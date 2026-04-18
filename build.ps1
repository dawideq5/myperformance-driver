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

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Signature Bridge Installer Builder" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Build the project
Write-Host "[1/2] Building .NET project..." -ForegroundColor Cyan
dotnet publish SignatureBridge/SignatureBridge.csproj `
    --configuration $Configuration `
    --runtime win-x64 `
    --self-contained true `
    --output "SignatureBridge/bin/$Configuration/net10.0-windows/win-x64/publish"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

$publishDir = "SignatureBridge/bin/$Configuration/net10.0-windows/win-x64/publish"
if (-not (Test-Path "$publishDir/SignatureBridge.exe")) {
    Write-Host "Error: SignatureBridge.exe not found in publish directory!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green
Write-Host "Location: $publishDir" -ForegroundColor Gray
Write-Host ""

# Create installer if Inno Setup is available
if (-not $SkipInstaller) {
    Write-Host "[2/2] Creating installer..." -ForegroundColor Cyan
    $innosetup = Get-Command "iscc.exe" -ErrorAction SilentlyContinue
    if ($innosetup) {
        & iscc.exe installer/SignatureBridge.iss
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Installer creation failed!" -ForegroundColor Red
            exit 1
        }
        
        if (Test-Path "SignatureBridge-Setup.exe") {
            Write-Host "Installer created successfully!" -ForegroundColor Green
            Write-Host "Location: $(Get-Location)\SignatureBridge-Setup.exe" -ForegroundColor Cyan
        } else {
            Write-Host "Warning: Installer file not found!" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Inno Setup (iscc.exe) not found." -ForegroundColor Yellow
        Write-Host "Installer will not be created." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To create the installer:" -ForegroundColor White
        Write-Host "1. Download Inno Setup from: https://jrsoftware.org/isdl.php" -ForegroundColor Cyan
        Write-Host "2. Install it" -ForegroundColor Cyan
        Write-Host "3. Run this script again" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Build Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "EXE: $publishDir/SignatureBridge.exe" -ForegroundColor Cyan
if (Test-Path "SignatureBridge-Setup.exe") {
    Write-Host "Installer: $(Get-Location)\SignatureBridge-Setup.exe" -ForegroundColor Cyan
}
Write-Host ""
