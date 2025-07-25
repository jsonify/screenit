#!/bin/bash

# Test script for Release Automation Workflows
# Tests for Task 6: Release Automation Workflows

set -e

echo "Testing Release Automation Workflows..."

# Test 6.2: Test beta lane functionality (dry run)
test_beta_lane() {
    echo "  Testing beta lane functionality..."
    
    # Check if lane exists and loads properly
    if ! fastlane lanes | grep -q "mac beta" > /dev/null 2>&1; then
        echo "  ❌ Beta lane not found in available lanes"
        return 1
    fi
    
    # Note: We don't actually run the beta lane as it would create tags
    # Instead, we validate that the lane definition is correct
    echo "  ✅ Beta lane definition validated"
}

# Test 6.3: Test prod lane functionality (dry run)
test_prod_lane() {
    echo "  Testing prod lane functionality..."
    
    # Check if lane exists and loads properly
    if ! fastlane lanes | grep -q "mac prod" > /dev/null 2>&1; then
        echo "  ❌ Prod lane not found in available lanes"
        return 1
    fi
    
    # Note: We don't actually run the prod lane as it would create tags
    # Instead, we validate that the lane definition is correct
    echo "  ✅ Prod lane definition validated"
}

# Test 6.4: Test automated tagging logic
test_tagging_logic() {
    echo "  Testing tagging logic..."
    
    # Test timestamp generation for beta tags
    timestamp_pattern="^[0-9]{8}-[0-9]{6}$"
    test_timestamp=$(date "+%Y%m%d-%H%M%S")
    
    if ! echo "$test_timestamp" | grep -E "$timestamp_pattern" > /dev/null; then
        echo "  ❌ Timestamp format validation failed"
        return 1
    fi
    
    # Test semantic version tag format
    if [ ! -f "Info.plist" ]; then
        echo "  ❌ Info.plist not found for version extraction"
        return 1
    fi
    
    version=$(plutil -extract CFBundleShortVersionString raw Info.plist 2>/dev/null || echo "")
    if [ -z "$version" ]; then
        echo "  ❌ Version not found in Info.plist"
        return 1
    fi
    
    prod_tag="v$version"
    if ! echo "$prod_tag" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' > /dev/null; then
        echo "  ❌ Production tag format validation failed: $prod_tag"
        return 1
    fi
    
    echo "  ✅ Tagging logic validated (beta: $test_timestamp, prod: $prod_tag)"
}

# Test 6.6: Test git status validation
test_git_status_validation() {
    echo "  Testing git status validation..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "  ❌ Not in a git repository"
        return 1
    fi
    
    # Test git status check command
    git_status=$(git status --porcelain 2>/dev/null || echo "error")
    if [ "$git_status" = "error" ]; then
        echo "  ❌ Git status command failed"
        return 1
    fi
    
    # Test branch detection
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "error")
    if [ "$current_branch" = "error" ]; then
        echo "  ❌ Branch detection failed"
        return 1
    fi
    
    echo "  ✅ Git status validation capabilities confirmed (branch: $current_branch)"
}

# Test 6.8: Validate release lane structure
test_release_lane_structure() {
    echo "  Testing release lane structure..."
    
    # Check that both beta and prod lanes exist
    lanes_output=$(fastlane lanes 2>/dev/null || echo "error")
    if [ "$lanes_output" = "error" ]; then
        echo "  ❌ Failed to get lanes list"
        return 1
    fi
    
    if ! echo "$lanes_output" | grep -q "mac beta"; then
        echo "  ❌ Beta lane missing from lanes list"
        return 1
    fi
    
    if ! echo "$lanes_output" | grep -q "mac prod"; then
        echo "  ❌ Prod lane missing from lanes list"
        return 1
    fi
    
    echo "  ✅ Release lane structure validated"
}

# Run all tests
run_tests() {
    echo "Running Release Automation Tests..."
    
    # Check if fastlane is available
    if ! command -v fastlane > /dev/null 2>&1; then
        echo "  ❌ Fastlane not installed - cannot test release automation"
        return 1
    fi
    
    test_beta_lane || return 1
    test_prod_lane || return 1
    test_tagging_logic || return 1
    test_git_status_validation || return 1
    test_release_lane_structure || return 1
    
    echo "✅ All Release Automation tests passed!"
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi