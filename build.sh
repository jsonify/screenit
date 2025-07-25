#!/bin/bash

# Build script for screenit macOS app

echo "Building screenit..."

# Create app bundle structure
mkdir -p screenit.app/Contents/MacOS
mkdir -p screenit.app/Contents/Resources

# Compile the Swift app with both source files
swiftc -parse-as-library -target x86_64-apple-macos15.0 main.swift CaptureEngine.swift -o screenit.app/Contents/MacOS/screenit

# Copy Info.plist
cp Info.plist screenit.app/Contents/

echo "Build complete! Run with: open screenit.app"
echo "Or run directly: ./screenit.app/Contents/MacOS/screenit"
echo ""
echo "To run tests: swift test_capture_engine.swift"