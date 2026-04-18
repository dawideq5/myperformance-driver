# One-click installer for Signature Bridge
# This script clones, builds, and optionally installs Signature Bridge
# Run: irm https://raw.githubusercontent.com/dawideq5/myperformance-driver/main/install.ps1 | iex

param(
    [string]$Branch = "main",
    [switch]$SkipInstaller = $false,
    [switch]$AutoStart = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== Signature Bridge One-Click Installer ===" -ForegroundColor Cyan
Write-Host ""

# Check if running with sufficient privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Note: Running without administrator privileges. Installer creation may fail." -ForegroundColor Yellow
}

# Create temp directory
$tempDir = Join-Path $env:TEMP "myperformance-driver-$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Write-Host "Working directory: $tempDir" -ForegroundColor Gray

try {
    # Clone repository
    Write-Host "Cloning repository..." -ForegroundColor Cyan
    git clone --depth 1 --branch $Branch "https://github.com/dawideq5/myperformance-driver.git" $tempDir
    if ($LASTEXITCODE -ne 0) {
        throw "Git clone failed"
    }

    # Build project
    Write-Host "Building project..." -ForegroundColor Cyan
    Push-Location $tempDir
    & dotnet publish SignatureBridge/SignatureBridge.csproj `
        --configuration Release `
        --runtime win-x64 `
        --self-contained true `
        --output "SignatureBridge/bin/Release/net8.0-windows/win-x64/publish" `
        /p:PublishSingleFile=true `
        /p:IncludeNativeLibrariesForSelfExtract=true `
        /p:EnableCompressionInSingleFile=true
    
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    Pop-Location

    $publishDir = Join-Path $tempDir "SignatureBridge\bin\Release\net8.0-windows\win-x64\publish"
    $exePath = Join-Path $publishDir "SignatureBridge.exe"

    if (-not (Test-Path $exePath)) {
        throw "EXE not found at $exePath"
    }

    Write-Host "Build successful!" -ForegroundColor Green
    Write-Host "EXE location: $exePath" -ForegroundColor Gray

    # Create installer if Inno Setup is available
    if (-not $SkipInstaller) {
        $innosetup = Get-Command "iscc.exe" -ErrorAction SilentlyContinue
        if ($innosetup) {
            Write-Host "Creating installer..." -ForegroundColor Cyan
            & iscc.exe (Join-Path $tempDir "installer\SignatureBridge.iss")
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: Installer creation failed" -ForegroundColor Yellow
            } else {
                Write-Host "Installer created successfully!" -ForegroundColor Green
                $installerPath = Join-Path $tempDir "SignatureBridgeInstaller.exe"
                if (Test-Path $installerPath) {
                    Write-Host "Installer location: $installerPath" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host "Inno Setup not found. Skipping installer creation." -ForegroundColor Yellow
            Write-Host "Download from: https://jrsoftware.org/isdl.php" -ForegroundColor Gray
        }
    }

    # Ask user where to copy files
    Write-Host ""
    Write-Host "Select installation option:" -ForegroundColor Cyan
    Write-Host "1. Copy to Program Files (requires admin)" -ForegroundColor White
    Write-Host "2. Copy to current directory" -ForegroundColor White
    Write-Host "3. Keep in temp directory (temporary)" -ForegroundColor White
    $choice = Read-Host "Enter choice (1-3, default: 2)"

    $targetDir = switch ($choice) {
        "1" { 
            if ($isAdmin) {
                Join-Path $env:ProgramFiles "SignatureBridge"
            } else {
                Write-Host "Admin privileges required for Program Files. Using current directory." -ForegroundColor Yellow
                Join-Path $PWD "SignatureBridge"
            }
        }
        "3" { $publishDir }
        default { Join-Path $PWD "SignatureBridge" }
    }

    # Copy files
    if ($choice -ne "3") {
        Write-Host "Copying files to: $targetDir" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Copy-Item -Path (Join-Path $publishDir "*") -Destination $targetDir -Recurse -Force
        $exePath = Join-Path $targetDir "SignatureBridge.exe"
    }

    Write-Host ""
    Write-Host "=== Installation Complete ===" -ForegroundColor Green
    Write-Host "Application: $exePath" -ForegroundColor Cyan
    Write-Host "Config file: $(Join-Path (Split-Path $exePath) 'config.json')" -ForegroundColor Gray

    # Auto-start if requested
    if ($AutoStart) {
        Write-Host "Starting application..." -ForegroundColor Cyan
        Start-Process $exePath
    }

    # Ask if user wants to start now
    if (-not $AutoStart) {
        $start = Read-Host "Start application now? (y/n)"
        if ($start -eq "y" -or $start -eq "Y") {
            Start-Process $exePath
        }
    }

    # Ask about cleanup
    if ($choice -ne "3") {
        Write-Host ""
        $cleanup = Read-Host "Delete temporary files? (y/n)"
        if ($cleanup -eq "y" -or $cleanup -eq "Y") {
            Pop-Location
            Remove-Item $tempDir -Recurse -Force
            Write-Host "Temporary files cleaned up." -ForegroundColor Green
        }
    }

} catch {
    Write-Host ""
    Write-Host "=== Installation Failed ===" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host ""
Write-Host "For configuration, edit: $(Join-Path (Split-Path $exePath) 'config.json')" -ForegroundColor Gray
Write-Host "API endpoints:" -ForegroundColor Gray
Write-Host "  http://localhost:12345/show?url=..." -ForegroundColor Gray
Write-Host "  http://localhost:12345/idle" -ForegroundColor Gray
Write-Host "  http://localhost:12345/status" -ForegroundColor Gray
