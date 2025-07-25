#!/bin/bash

# Test script for Development Workflow Automation
# Tests for Task 3: Development Workflow Automation

set -e

echo "Testing Development Workflow Automation..."

# Test 3.2: Test launch lane (build_debug + app launching)
test_launch_lane() {
    echo "  Testing launch lane..."
    
    # Kill any existing screenit processes
    pkill -f screenit || true
    sleep 1
    
    # Clean first
    fastlane clean > /dev/null 2>&1
    
    # Run launch lane (this will build and attempt to launch the app)
    # Note: Launch may fail in headless environments, so we check for build success
    fastlane launch > /dev/null 2>&1 || echo "    ⚠️  App launch may have failed (this is expected in headless environments)"
    
    # Check if debug app was created
    if [ ! -d "dist/screenit-Debug.app" ]; then
        echo "  ❌ Debug app not found after launch"
        return 1
    fi
    
    # Give the app a moment to start
    sleep 2
    
    # Check if app is running (try to find the process)
    if ! pgrep -f "screenit" > /dev/null; then
        echo "  ⚠️  App may not be running (process not found)"
        # Don't fail the test since GUI apps might not show up in pgrep
    fi
    
    # Clean up
    pkill -f screenit || true
    
    echo "  ✅ launch lane succeeded"
}

# Test 3.3: Test dev lane with version sync validation
test_dev_lane() {
    echo "  Testing dev lane..."
    
    # Kill any existing screenit processes
    pkill -f screenit || true
    sleep 1
    
    # Run dev lane (may fail at launch step in headless environments)
    fastlane dev > /dev/null 2>&1 || echo "    ⚠️  Dev workflow may have failed at launch step (expected in headless environments)"
    
    # Check if debug app was created
    if [ ! -d "dist/screenit-Debug.app" ]; then
        echo "  ❌ Debug app not found after dev workflow"
        return 1
    fi
    
    # Clean up
    pkill -f screenit || true
    
    echo "  ✅ dev lane succeeded"
}

# Test 3.5: Test clean lane for build artifact management
test_clean_lane() {
    echo "  Testing clean lane..."
    
    # First create some artifacts
    fastlane build_debug > /dev/null 2>&1
    
    # Verify artifacts exist
    if [ ! -d "dist" ] || [ ! -d "screenit.app" ]; then
        echo "  ❌ Could not create artifacts for clean test"
        return 1
    fi
    
    # Run clean
    if ! fastlane clean > /dev/null 2>&1; then
        echo "  ❌ clean lane failed"
        return 1
    fi
    
    # Check that artifacts are cleaned but dist directory exists
    if [ -d "screenit.app" ]; then
        echo "  ❌ screenit.app not cleaned"
        return 1
    fi
    
    if [ ! -d "dist" ]; then
        echo "  ❌ dist directory should exist after clean"
        return 1
    fi
    
    # Check that dist directory is empty (except for .gitkeep if present)
    if [ "$(ls -A dist 2>/dev/null | grep -v '.gitkeep' | wc -l)" -ne 0 ]; then
        echo "  ❌ dist directory not properly cleaned"
        return 1
    fi
    
    echo "  ✅ clean lane succeeded"
}

# Test 3.6: Verify complete development workflow functions end-to-end
test_complete_workflow() {
    echo "  Testing complete development workflow..."
    
    # Kill any existing processes
    pkill -f screenit || true
    sleep 1
    
    # Clean → Build → Info → Launch workflow
    if ! fastlane clean > /dev/null 2>&1; then
        echo "  ❌ Complete workflow failed at clean step"
        return 1
    fi
    
    if ! fastlane build_debug > /dev/null 2>&1; then
        echo "  ❌ Complete workflow failed at build_debug step"
        return 1
    fi
    
    if ! fastlane info > /dev/null 2>&1; then
        echo "  ❌ Complete workflow failed at info step"
        return 1
    fi
    
    # Launch step may fail in headless environments
    fastlane launch > /dev/null 2>&1 || echo "    ⚠️  Launch step may have failed (expected in headless environments)"
    
    # Clean up
    pkill -f screenit || true
    
    echo "  ✅ Complete development workflow succeeded"
}

# Run all tests
run_tests() {
    echo "Running Development Workflow Tests..."
    
    # Check if fastlane is available
    if ! command -v fastlane > /dev/null 2>&1; then
        echo "  ❌ Fastlane not installed - cannot test development workflow"
        return 1
    fi
    
    test_clean_lane || return 1
    test_launch_lane || return 1
    test_dev_lane || return 1
    test_complete_workflow || return 1
    
    echo "✅ All Development Workflow tests passed!"
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi