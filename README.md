# myperformance-driver

## Signature Bridge (.NET 8 WPF)

### Quick Install (One-Click)

Run this single command in PowerShell to clone, build, and install:

```powershell
irm https://raw.githubusercontent.com/dawideq5/myperformance-driver/main/install.ps1 | iex
```

This will:
- Clone the repository
- Build the self-contained EXE
- Create installer (if Inno Setup is installed)
- Copy files to chosen location
- Optionally start the application

**Note:** Requires .NET 8 SDK for building. If you don't have it, download from: https://dotnet.microsoft.com/download/dotnet/8.0

### Manual Install (Terminal Commands)

If you prefer to run commands manually, copy and paste this block in PowerShell:

```powershell
# Clone repository
git clone https://github.com/dawideq5/myperformance-driver.git
cd myperformance-driver

# Build self-contained EXE
dotnet publish SignatureBridge/SignatureBridge.csproj --configuration Release --runtime win-x64 --self-contained true --output "SignatureBridge\bin\Release\net8.0-windows\win-x64\publish"

# Copy to desired location (example: current directory)
Copy-Item -Path "SignatureBridge\bin\Release\net8.0-windows\win-x64\publish\*" -Destination ".\SignatureBridge" -Recurse

# Run application
.\SignatureBridge\SignatureBridge.exe
```

Or as a single one-liner:

```powershell
git clone https://github.com/dawideq5/myperformance-driver.git; cd myperformance-driver; dotnet publish SignatureBridge/SignatureBridge.csproj -c Release -r win-x64 --self-contained true -o "SignatureBridge\bin\Release\net8.0-windows\win-x64\publish"; Copy-Item -Path "SignatureBridge\bin\Release\net8.0-windows\win-x64\publish\*" -Destination ".\SignatureBridge" -Recurse; .\SignatureBridge\SignatureBridge.exe
```

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
