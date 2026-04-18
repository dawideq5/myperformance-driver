@echo off
REM One-click installer for Signature Bridge (CMD version)
REM This script clones, builds, and installs Signature Bridge
REM Run: install.cmd

chcp 65001 >nul
setlocal EnableDelayedExpansion

echo ============================================
echo  Signature Bridge One-Click Installer (CMD)
echo ============================================
echo.

REM Check if running with sufficient privileges
net session >nul 2>&1
if %errorlevel% == 0 (
    set isAdmin=1
) else (
    set isAdmin=0
    echo Note: Running without administrator privileges. Installer creation may fail.
    echo.
)

REM Create temp directory
set tempDir=%TEMP%\myperformance-driver-%date:~-4,4%%date:~-10,2%%date:~-7,2%%time:~0,2%%time:~3,2%%time:~6,2%
set tempDir=%tempDir: =0%
mkdir "%tempDir%" 2>nul
if errorlevel 1 (
    echo Error: Failed to create temp directory
    exit /b 1
)
echo Working directory: %tempDir%
echo.

REM Clone repository
echo Cloning repository...
git clone --depth 1 --branch main "https://github.com/dawideq5/myperformance-driver.git" "%tempDir%"
if errorlevel 1 (
    echo Error: Git clone failed
    exit /b 1
)

REM Build project
echo.
echo Building project...
cd /d "%tempDir%"
dotnet publish SignatureBridge/SignatureBridge.csproj --configuration Release --runtime win-x64 --self-contained true --output "SignatureBridge\bin\Release\net8.0-windows\win-x64\publish" /p:PublishSingleFile=true /p:IncludeNativeLibrariesForSelfExtract=true /p:EnableCompressionInSingleFile=true
if errorlevel 1 (
    echo Error: Build failed
    exit /b 1
)

set publishDir=%tempDir%\SignatureBridge\bin\Release\net8.0-windows\win-x64\publish
set exePath=%publishDir%\SignatureBridge.exe

if not exist "%exePath%" (
    echo Error: EXE not found at %exePath%
    exit /b 1
)

echo.
echo Build successful!
echo EXE location: %exePath%
echo.

REM Create installer if Inno Setup is available
where iscc.exe >nul 2>&1
if %errorlevel% == 0 (
    echo Creating installer...
    iscc.exe "installer\SignatureBridge.iss"
    if %errorlevel% == 0 (
        echo Installer created successfully!
        if exist "SignatureBridgeInstaller.exe" (
            echo Installer location: %tempDir%\SignatureBridgeInstaller.exe
        )
    ) else (
        echo Warning: Installer creation failed
    )
) else (
    echo Inno Setup not found. Skipping installer creation.
    echo Download from: https://jrsoftware.org/isdl.php
)

echo.
echo ============================================
echo  Installation Complete
echo ============================================
echo.
echo Application: %exePath%
echo Config file: %publishDir%\config.json
echo.
echo API endpoints:
echo   http://localhost:12345/show?url=...
echo   http://localhost:12345/idle
echo   http://localhost:12345/status
echo.
echo Would you like to:
echo 1. Copy to Program Files (requires admin)
echo 2. Copy to current directory
echo 3. Keep in temp directory (temporary)
set /p choice="Enter choice (1-3, default: 2): "

if "%choice%"=="1" (
    if %isAdmin%==1 (
        set targetDir=%ProgramFiles%\SignatureBridge
    ) else (
        echo Admin privileges required for Program Files. Using current directory.
        set targetDir=%CD%\SignatureBridge
    )
) else if "%choice%"=="3" (
    set targetDir=%publishDir%
) else (
    set targetDir=%CD%\SignatureBridge
)

echo.
echo Copying files to: %targetDir%
if not exist "%targetDir%" mkdir "%targetDir%"
xcopy "%publishDir%\*" "%targetDir%\" /E /I /Y
set exePath=%targetDir%\SignatureBridge.exe

echo.
echo ============================================
echo  Installation Complete
echo ============================================
echo.
echo Application: %exePath%
echo Config file: %targetDir%\config.json
echo.

set /p start="Start application now? (y/n): "
if /i "%start%"=="y" (
    echo Starting application...
    start "" "%exePath%"
)

echo.
echo For configuration, edit: %targetDir%\config.json
echo.

if not "%choice%"=="3" (
    set /p cleanup="Delete temporary files? (y/n): "
    if /i "%cleanup%"=="y" (
        cd /d "%USERPROFILE%"
        rmdir /s /q "%tempDir%"
        echo Temporary files cleaned up.
    )
)

pause
