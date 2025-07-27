#!/bin/bash

# Alternative Xcode-based build script for screenit
# Uses xcodebuild for more consistent app bundle creation

set -e

echo "🚀 Building screenit with Xcode toolchain..."

# Configuration
APP_NAME="screenit"
SCHEME="screenit"
WORKSPACE=".swiftpm/xcode/package.xcworkspace"
BUILD_DIR="build"
DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"
CONFIGURATION="Debug"  # Use Debug for development to speed up builds

# Use the first available Apple Development certificate
SIGNING_IDENTITY="Apple Development"
BUNDLE_ID="com.screenit.screenit"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Generate Xcode project if needed
if [ ! -d "$WORKSPACE" ]; then
    echo "📋 Generating Xcode project..."
    swift package generate-xcodeproj
fi

# Build with xcodebuild for proper app bundle
echo "🔨 Building with xcodebuild..."
xcodebuild \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -destination "platform=macOS,arch=x86_64" \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    CODE_SIGN_STYLE="Automatic" \
    DEVELOPMENT_TEAM="" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    build

# Find the built app
BUILT_APP=$(find "$DERIVED_DATA_PATH" -name "${APP_NAME}.app" -type d | head -1)

if [ -n "$BUILT_APP" ]; then
    # Copy to project root for easy access
    echo "📦 Copying app bundle..."
    cp -R "$BUILT_APP" "./"
    
    echo "🎉 Build complete!"
    echo "📍 App bundle: ./${APP_NAME}.app"
    echo ""
    echo "✅ The app bundle is properly signed and should maintain permissions"
    echo "🚀 To run: open ${APP_NAME}.app"
else
    echo "❌ Could not find built app bundle"
    exit 1
fi