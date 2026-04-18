using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Text.Json;
using System.Windows;
using System.Windows.Media.Imaging;
using Microsoft.Win32;
using Screen = System.Windows.Forms.Screen;

namespace SignatureBridge;

public partial class ConfigWindow : Window
{
    private readonly MainWindow _mainWindow;
    private BridgeConfig _config;
    private string? _configFilePath;

    public ConfigWindow(MainWindow mainWindow, BridgeConfig config, string configFilePath)
    {
        InitializeComponent();
        _mainWindow = mainWindow;
        _config = config;
        _configFilePath = configFilePath;
        
        LoadConfig();
        LoadMonitors();
        LoadLogoPreview();
    }

    private void LoadConfig()
    {
        LogoUriTextBox.Text = _config.LogoUri ?? string.Empty;
        ResolutionTextBox.Text = _config.PreferredResolution ?? string.Empty;
        ApiTokenTextBox.Text = _config.ApiToken ?? string.Empty;
        
        if (!string.IsNullOrWhiteSpace(_config.PreferredScreenDeviceName))
        {
            foreach (var item in MonitorComboBox.Items)
            {
                if (item is Screen screen && 
                    string.Equals(screen.DeviceName, _config.PreferredScreenDeviceName, StringComparison.OrdinalIgnoreCase))
                {
                    MonitorComboBox.SelectedItem = item;
                    break;
                }
            }
        }
    }

    private void LoadMonitors()
    {
        MonitorComboBox.Items.Clear();
        
        foreach (var screen in Screen.AllScreens)
        {
            var displayName = screen.Primary 
                ? $"Primary - {screen.Bounds.Width}x{screen.Bounds.Height}" 
                : $"Secondary - {screen.Bounds.Width}x{screen.Bounds.Height}";
            
            MonitorComboBox.Items.Add(new
            {
                Screen = screen,
                DisplayName = displayName
            });
        }
        
        if (MonitorComboBox.Items.Count > 0)
        {
            MonitorComboBox.SelectedIndex = 0;
        }
    }

    private async void LoadLogoPreview()
    {
        try
        {
            if (string.IsNullOrWhiteSpace(LogoUriTextBox.Text))
            {
                LogoPreviewText.Text = "No image URL provided";
                return;
            }

            var bitmap = new BitmapImage();
            bitmap.BeginInit();
            bitmap.CacheOption = BitmapCacheOption.OnLoad;
            bitmap.UriSource = new Uri(LogoUriTextBox.Text, UriKind.Absolute);
            bitmap.EndInit();
            bitmap.Freeze();
            
            LogoPreviewImage.Source = bitmap;
            LogoPreviewText.Text = "Image loaded successfully";
        }
        catch (Exception ex)
        {
            LogoPreviewText.Text = $"Failed to load image: {ex.Message}";
            LogoPreviewImage.Source = null;
        }
    }

    private void OnBrowseLogoClick(object sender, RoutedEventArgs e)
    {
        var openFileDialog = new OpenFileDialog
        {
            Filter = "Image Files|*.png;*.jpg;*.jpeg;*.bmp;*.gif|All Files|*.*",
            Title = "Select Logo Image"
        };

        if (openFileDialog.ShowDialog() == true)
        {
            try
            {
                // Copy image to app directory
                var appDirectory = Path.GetDirectoryName(_configFilePath);
                if (appDirectory == null) return;

                var imagesDirectory = Path.Combine(appDirectory, "images");
                Directory.CreateDirectory(imagesDirectory);

                var fileName = Path.GetFileName(openFileDialog.FileName);
                var destPath = Path.Combine(imagesDirectory, fileName);
                
                File.Copy(openFileDialog.FileName, destPath, true);
                
                // Use relative path
                LogoUriTextBox.Text = destPath;
                LoadLogoPreview();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to copy image: {ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }

    private async void OnShowTestDocumentClick(object sender, RoutedEventArgs e)
    {
        try
        {
            // Create test document HTML
            var testHtml = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <title>Test Document</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .document {
            background: white;
            padding: 40px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 2px solid #3b82f6;
            padding-bottom: 10px;
        }
        .content {
            line-height: 1.6;
            color: #555;
            margin: 20px 0;
        }
        .signature-area {
            margin-top: 50px;
            padding: 30px;
            border: 2px dashed #3b82f6;
            background: #f0f9ff;
            text-align: center;
        }
        .signature-label {
            color: #3b82f6;
            font-weight: bold;
            font-size: 14px;
            margin-bottom: 10px;
        }
        .signature-line {
            border-bottom: 1px solid #333;
            width: 300px;
            margin: 0 auto;
            height: 50px;
        }
        .signature-placeholder {
            color: #999;
            font-style: italic;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class='document'>
        <h1>Test Document</h1>
        
        <div class='content'>
            <p>This is a sample document to test the Signature Bridge display functionality.</p>
            <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
            <p>Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</p>
        </div>
        
        <div class='signature-area'>
            <div class='signature-label'>SIGNATURE AREA</div>
            <div class='signature-line'></div>
            <div class='signature-placeholder'>Please sign here</div>
        </div>
    </div>
</body>
</html>";

            // Save to temp file
            var tempFile = Path.Combine(Path.GetTempPath(), "signature_test.html");
            await File.WriteAllTextAsync(tempFile, testHtml);

            // Show in main window
            await _mainWindow.ShowSigningAsync(new Uri(tempFile).AbsoluteUri);
            
            MessageBox.Show("Test document displayed. Check the secondary monitor.", "Success", MessageBoxButton.OK, MessageBoxImage.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Failed to show test document: {ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
        }
    }

    private void OnApplyClick(object sender, RoutedEventArgs e)
    {
        SaveConfig();
        _mainWindow.ReloadConfig();
        MessageBox.Show("Configuration applied successfully.", "Success", MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private void OnSaveClick(object sender, RoutedEventArgs e)
    {
        SaveConfig();
        _mainWindow.ReloadConfig();
        MessageBox.Show("Configuration saved successfully.", "Success", MessageBoxButton.OK, MessageBoxImage.Information);
        Close();
    }

    private void OnCancelClick(object sender, RoutedEventArgs e)
    {
        Close();
    }

    private void SaveConfig()
    {
        var selectedMonitor = MonitorComboBox.SelectedItem;
        string? monitorName = null;
        
        if (selectedMonitor != null)
        {
            var prop = selectedMonitor.GetType().GetProperty("Screen");
            if (prop != null)
            {
                var screen = prop.GetValue(selectedMonitor) as Screen;
                monitorName = screen?.DeviceName;
            }
        }

        _config = new BridgeConfig
        {
            LogoUri = LogoUriTextBox.Text.Trim(),
            PreferredScreenDeviceName = monitorName,
            PreferredResolution = ResolutionTextBox.Text.Trim(),
            ApiToken = ApiTokenTextBox.Text.Trim()
        };

        try
        {
            var json = JsonSerializer.Serialize(_config, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(_configFilePath, json);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Failed to save config: {ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
        }
    }
}
