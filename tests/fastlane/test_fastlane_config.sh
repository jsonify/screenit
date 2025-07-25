#!/bin/bash

# Test script for Fastlane configuration validation
# Tests for Task 1: Fastlane Configuration Setup
# Follows Agent-OS standards for test organization and cleanup

set -e

# Load test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../test-utils.sh"

echo "Testing Fastlane Configuration Setup..."

# Setup test environment
test_setup

# Trap cleanup on exit
trap 'test_cleanup false' EXIT

# Test 1.2: Verify fastlane directory structure exists
test_fastlane_directory() {
    echo "  Testing fastlane directory structure..."
    if [ ! -d "fastlane" ]; then
        echo "  ❌ fastlane directory does not exist"
        return 1
    fi
    echo "  ✅ fastlane directory exists"
}

# Test 1.3: Verify Fastfile exists and has required content
test_fastfile() {
    echo "  Testing Fastfile configuration..."
    if [ ! -f "fastlane/Fastfile" ]; then
        echo "  ❌ Fastfile does not exist"
        return 1
    fi
    
    # Check for required constants
    if ! grep -q "APP_NAME.*screenit" fastlane/Fastfile; then
        echo "  ❌ APP_NAME constant not found in Fastfile"
        return 1
    fi
    
    if ! grep -q "BUNDLE_ID.*com.screenit.screenit" fastlane/Fastfile; then
        echo "  ❌ BUNDLE_ID constant not found in Fastfile"
        return 1
    fi
    
    echo "  ✅ Fastfile exists with required constants"
}

# Test 1.4: Verify Appfile exists and has correct bundle identifier
test_appfile() {
    echo "  Testing Appfile configuration..."
    if [ ! -f "fastlane/Appfile" ]; then
        echo "  ❌ Appfile does not exist"
        return 1
    fi
    
    if ! grep -q "app_identifier.*com.screenit.screenit" fastlane/Appfile; then
        echo "  ❌ app_identifier not found in Appfile"
        return 1
    fi
    
    echo "  ✅ Appfile exists with correct bundle identifier"
}

# Test 1.5: Verify analytics opt-out and performance settings
test_analytics_settings() {
    echo "  Testing analytics and performance settings..."
    if ! grep -q "opt_out_usage" fastlane/Fastfile; then
        echo "  ❌ Analytics opt-out not found in Fastfile"
        return 1
    fi
    
    if ! grep -q "skip_docs" fastlane/Fastfile; then
        echo "  ❌ Documentation skip setting not found in Fastfile"
        return 1
    fi
    
    echo "  ✅ Analytics and performance settings configured"
}

# Test 1.6: Verify Fastlane configuration loads without errors
test_fastlane_loads() {
    echo "  Testing Fastlane configuration loading..."
    if ! fastlane lanes > /dev/null 2>&1; then
        echo "  ❌ Fastlane configuration has syntax errors"
        return 1
    fi
    
    echo "  ✅ Fastlane configuration loads without errors"
}

# Run all tests
run_tests() {
    echo "Running Fastlane Configuration Tests..."
    
    test_fastlane_directory || return 1
    test_fastfile || return 1
    test_appfile || return 1
    test_analytics_settings || return 1
    
    # Only test loading if fastlane is installed
    if command -v fastlane > /dev/null 2>&1; then
        test_fastlane_loads || return 1
    else
        echo "  ⚠️  Fastlane not installed - skipping load test"
    fi
    
    echo "✅ All Fastlane configuration tests passed!"
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit_code=0
    run_tests || exit_code=$?
    test_footer "Fastlane Configuration" $exit_code
    exit $exit_code
fi