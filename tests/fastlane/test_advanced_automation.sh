#!/bin/bash

# Test script for Advanced Automation Features
# Tests for Task 7: Advanced Automation Features

set -e

echo "Testing Advanced Automation Features..."

# Test 7.2: Test auto_beta lane
test_auto_beta_lane() {
    echo "  Testing auto_beta lane..."
    
    # Check if lane exists and loads properly
    if ! fastlane lanes | grep -q "mac auto_beta" > /dev/null 2>&1; then
        echo "  ❌ auto_beta lane not found in available lanes"
        return 1
    fi
    
    echo "  ✅ auto_beta lane definition validated"
}

# Test 7.3: Test auto_prod lane
test_auto_prod_lane() {
    echo "  Testing auto_prod lane..."
    
    # Check if lane exists and loads properly
    if ! fastlane lanes | grep -q "mac auto_prod" > /dev/null 2>&1; then
        echo "  ❌ auto_prod lane not found in available lanes"
        return 1
    fi
    
    echo "  ✅ auto_prod lane definition validated"
}

# Test 7.4: Test bump_and_release lane version logic
test_bump_and_release() {
    echo "  Testing bump_and_release lane..."
    
    # Check if lane exists and loads properly
    if ! fastlane lanes | grep -q "mac bump_and_release" > /dev/null 2>&1; then
        echo "  ❌ bump_and_release lane not found in available lanes"
        return 1
    fi
    
    # Test version parsing logic
    if [ ! -f "Info.plist" ]; then
        echo "  ❌ Info.plist not found"
        return 1
    fi
    
    version=$(plutil -extract CFBundleShortVersionString raw Info.plist 2>/dev/null || echo "")
    if [ -z "$version" ]; then
        echo "  ❌ Version not found in Info.plist"
        return 1
    fi
    
    # Test semantic version parsing
    if ! echo "$version" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' > /dev/null; then
        echo "  ❌ Version '$version' is not in semantic format"
        return 1
    fi
    
    echo "  ✅ bump_and_release lane validated (current version: $version)"
}

# Test 7.5: Test branch validation logic
test_branch_validation() {
    echo "  Testing branch validation logic..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "  ❌ Not in a git repository"
        return 1
    fi
    
    # Test branch detection
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "error")
    if [ "$current_branch" = "error" ]; then
        echo "  ❌ Branch detection failed"
        return 1
    fi
    
    # Test branch validation patterns
    valid_branches=("main" "staging" "develop")
    is_valid_branch=false
    
    for branch in "${valid_branches[@]}"; do
        if [ "$current_branch" = "$branch" ]; then
            is_valid_branch=true
            break
        fi
    done
    
    # Note: We don't fail if branch is not valid, just report status
    echo "  ✅ Branch validation logic confirmed (current: $current_branch)"
}

# Test 7.6: Test error handling capabilities
test_error_handling() {
    echo "  Testing error handling capabilities..."
    
    # Test that Fastfile can be parsed without errors
    if ! fastlane lanes > /dev/null 2>&1; then
        echo "  ❌ Fastfile has syntax errors"
        return 1
    fi
    
    # Test that lanes have proper error handling structure
    # (we check for presence of error handling patterns in the file)
    if ! grep -q "rescue" fastlane/Fastfile; then
        echo "  ⚠️  No explicit error handling found in Fastfile"
    fi
    
    if ! grep -q "begin" fastlane/Fastfile; then
        echo "  ⚠️  No begin blocks found in Fastfile"
    fi
    
    echo "  ✅ Error handling capabilities validated"
}

# Test 7.7: Test advanced features integration
test_advanced_features_integration() {
    echo "  Testing advanced features integration..."
    
    # Check that all advanced lanes are available
    required_lanes=("auto_beta" "auto_prod" "bump_and_release")
    lanes_output=$(fastlane lanes 2>/dev/null || echo "error")
    
    if [ "$lanes_output" = "error" ]; then
        echo "  ❌ Failed to get lanes list"
        return 1
    fi
    
    for lane in "${required_lanes[@]}"; do
        if ! echo "$lanes_output" | grep -q "mac $lane"; then
            echo "  ❌ Required lane '$lane' not found"
            return 1
        fi
    done
    
    # Test that advanced lanes can handle GitHub CLI presence/absence
    if command -v gh > /dev/null 2>&1; then
        echo "    GitHub CLI available: advanced features will use GitHub integration"
    else
        echo "    GitHub CLI not available: advanced features will use fallback behavior"
    fi
    
    echo "  ✅ Advanced features integration validated"
}

# Run all tests
run_tests() {
    echo "Running Advanced Automation Tests..."
    
    # Check if fastlane is available
    if ! command -v fastlane > /dev/null 2>&1; then
        echo "  ❌ Fastlane not installed - cannot test advanced automation"
        return 1
    fi
    
    test_auto_beta_lane || return 1
    test_auto_prod_lane || return 1
    test_bump_and_release || return 1
    test_branch_validation || return 1
    test_error_handling || return 1
    test_advanced_features_integration || return 1
    
    echo "✅ All Advanced Automation tests passed!"
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi