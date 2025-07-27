#!/bin/bash

# Test framework for release.sh
# Usage: ./test_release.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework functions
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo -e "${YELLOW}Running: $test_name${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if $test_function; then
        echo -e "${GREEN}✓ PASS: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "  Expected: '$expected'"
        echo "  Actual: '$actual'"
        [[ -n "$message" ]] && echo "  Message: $message"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "  Expected to contain: '$needle'"
        echo "  Actual: '$haystack'"
        [[ -n "$message" ]] && echo "  Message: $message"
        return 1
    fi
}

# Mock functions for testing
mock_git() {
    case "$1" in
        "describe")
            echo "v1.0.0"
            ;;
        "add")
            return 0
            ;;
        "commit")
            return 0
            ;;
        "tag")
            return 0
            ;;
        "push")
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

mock_swift() {
    case "$1" in
        "test")
            echo "Test Suite 'All tests' passed"
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

mock_plistbuddy() {
    return 0
}

# Test functions
test_argument_parsing_valid() {
    source ../release.sh
    
    # Mock git command
    alias git=mock_git
    
    local result=$(parse_arguments "patch" 2>/dev/null)
    assert_equals "patch" "$result" "Should parse patch argument correctly"
    
    unalias git
}

test_argument_parsing_invalid() {
    source ../release.sh
    
    local result=$(parse_arguments "invalid" 2>/dev/null)
    assert_equals "" "$result" "Should reject invalid argument"
}

test_info_plist_detection() {
    # Create temporary Info.plist for testing
    local temp_plist="/tmp/test_Info.plist"
    cat > "$temp_plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
</dict>
</plist>
EOF
    
    source ../release.sh
    
    local result=$(find_info_plist "/tmp")
    assert_equals "$temp_plist" "$result" "Should find Info.plist file"
    
    rm -f "$temp_plist"
}

test_version_calculation() {
    source ../release.sh
    
    # Mock git to return v1.0.0
    alias git=mock_git
    
    local result=$(calculate_new_version "patch")
    assert_equals "1.0.1" "$result" "Should calculate new patch version"
    
    unalias git
}

test_dry_run_mode() {
    source ../release.sh
    
    # Mock commands
    alias git=mock_git
    alias swift=mock_swift
    alias /usr/libexec/PlistBuddy=mock_plistbuddy
    
    DRY_RUN=1
    local output=$(release_workflow "patch" 2>&1)
    assert_contains "$output" "DRY RUN" "Should indicate dry run mode"
    
    unalias git swift /usr/libexec/PlistBuddy
}

test_usage_display() {
    source ../release.sh
    
    local output=$(show_usage 2>&1)
    assert_contains "$output" "Usage:" "Should show usage information"
    assert_contains "$output" "patch" "Should mention patch option"
    assert_contains "$output" "minor" "Should mention minor option"
    assert_contains "$output" "major" "Should mention major option"
}

test_build_validation() {
    source ../release.sh
    
    # Mock successful swift test
    alias swift=mock_swift
    
    local result=$(validate_build 2>&1)
    local exit_code=$?
    assert_equals "0" "$exit_code" "Should pass with successful tests"
    
    unalias swift
}

test_git_operations() {
    source ../release.sh
    
    # Mock git commands
    alias git=mock_git
    
    DRY_RUN=1  # Use dry run to avoid actual git operations
    local result=$(perform_git_operations "1.0.1" 2>&1)
    local exit_code=$?
    assert_equals "0" "$exit_code" "Should complete git operations successfully"
    
    unalias git
}

test_error_handling() {
    source ../release.sh
    
    # Mock failing swift test
    mock_swift_fail() {
        return 1
    }
    alias swift=mock_swift_fail
    
    local result=$(validate_build 2>&1)
    local exit_code=$?
    assert_equals "1" "$exit_code" "Should fail with failing tests"
    
    unalias swift
}

# Main test runner
main() {
    echo "🧪 Running release.sh tests..."
    echo "==============================="
    echo
    
    # Run all tests
    run_test "Argument parsing - valid" test_argument_parsing_valid
    run_test "Argument parsing - invalid" test_argument_parsing_invalid
    run_test "Info.plist detection" test_info_plist_detection
    run_test "Version calculation" test_version_calculation
    run_test "Dry run mode" test_dry_run_mode
    run_test "Usage display" test_usage_display
    run_test "Build validation" test_build_validation
    run_test "Git operations" test_git_operations
    run_test "Error handling" test_error_handling
    
    # Summary
    echo "==============================="
    echo "Test Results:"
    echo "  Total: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed! ✨${NC}"
        exit 0
    else
        echo -e "${RED}$TESTS_FAILED test(s) failed! ❌${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi