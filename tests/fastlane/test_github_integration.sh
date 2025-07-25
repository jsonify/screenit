#!/bin/bash

# Test script for GitHub Integration and Version Management
# Tests for Task 5: GitHub Integration and Version Management

set -e

echo "Testing GitHub Integration and Version Management..."

# Test 5.2: Test validate_github_sync lane
test_validate_github_sync() {
    echo "  Testing validate_github_sync lane..."
    
    # Run validate_github_sync (should not fail even without GitHub CLI)
    if ! fastlane validate_github_sync > /dev/null 2>&1; then
        echo "  ❌ validate_github_sync lane failed"
        return 1
    fi
    
    echo "  ✅ validate_github_sync lane succeeded"
}

# Test 5.3: Test sync_version_with_github lane
test_sync_version_with_github() {
    echo "  Testing sync_version_with_github lane..."
    
    # Run sync_version_with_github (should handle missing GitHub CLI gracefully)
    if ! fastlane sync_version_with_github > /dev/null 2>&1; then
        echo "  ❌ sync_version_with_github lane failed"
        return 1
    fi
    
    echo "  ✅ sync_version_with_github lane succeeded"
}

# Test 5.4: Test semantic version parsing
test_semantic_version() {
    echo "  Testing semantic version parsing..."
    
    # Check if Info.plist has a valid semantic version
    if [ ! -f "Info.plist" ]; then
        echo "  ❌ Info.plist not found"
        return 1
    fi
    
    version=$(plutil -extract CFBundleShortVersionString raw Info.plist 2>/dev/null || echo "")
    if [ -z "$version" ]; then
        echo "  ❌ Version not found in Info.plist"
        return 1
    fi
    
    # Check if version follows semantic versioning (X.Y.Z)
    if ! echo "$version" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' > /dev/null; then
        echo "  ❌ Version '$version' is not in semantic format (X.Y.Z)"
        return 1
    fi
    
    echo "  ✅ Semantic version format validated: $version"
}

# Test 5.7: Test version synchronization capabilities
test_version_sync_capabilities() {
    echo "  Testing version synchronization capabilities..."
    
    # Test that lanes can handle both with and without GitHub CLI
    local has_gh_cli=false
    if command -v gh > /dev/null 2>&1; then
        has_gh_cli=true
        echo "    GitHub CLI available: testing with real CLI"
    else
        echo "    GitHub CLI not available: testing fallback behavior"
    fi
    
    # Both scenarios should work without fatal errors
    if ! fastlane validate_github_sync > /dev/null 2>&1; then
        echo "  ❌ Version sync capabilities test failed"
        return 1
    fi
    
    echo "  ✅ Version synchronization capabilities validated"
}

# Run all tests
run_tests() {
    echo "Running GitHub Integration Tests..."
    
    # Check if fastlane is available
    if ! command -v fastlane > /dev/null 2>&1; then
        echo "  ❌ Fastlane not installed - cannot test GitHub integration"
        return 1
    fi
    
    test_validate_github_sync || return 1
    test_sync_version_with_github || return 1
    test_semantic_version || return 1
    test_version_sync_capabilities || return 1
    
    echo "✅ All GitHub Integration tests passed!"
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi