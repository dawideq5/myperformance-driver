# Build script for Signature Bridge
# This script builds the self-contained EXE and creates the installer
# NOTE: This script MUST be run in PowerShell, not CMD!

param(
    [string]$Configuration = "Release",
    [switch]$SkipInstaller = $false
)

# Check if running in CMD
if ($Host.Name -eq "Windows Command Processor") {
    Write-Error "This script must be run in PowerShell, not CMD. Right-click Start button and select 'Windows PowerShell'"
    exit 1
}

$ErrorActionPreference = "Stop"

Write-Host "Building Signature Bridge..." -ForegroundColor Green

# Build the project
Write-Host "Building project..." -ForegroundColor Cyan
dotnet publish SignatureBridge/SignatureBridge.csproj `
    --configuration $Configuration `
    --runtime win-x64 `
    --self-contained true `
    --output "SignatureBridge/bin/$Configuration/net8.0-windows/win-x64/publish"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green

# Create installer if Inno Setup is available
if (-not $SkipInstaller) {
    $innosetup = Get-Command "iscc.exe" -ErrorAction SilentlyContinue
    if ($innosetup) {
        Write-Host "Creating installer..." -ForegroundColor Cyan
        & iscc.exe installer/SignatureBridge.iss
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Installer creation failed!" -ForegroundColor Red
            exit 1
        }
        Write-Host "Installer created successfully!" -ForegroundColor Green
    } else {
        Write-Host "Inno Setup (iscc.exe) not found. Skipping installer creation." -ForegroundColor Yellow
        Write-Host "Download from: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
    }
}

Write-Host "`nBuild complete!" -ForegroundColor Green
Write-Host "Output: SignatureBridge/bin/$Configuration/net8.0-windows/win-x64/publish/" -ForegroundColor Cyan
