#!/bin/bash

# Build script for screenit macOS app

echo "Building screenit..."

# Create app bundle structure
mkdir -p screenit.app/Contents/MacOS
mkdir -p screenit.app/Contents/Resources

# Compile all Swift source files for the SwiftUI app
swiftc -parse-as-library -target x86_64-apple-macos15.0 \
    screenit/App/screenitApp.swift \
    screenit/Core/CaptureEngine.swift \
    screenit/Core/SCCaptureManager.swift \
    screenit/Core/ScreenCapturePermissionManager.swift \
    screenit/UI/MenuBar/MenuBarManager.swift \
    -o screenit.app/Contents/MacOS/screenit \
    -framework SwiftUI \
    -framework ScreenCaptureKit \
    -framework UniformTypeIdentifiers

# Copy Info.plist
cp Info.plist screenit.app/Contents/

echo "Build complete! Run with: open screenit.app"
echo "Or run directly: ./screenit.app/Contents/MacOS/screenit"