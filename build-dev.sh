#!/bin/bash

# Development build script for screenit
# This ensures consistent code signing to maintain permissions across builds

set -e

echo "🚀 Building screenit for development..."

# Configuration
APP_NAME="screenit"
BUILD_DIR="build"
DIST_DIR="dist"
BUNDLE_ID="com.screenit.screenit"
ENTITLEMENTS="screenit/screenit.entitlements"
INFO_PLIST="Info.plist"

# Use specific Apple Development certificate (avoiding ambiguity)
SIGNING_IDENTITY="Apple Development: Jason Rueckert (5K35266D72)"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR" "$DIST_DIR" "${APP_NAME}.app"

# Create directories
mkdir -p "$BUILD_DIR" "$DIST_DIR"

# Build with Swift Package Manager
echo "🔨 Building Swift package..."
swift build --configuration release --arch arm64 --arch x86_64

# Create app bundle structure
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "📦 Creating app bundle structure..."
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy executable
echo "📋 Copying executable..."
cp ".build/apple/Products/Release/${APP_NAME}" "$MACOS_DIR/"

# Copy Info.plist
echo "📋 Copying Info.plist..."
cp "$INFO_PLIST" "$CONTENTS_DIR/"

# Copy entitlements to bundle for reference
cp "$ENTITLEMENTS" "$RESOURCES_DIR/"

# Sign the app bundle with entitlements
echo "🔐 Code signing app bundle..."
codesign --force --sign "$SIGNING_IDENTITY" --entitlements "$ENTITLEMENTS" --options runtime "$APP_BUNDLE"

# Verify signing
echo "✅ Verifying code signature..."
codesign --verify --verbose "$APP_BUNDLE"

echo "🎉 Build complete!"
echo "📍 App bundle created at: $APP_BUNDLE"
echo ""
echo "To maintain permissions across builds:"
echo "1. Use this script for all development builds"
echo "2. The same signing identity will be used consistently"
echo "3. Permissions should persist between builds"
echo ""
echo "To install: open $APP_BUNDLE"