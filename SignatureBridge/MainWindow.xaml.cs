using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Text.Json;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media.Imaging;
using Microsoft.Win32;
using Microsoft.Web.WebView2.Core;
using Screen = System.Windows.Forms.Screen;
using System.Net.Http;

namespace SignatureBridge;

public partial class MainWindow : Window
{
    private readonly BridgeConfig _config;
    private readonly System.Windows.Forms.NotifyIcon _notifyIcon;
    private readonly CancellationTokenSource _listenerCancellation = new();
    private readonly CancellationTokenSource _appCancellation = new();
    private readonly HttpClient _httpClient;
    private bool _allowClose;
    private bool _connected;
    private Screen? _activeScreen;
    private BitmapImage? _cachedLogo;

    public MainWindow()
    {
        InitializeComponent();
        _config = BridgeConfig.Load(Path.Combine(AppContext.BaseDirectory, "config.json"));
        _httpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(10) };
        SetLogoImage();
        _notifyIcon = CreateTrayIcon();

        Loaded += OnLoaded;
        SystemEvents.DisplaySettingsChanged += OnDisplaySettingsChanged;
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        ApplyDisplayConfiguration();
        _ = Task.Run(() => RunApiServerAsync(_listenerCancellation.Token));
    }

    private async Task RunApiServerAsync(CancellationToken cancellationToken)
    {
        using var listener = new HttpListener();
        listener.Prefixes.Add("http://localhost:12345/");
        listener.Start();
        using var cancellationRegistration = cancellationToken.Register(() =>
        {
            if (listener.IsListening)
            {
                listener.Close();
            }
        });

        var requestTasks = new List<Task>();
        while (!cancellationToken.IsCancellationRequested)
        {
            HttpListenerContext? context = null;
            try
            {
                context = await listener.GetContextAsync(cancellationToken);
                var processTask = ProcessRequestAsync(context);
                requestTasks.Add(processTask);
                
                if (requestTasks.Count >= 10)
                {
                    var completed = await Task.WhenAny(requestTasks);
                    requestTasks.Remove(completed);
                }
            }
            catch (HttpListenerException) when (cancellationToken.IsCancellationRequested)
            {
                break;
            }
            catch (ObjectDisposedException) when (cancellationToken.IsCancellationRequested)
            {
                break;
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"HTTP listener loop error: {ex}");
                if (context is not null)
                {
                    await WriteResponseAsync(context.Response, 500, "Internal Server Error", "text/plain");
                }
            }
        }

        if (requestTasks.Count > 0)
        {
            await Task.WhenAll(requestTasks);
        }

        listener.Stop();
    }

    private async Task ProcessRequestAsync(HttpListenerContext context)
    {
        try
        {
            if (!context.Request.IsLocal)
            {
                await WriteResponseAsync(context.Response, 403, "Forbidden", "text/plain");
                return;
            }

            if (!IsTokenAuthorized(context.Request))
            {
                await WriteResponseAsync(context.Response, 401, "Unauthorized", "text/plain");
                return;
            }

        var route = context.Request.Url?.AbsolutePath?.Trim('/').ToLowerInvariant();
        switch (route)
        {
            case "show":
            {
                var url = context.Request.QueryString["url"];
                if (!Uri.TryCreate(url, UriKind.Absolute, out var targetUri) ||
                    (targetUri.Scheme != Uri.UriSchemeHttp && targetUri.Scheme != Uri.UriSchemeHttps))
                {
                    await WriteResponseAsync(context.Response, 400, "Missing or invalid 'url' query parameter.", "text/plain");
                    return;
                }

                var showOperation = Dispatcher.InvokeAsync(() => ShowSigningAsync(targetUri.ToString()));
                await showOperation.Task.Unwrap();
                await WriteResponseAsync(context.Response, 200, "OK", "text/plain");
                return;
            }
            case "idle":
                await Dispatcher.InvokeAsync(ShowIdle);
                await WriteResponseAsync(context.Response, 200, "OK", "text/plain");
                return;
            case "status":
                var status = new
                {
                    connected = _connected,
                    resolution = _activeScreen is null
                        ? string.Empty
                        : $"{_activeScreen.Bounds.Width}x{_activeScreen.Bounds.Height}",
                    monitor = _activeScreen?.DeviceName ?? string.Empty
                };
                await WriteResponseAsync(context.Response, 200, JsonSerializer.Serialize(status), "application/json");
                return;
            default:
                await WriteResponseAsync(context.Response, 404, "Not Found", "text/plain");
                return;
        }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Request processing error: {ex}");
            try
            {
                await WriteResponseAsync(context.Response, 500, "Internal Server Error", "text/plain");
            }
            catch
            {
                // Response already sent or closed
            }
        }
    }

    private static async Task WriteResponseAsync(HttpListenerResponse response, int statusCode, string content, string contentType)
    {
        response.StatusCode = statusCode;
        response.ContentType = contentType;
        var bytes = System.Text.Encoding.UTF8.GetBytes(content);
        response.ContentLength64 = bytes.Length;
        await response.OutputStream.WriteAsync(bytes);
        response.OutputStream.Close();
    }

    private async Task ShowSigningAsync(string url)
    {
        if (!_connected)
        {
            return;
        }

        try
        {
            if (SigningBrowser.CoreWebView2 is null)
            {
                try
                {
                    await SigningBrowser.EnsureCoreWebView2Async(null);
                }
                catch (Exception ex)
                {
                    Debug.WriteLine($"WebView2 initialization failed: {ex.Message}");
                    return;
                }
                
                var core = SigningBrowser.CoreWebView2;
                if (core is null)
                {
                    Debug.WriteLine("WebView2 core is null after initialization");
                    return;
                }

                core.Settings.AreDefaultContextMenusEnabled = false;
                core.Settings.AreDevToolsEnabled = false;
                core.NewWindowRequested += (_, args) =>
                {
                    args.Handled = true;
                    SigningBrowser.Source = args.Uri is null ? null : new Uri(args.Uri);
                };
            }

            SigningBrowser.Source = new Uri(url);
            IdleView.Visibility = Visibility.Collapsed;
            SigningView.Visibility = Visibility.Visible;
            ShowAndFocus();
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Error showing signing view: {ex.Message}");
        }
    }

    private void ShowIdle()
    {
        IdleView.Visibility = Visibility.Visible;
        SigningView.Visibility = Visibility.Collapsed;
        ShowAndFocus();
    }

    private async void SetLogoImage()
    {
        if (string.IsNullOrWhiteSpace(_config.LogoUri))
        {
            return;
        }

        try
        {
            if (_cachedLogo is not null)
            {
                LogoImage.Source = _cachedLogo;
                return;
            }

            var bitmap = new BitmapImage();
            bitmap.BeginInit();
            bitmap.CacheOption = BitmapCacheOption.OnLoad;
            bitmap.UriSource = new Uri(_config.LogoUri, UriKind.Absolute);
            bitmap.EndInit();
            bitmap.Freeze();
            _cachedLogo = bitmap;
            LogoImage.Source = bitmap;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Failed to load logo from '{_config.LogoUri}': {ex.Message}");
            LogoImage.Source = null;
        }
    }

    private bool IsTokenAuthorized(HttpListenerRequest request)
    {
        if (string.IsNullOrWhiteSpace(_config.ApiToken))
        {
            return true;
        }

        var providedToken = request.QueryString["token"];
        if (string.IsNullOrWhiteSpace(providedToken))
        {
            providedToken = request.Headers["X-SignatureBridge-Token"];
        }

        return string.Equals(_config.ApiToken, providedToken, StringComparison.Ordinal);
    }

    private void ApplyDisplayConfiguration()
    {
        _activeScreen = ResolveTargetScreen();
        _connected = _activeScreen is not null;

        if (_activeScreen is null)
        {
            Hide();
            return;
        }

        var bounds = _activeScreen.Bounds;
        Left = bounds.Left;
        Top = bounds.Top;
        Width = bounds.Width;
        Height = bounds.Height;
        WindowState = WindowState.Normal;
        ShowIdle();
    }

    private Screen? ResolveTargetScreen()
    {
        var secondary = Screen.AllScreens.Where(screen => !screen.Primary).ToArray();
        if (secondary.Length == 0)
        {
            return null;
        }

        if (!string.IsNullOrWhiteSpace(_config.PreferredScreenDeviceName))
        {
            var byName = secondary.FirstOrDefault(screen =>
                string.Equals(screen.DeviceName, _config.PreferredScreenDeviceName, StringComparison.OrdinalIgnoreCase));
            if (byName is not null)
            {
                return byName;
            }
        }

        if (!string.IsNullOrWhiteSpace(_config.PreferredResolution) &&
            TryParseResolution(_config.PreferredResolution, out var width, out var height))
        {
            var byResolution = secondary.FirstOrDefault(screen => screen.Bounds.Width == width && screen.Bounds.Height == height);
            if (byResolution is not null)
            {
                return byResolution;
            }
        }

        return secondary[0];
    }

    private static bool TryParseResolution(string value, out int width, out int height)
    {
        width = 0;
        height = 0;
        var split = value.Split('x', 'X');
        return split.Length == 2 &&
               int.TryParse(split[0], out width) &&
               int.TryParse(split[1], out height);
    }

    private void OnDisplaySettingsChanged(object? sender, EventArgs e)
    {
        Dispatcher.Invoke(ApplyDisplayConfiguration);
    }

    private System.Windows.Forms.NotifyIcon CreateTrayIcon()
    {
        var contextMenu = new System.Windows.Forms.ContextMenuStrip();
        contextMenu.Items.Add("Open", null, (_, _) =>
        {
            if (_connected)
            {
                ShowAndFocus();
            }
        });
        contextMenu.Items.Add("Idle", null, (_, _) => Dispatcher.Invoke(ShowIdle));
        contextMenu.Items.Add("Exit", null, (_, _) =>
        {
            _allowClose = true;
            Close();
        });

        return new System.Windows.Forms.NotifyIcon
        {
            Icon = SystemIcons.Application,
            Visible = true,
            Text = "Signature Bridge",
            ContextMenuStrip = contextMenu
        };
    }

    private void ShowAndFocus()
    {
        if (!_connected)
        {
            return;
        }

        if (!IsVisible)
        {
            Show();
        }

        Activate();
        Focus();
    }

    protected override void OnPreviewKeyDown(System.Windows.Input.KeyEventArgs e)
    {
        if (e.SystemKey == Key.F4 && Keyboard.Modifiers.HasFlag(ModifierKeys.Alt))
        {
            e.Handled = true;
            return;
        }

        base.OnPreviewKeyDown(e);
    }

    protected override void OnClosing(System.ComponentModel.CancelEventArgs e)
    {
        if (!_allowClose)
        {
            e.Cancel = true;
            Hide();
            return;
        }

        _appCancellation.Cancel();
        _listenerCancellation.Cancel();
        _notifyIcon.Visible = false;
        _notifyIcon.Dispose();
        _httpClient.Dispose();
        SystemEvents.DisplaySettingsChanged -= OnDisplaySettingsChanged;
        _cachedLogo = null;
        base.OnClosing(e);
    }
}

internal sealed class BridgeConfig
{
    public string LogoUri { get; init; } = "https://dummyimage.com/1920x1080/0e0e0e/ffffff.png&text=Signature+Bridge";
    public string? PreferredScreenDeviceName { get; init; }
    public string? PreferredResolution { get; init; }
    public string? ApiToken { get; init; }

    public static BridgeConfig Load(string filePath)
    {
        if (!File.Exists(filePath))
        {
            return new BridgeConfig();
        }

        try
        {
            var json = File.ReadAllText(filePath);
            return JsonSerializer.Deserialize<BridgeConfig>(json) ?? new BridgeConfig();
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Failed to load config '{filePath}': {ex.Message}");
            return new BridgeConfig();
        }
    }
}
