#!/bin/bash

# Build script for screenit macOS app
<<<<<<< HEAD
# Uses Swift Package Manager to match Xcode build configuration

set -e  # Exit on any error

echo "🔨 Building screenit with Swift Package Manager..."

# Clean previous build artifacts
rm -rf screenit.app
rm -rf .build

# Build using Swift Package Manager (same as Xcode) - Use Debug to match Xcode
echo "📦 Running swift build..."
swift build --configuration debug --arch arm64 --arch x86_64

# Sign the executable with entitlements (if available)
if [ -f "screenit/screenit.entitlements" ]; then
    echo "🔐 Applying entitlements..."
    codesign --force --options runtime --entitlements screenit/screenit.entitlements --sign - .build/apple/Products/Debug/screenit
fi

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p screenit.app/Contents/MacOS
mkdir -p screenit.app/Contents/Resources

# Copy the built executable
echo "📋 Copying executable..."
cp .build/apple/Products/Debug/screenit screenit.app/Contents/MacOS/

# Copy Info.plist
echo "📋 Copying Info.plist..."
cp Info.plist screenit.app/Contents/

# Copy the compiled resource bundle if it exists and has content
if [ -d ".build/apple/Products/Debug/screenit_screenit.bundle" ] && [ "$(ls -A .build/apple/Products/Debug/screenit_screenit.bundle/Contents/Resources 2>/dev/null)" ]; then
    echo "📋 Copying compiled resource bundle..."
    cp -R .build/apple/Products/Debug/screenit_screenit.bundle screenit.app/Contents/Resources/
else
    echo "📋 No separate resource bundle found - assets should be embedded in executable"
fi

# Set executable permissions
chmod +x screenit.app/Contents/MacOS/screenit

# Sign the complete app bundle (don't copy entitlements to bundle)
if [ -f "screenit/screenit.entitlements" ]; then
    echo "🔐 Signing app bundle..."
    codesign --force --options runtime --entitlements screenit/screenit.entitlements --sign - screenit.app
else
    echo "🔐 Signing app bundle without entitlements..."
    codesign --force --sign - screenit.app
fi

echo "✅ Build complete! App bundle: screenit.app"
echo "🚀 Run with: open screenit.app"
=======

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
>>>>>>> fastlane-build-automation
