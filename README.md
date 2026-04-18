# myperformance-driver

## Signature Bridge (.NET 8 WPF)

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
