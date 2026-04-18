# myperformance-driver

## Signature Bridge (.NET 10 WPF)

Signature Bridge is a Windows application that displays documents on a secondary monitor for signature workflows. It provides a local HTTP API for remote control and includes a graphical configuration interface.

**Requires .NET 10 SDK for building.**

### Features

- **GUI Configuration**: Built-in configuration window for easy setup
- **Loading Image**: Customize the logo/loading image displayed in idle state
- **Document Display**: Show documents with signature placeholders on secondary monitor
- **Test Mode**: Built-in test document with signature area for validation
- **Monitor Selection**: Automatic or manual monitor selection
- **API Authentication**: Optional token-based authentication
- **Tray Icon**: System tray integration with quick actions
- **Self-Contained**: Single EXE with no runtime dependencies

### Quick Install (Easiest - Works in ANY Terminal)

Download and run `start.bat` - it automatically switches to PowerShell and installs everything:

```batch
start.bat
```

This works in CMD, PowerShell, or any terminal. It will:
- Automatically switch to PowerShell
- Clone the repository
- Build the self-contained EXE
- Create installer (if Inno Setup is installed)
- Copy files to chosen location
- Optionally start the application

### Alternative: PowerShell One-Click

If you prefer to use PowerShell directly:

```powershell
irm https://raw.githubusercontent.com/dawideq5/myperformance-driver/main/install.ps1 | iex
```

**Note:** Requires .NET 10 SDK for building. If you don't have it, download from: https://dotnet.microsoft.com/download/dotnet/10.0

### Manual Install

#### PowerShell Commands (Recommended)

Copy and paste this entire block into **PowerShell**:

```powershell
# Clone repository
git clone https://github.com/dawideq5/myperformance-driver.git
cd myperformance-driver

# Build self-contained EXE
dotnet publish SignatureBridge/SignatureBridge.csproj --configuration Release --runtime win-x64 --self-contained true --output "SignatureBridge\bin\Release\net10.0-windows\win-x64\publish"

# Copy to desired location (example: current directory)
Copy-Item -Path "SignatureBridge\bin\Release\net10.0-windows\win-x64\publish\*" -Destination ".\SignatureBridge" -Recurse

# Run application
.\SignatureBridge\SignatureBridge.exe
```

**Single one-liner for PowerShell:**

```powershell
git clone https://github.com/dawideq5/myperformance-driver.git; cd myperformance-driver; dotnet publish SignatureBridge/SignatureBridge.csproj -c Release -r win-x64 --self-contained true -o "SignatureBridge\bin\Release\net10.0-windows\win-x64\publish"; Copy-Item -Path "SignatureBridge\bin\Release\net10.0-windows\win-x64\publish\*" -Destination ".\SignatureBridge" -Recurse; .\SignatureBridge\SignatureBridge.exe
```

#### CMD/Command Prompt Commands

Copy and paste this entire block into **Command Prompt (CMD)**:

```batch
git clone https://github.com/dawideq5/myperformance-driver.git
cd myperformance-driver
dotnet publish SignatureBridge/SignatureBridge.csproj --configuration Release --runtime win-x64 --self-contained true --output "SignatureBridge\bin\Release\net10.0-windows\win-x64\publish"
xcopy "SignatureBridge\bin\Release\net10.0-windows\win-x64\publish\*" "SignatureBridge\" /E /I /Y
SignatureBridge\SignatureBridge.exe
```

**Important CMD notes:**
- Do NOT copy lines starting with `#` - CMD doesn't support comments
- Use `xcopy` instead of `Copy-Item`
- Use backslashes `\` in paths, not forward slashes

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

## Building

### Windows (recommended)
```powershell
.\build.ps1
```

### Cross-platform
```bash
./build.sh
```

To build without creating the installer:
```powershell
.\build.ps1 -SkipInstaller
```

### Manual build
```bash
dotnet publish SignatureBridge/SignatureBridge.csproj --configuration Release --runtime win-x64 --self-contained true
```

The output EXE will be in `SignatureBridge/bin/Release/net8.0-windows/win-x64/publish/`.

To create the installer, run Inno Setup:
```bash
iscc.exe installer/SignatureBridge.iss
```

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

### "'irm' is not recognized as an internal or external command"

**Problem:** You are trying to run a PowerShell command in CMD (Command Prompt).

**Solution:** 
1. Open PowerShell instead (right-click Start button → Windows PowerShell)
2. Or use the CMD alternative command: `powershell -Command "irm ... | iex"`
3. Or download and run `install.cmd` instead

### "'Copy-Item' is not recognized..."

**Problem:** You are using PowerShell commands in CMD.

**Solution:**
1. Open PowerShell for PowerShell commands
2. Or use CMD equivalents (see "Manual Install" section above for CMD commands)

### "'#' is not recognized..."

**Problem:** CMD doesn't support `#` comments. You copy-pasted comment lines.

**Solution:**
1. In CMD: Don't copy lines starting with `#`
2. In PowerShell: Comments work fine, but make sure you're actually in PowerShell

### "git clone" fails with "already exists"

**Problem:** Directory already exists from previous attempt.

**Solution:**
```powershell
# Remove existing directory first
Remove-Item -Recurse -Force myperformance-driver
# Then run git clone again
git clone https://github.com/dawideq5/myperformance-driver.git
```

Or use a different directory name:
```powershell
git clone https://github.com/dawideq5/myperformance-driver.git myperformance-driver-new
```

### Application doesn't start

**Problem:** Missing dependencies or configuration issues.

**Solution:**
1. Check if .NET 8 SDK is installed: `dotnet --version`
2. Verify config.json exists in the application directory
3. Check Windows Event Viewer for errors
4. Run from command line to see error messages: `.\SignatureBridge\SignatureBridge.exe`

### No secondary monitor detected

**Problem:** Application requires a secondary monitor (non-primary).

**Solution:**
1. Connect a second monitor
2. Or use the Configuration window to select a different monitor
3. Check Display Settings in Windows to ensure monitor is active

## File Descriptions

- `SignatureBridge.exe` - Main application
- `config.json` - Configuration file (edit via GUI or manually)
- `install.ps1` - PowerShell one-click installer
- `install.cmd` - CMD/Batch installer alternative
- `build.ps1` - Build script for developers
- `installer/SignatureBridge.iss` - Inno Setup installer script
