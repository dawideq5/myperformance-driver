@echo off
REM Auto-switch to PowerShell and run install script
REM This script automatically detects if you're in CMD and switches to PowerShell

echo ============================================
echo  Signature Bridge Auto-Installer
echo ============================================
echo.
echo NOTE: This script requires PowerShell
echo Automatically switching to PowerShell...
echo.

powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/dawideq5/myperformance-driver/main/install.ps1 | iex"

if errorlevel 1 (
    echo.
    echo ============================================
    echo  Installation failed or was cancelled
    echo ============================================
    echo.
    pause
)
