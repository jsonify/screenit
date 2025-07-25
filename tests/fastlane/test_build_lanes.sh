#!/bin/bash

# Test script for Core Build Lane Implementation
# Tests for Task 2: Core Build Lane Implementation

set -e

echo "Testing Core Build Lane Implementation..."

# Test 2.1: Test build lane functionality
test_build_debug_lane() {
    echo "  Testing build_debug lane..."
    
    # Clean first
    fastlane clean > /dev/null 2>&1
    
    # Run build_debug
    if ! fastlane build_debug > /dev/null 2>&1; then
        echo "  ❌ build_debug lane failed"
        return 1
    fi
    
    # Check if debug app was created
    if [ ! -d "dist/screenit-Debug.app" ]; then
        echo "  ❌ Debug app not found in dist directory"
        return 1
    fi
    
    echo "  ✅ build_debug lane succeeded"
}

test_build_release_lane() {
    echo "  Testing build_release lane..."
    
    # Run build_release
    if ! fastlane build_release > /dev/null 2>&1; then
        echo "  ❌ build_release lane failed"
        return 1
    fi
    
    # Check if release app was created
    if [ ! -d "dist/screenit-Release.app" ]; then
        echo "  ❌ Release app not found in dist directory"
        return 1
    fi
    
    echo "  ✅ build_release lane succeeded"
}

# Test 2.5: Test build artifact validation
test_build_artifacts() {
    echo "  Testing build artifact validation..."
    
    # Check if apps are executable
    debug_binary="dist/screenit-Debug.app/Contents/MacOS/screenit"
    release_binary="dist/screenit-Release.app/Contents/MacOS/screenit"
    
    if [ ! -x "$debug_binary" ]; then
        echo "  ❌ Debug binary is not executable"
        return 1
    fi
    
    if [ ! -x "$release_binary" ]; then
        echo "  ❌ Release binary is not executable"
        return 1
    fi
    
    # Check if Info.plist exists
    if [ ! -f "dist/screenit-Debug.app/Contents/Info.plist" ]; then
        echo "  ❌ Debug Info.plist missing"
        return 1
    fi
    
    if [ ! -f "dist/screenit-Release.app/Contents/Info.plist" ]; then
        echo "  ❌ Release Info.plist missing"
        return 1
    fi
    
    echo "  ✅ Build artifacts validated"
}

# Test 2.7: Verify functional app bundles
test_app_bundle_functionality() {
    echo "  Testing app bundle functionality..."
    
    # Test that the apps can be launched (just check they exist and are valid bundles)
    if ! /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep -q "screenit" > /dev/null 2>&1; then
        # Try to validate the bundle structure at least
        if [ ! -d "dist/screenit-Release.app/Contents/MacOS" ]; then
            echo "  ❌ App bundle structure is invalid"
            return 1
        fi
    fi
    
    echo "  ✅ App bundles appear functional"
}

# Run all tests
run_tests() {
    echo "Running Core Build Lane Tests..."
    
    # Check if fastlane is available
    if ! command -v fastlane > /dev/null 2>&1; then
        echo "  ❌ Fastlane not installed - cannot test build lanes"
        return 1
    fi
    
    test_build_debug_lane || return 1
    test_build_release_lane || return 1
    test_build_artifacts || return 1
    test_app_bundle_functionality || return 1
    
    echo "✅ All Core Build Lane tests passed!"
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi