#!/bin/bash

# Build script for screenit macOS app
# Uses Swift Package Manager to match Xcode build configuration

set -e  # Exit on any error

echo "🔨 Building screenit with Swift Package Manager..."

# Clean previous build artifacts
rm -rf screenit.app
rm -rf .build

# Build using Swift Package Manager (same as Xcode)
echo "📦 Running swift build..."
swift build --configuration release --arch arm64 --arch x86_64

# Sign the executable with entitlements (if available)
if [ -f "screenit/screenit.entitlements" ]; then
    echo "🔐 Applying entitlements..."
    codesign --force --options runtime --entitlements screenit/screenit.entitlements --sign - .build/apple/Products/Release/screenit
fi

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p screenit.app/Contents/MacOS
mkdir -p screenit.app/Contents/Resources

# Copy the built executable
echo "📋 Copying executable..."
cp .build/apple/Products/Release/screenit screenit.app/Contents/MacOS/

# Copy Info.plist
echo "📋 Copying Info.plist..."
cp Info.plist screenit.app/Contents/

# Copy the compiled resource bundle if it exists and has content
if [ -d ".build/apple/Products/Release/screenit_screenit.bundle" ] && [ "$(ls -A .build/apple/Products/Release/screenit_screenit.bundle/Contents/Resources 2>/dev/null)" ]; then
    echo "📋 Copying compiled resource bundle..."
    cp -R .build/apple/Products/Release/screenit_screenit.bundle screenit.app/Contents/Resources/
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