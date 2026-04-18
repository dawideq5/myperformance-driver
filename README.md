# myperformance-driver

## Signature Bridge (.NET 10 WPF)

Signature Bridge is a Windows application that displays documents on a secondary monitor for signature workflows. It provides a local HTTP API for remote control and includes a graphical configuration interface.

**Self-contained installer - no dependencies required.**

### Features

- **GUI Configuration**: Built-in configuration window for easy setup
- **Loading Image**: Customize the logo/loading image displayed in idle state
- **Document Display**: Show documents with signature placeholders on secondary monitor
- **Test Mode**: Built-in test document with signature area for validation
- **Monitor Selection**: Automatic or manual monitor selection
- **API Authentication**: Optional token-based authentication
- **Tray Icon**: System tray integration with quick actions
- **Self-Contained**: Single EXE with no runtime dependencies

## Installation

### Download and Run Installer (Recommended)

Download the installer from the [Releases](https://github.com/dawideq5/myperformance-driver/releases) page and run it:

1. Download `SignatureBridge-Setup.exe`
2. Double-click to run
3. Follow the installation wizard
4. Launch the application from Start Menu or desktop shortcut

The installer includes everything needed - no additional downloads required.

**Note:** Installers are automatically built and released on GitHub when you push a version tag (see "Creating Release" below).

### Manual Install (For Developers)

**Note:** This requires .NET 10 SDK and is intended for developers building from source.

```powershell
git clone https://github.com/dawideq5/myperformance-driver.git
cd myperformance-driver
dotnet publish SignatureBridge/SignatureBridge.csproj -c Release -r win-x64 --self-contained true
```

Then run from the publish directory.

- Project: `SignatureBridge`
- Local API:
  - `GET http://localhost:12345/show?url=https://...`
  - `GET http://localhost:12345/idle`
  - `GET http://localhost:12345/status`
- Config file: `SignatureBridge/config.json`
  - `LogoUri` (image displayed in idle state)
  - `PreferredScreenDeviceName` (optional monitor device name)
  - `PreferredResolution` (optional fallback like `1024x600`)
  - `ApiToken` (optional; if set, include `token` query or `X-SignatureBridge-Token` header)
- Installer script: `installer/SignatureBridge.iss`

### Configuration GUI

Signature Bridge includes a built-in configuration window accessible via:

1. **Tray Icon**: Right-click the system tray icon and select "Configuration"
2. **On-Screen Button**: Click the ⚙ button in the top-right corner of the window (when visible)

The configuration window allows you to:

- **Loading Image**: Set a custom logo or loading image (URL or local file)
- **Monitor Selection**: Choose which monitor to use for display
- **Resolution**: Set preferred resolution (optional)
- **API Token**: Configure authentication token for API access
- **Test Display**: Preview a test document with signature placeholder
- **Status**: View current connection status and monitor information

### Usage

1. Install and run Signature Bridge
2. The application will automatically detect and connect to a secondary monitor
3. Access configuration via tray icon or on-screen button
4. Set your preferred loading image and monitor settings
5. Use the "Test" button to verify document display
6. Control the application via HTTP API from your web application

## Creating Release (For Developers)

The project uses GitHub Actions to automatically build and release installers.

### Automatic Release with GitHub Actions

To create a new release:

1. Commit and push your changes:
```bash
git add .
git commit -m "Your changes"
git push
```

2. Create and push a version tag:
```bash
git tag v1.2.0
git push origin v1.2.0
```

3. GitHub Actions will automatically:
   - Build the project
   - Create the installer
   - Create a GitHub Release
   - Upload `SignatureBridge-Setup.exe` to the release

The installer will be available at: https://github.com/dawideq5/myperformance-driver/releases

### Manual Build (If GitHub Actions Fails)

If the installer is not available in Releases, you can build it yourself:

### Prerequisites
- .NET 10 SDK
- Inno Setup (https://jrsoftware.org/isdl.php)
- Windows x64

### Build Instructions

1. Clone the repository:
```powershell
git clone https://github.com/dawideq5/myperformance-driver.git
cd myperformance-driver
```

2. Build the installer:
```powershell
.\build.ps1
```

This will:
- Build the self-contained EXE
- Create the installer (SignatureBridge-Setup.exe)
- Output both files in the project root

The installer will be created as `SignatureBridge-Setup.exe` in the project directory.

## Optimizations Applied

### Stability
- Added comprehensive error handling for WebView2 initialization
- Added HTTP request timeout (10s)
- Added proper disposal of resources (HttpClient, NotifyIcon, CancellationTokenSource)
- Added concurrent request limit (max 10)
- Added OperationCanceledException handling
- Added try-catch in ProcessRequestAsync for graceful error handling

### Performance
- Added logo caching to avoid repeated loading
- Added BitmapScalingMode.HighQuality for better image rendering
- Configured self-contained single-file publish for smaller footprint
- Added parallel request processing with controlled concurrency
- Added BitmapImage.Freeze() for thread-safe caching

### Security
- Maintained local-only request validation
- Maintained token-based authentication
- Added request context isolation

### Build
- Configured self-contained publish (no .NET runtime dependency)
- Added compression for single-file output
- Updated installer script for new build paths

## Troubleshooting

### Application doesn't start

**Problem:** Application fails to launch.

**Solution:**
1. Verify Windows is x64 (installer is 64-bit only)
2. Check Windows Event Viewer for error details
3. Reinstall the application

### No secondary monitor detected

**Problem:** Application requires a secondary monitor (non-primary).

**Solution:**
1. Connect a second monitor
2. Or use the Configuration window to select a different monitor
3. Check Display Settings in Windows to ensure monitor is active

## File Descriptions

- `SignatureBridge.exe` - Main application
- `config.json` - Configuration file (edit via GUI)
- `installer/SignatureBridge.iss` - Inno Setup installer script
