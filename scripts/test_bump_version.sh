#!/bin/bash

# Test framework for bump_version.sh
# Usage: ./test_bump_version.sh

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

# Test functions
test_parse_version_valid() {
    source ./bump_version.sh
    
    local result=$(parse_version "v1.2.3")
    assert_equals "1.2.3" "$result" "Should parse v1.2.3 correctly"
}

test_parse_version_no_v_prefix() {
    source ./bump_version.sh
    
    local result=$(parse_version "1.2.3")
    assert_equals "1.2.3" "$result" "Should parse 1.2.3 without v prefix"
}

test_parse_version_invalid() {
    source ./bump_version.sh
    
    local result=$(parse_version "invalid" 2>/dev/null)
    assert_equals "" "$result" "Should return empty for invalid version"
}

test_increment_patch() {
    source ./bump_version.sh
    
    local result=$(increment_version "1.2.3" "patch")
    assert_equals "1.2.4" "$result" "Should increment patch version"
}

test_increment_minor() {
    source ./bump_version.sh
    
    local result=$(increment_version "1.2.3" "minor")
    assert_equals "1.3.0" "$result" "Should increment minor version and reset patch"
}

test_increment_major() {
    source ./bump_version.sh
    
    local result=$(increment_version "1.2.3" "major")
    assert_equals "2.0.0" "$result" "Should increment major version and reset minor/patch"
}

test_increment_patch_from_zero() {
    source ./bump_version.sh
    
    local result=$(increment_version "0.0.0" "patch")
    assert_equals "0.0.1" "$result" "Should increment from 0.0.0"
}

test_increment_invalid_type() {
    source ./bump_version.sh
    
    local result=$(increment_version "1.2.3" "invalid" 2>/dev/null)
    assert_equals "" "$result" "Should return empty for invalid increment type"
}

test_format_version_tag() {
    source ./bump_version.sh
    
    local result=$(format_version_tag "1.2.3")
    assert_equals "v1.2.3" "$result" "Should format version with v prefix"
}

test_initial_version_creation() {
    source ./bump_version.sh
    
    local result=$(increment_version "" "patch")
    assert_equals "0.1.0" "$result" "Should create initial version for patch"
    
    result=$(increment_version "" "minor")
    assert_equals "0.1.0" "$result" "Should create initial version for minor"
    
    result=$(increment_version "" "major")
    assert_equals "1.0.0" "$result" "Should create initial version for major"
}

# Main test runner
main() {
    echo "🧪 Running bump_version.sh tests..."
    echo "=================================="
    echo
    
    # Run all tests
    run_test "Parse valid version" test_parse_version_valid
    run_test "Parse version without v prefix" test_parse_version_no_v_prefix
    run_test "Parse invalid version" test_parse_version_invalid
    run_test "Increment patch version" test_increment_patch
    run_test "Increment minor version" test_increment_minor
    run_test "Increment major version" test_increment_major
    run_test "Increment patch from zero" test_increment_patch_from_zero
    run_test "Invalid increment type" test_increment_invalid_type
    run_test "Format version tag" test_format_version_tag
    run_test "Initial version creation" test_initial_version_creation
    
    # Summary
    echo "=================================="
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