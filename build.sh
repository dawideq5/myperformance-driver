#!/bin/bash
# Build script for Signature Bridge (for cross-platform builds)
# Note: The final EXE can only be built on Windows, but this script can prepare the project

set -e

CONFIGURATION=${1:-Release}

echo "Building Signature Bridge..."
echo "Building project..."
dotnet publish SignatureBridge/SignatureBridge.csproj \
    --configuration "$CONFIGURATION" \
    --runtime win-x64 \
    --self-contained true \
    --output "SignatureBridge/bin/$CONFIGURATION/net8.0-windows/win-x64/publish"

echo "Build successful!"
echo "Note: To create the installer, run build.ps1 on Windows with Inno Setup installed."
