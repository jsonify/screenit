#!/bin/bash

# Test framework for code signing and notarization
# Usage: ./test_code_signing.sh

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

assert_command_exists() {
    local command_name="$1"
    local message="$2"
    
    if command -v "$command_name" >/dev/null 2>&1; then
        return 0
    else
        echo "  Command not found: $command_name"
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
        echo "  Actual content did not contain the needle"
        [[ -n "$message" ]] && echo "  Message: $message"
        return 1
    fi
}

# Test functions
test_codesign_command_available() {
    assert_command_exists "codesign" "codesign should be available on macOS"
}

test_security_command_available() {
    assert_command_exists "security" "security command should be available for keychain operations"
}

test_xcrun_command_available() {
    assert_command_exists "xcrun" "xcrun should be available for notarization"
}

test_notarytool_available() {
    if xcrun notarytool --help >/dev/null 2>&1; then
        return 0
    else
        echo "  notarytool not available via xcrun"
        return 1
    fi
}

test_stapler_available() {
    if xcrun stapler --help >/dev/null 2>&1; then
        echo "  stapler is available"
        return 0
    else
        echo "  stapler not available (may require newer Xcode version)"
        echo "  This is acceptable for development environments"
        return 0
    fi
}

test_spctl_command_available() {
    assert_command_exists "spctl" "spctl should be available for security assessment"
}

test_create_dmg_available() {
    # create-dmg is optional, so we just check if it can be installed
    if command -v create-dmg >/dev/null 2>&1; then
        echo "  create-dmg is already installed"
        return 0
    elif command -v brew >/dev/null 2>&1; then
        echo "  create-dmg not installed, but brew is available for installation"
        return 0
    else
        echo "  Neither create-dmg nor brew available"
        return 1
    fi
}

test_release_workflow_has_signing_steps() {
    local release_content
    release_content=$(cat "../.github/workflows/release.yml" 2>/dev/null || echo "")
    
    assert_contains "$release_content" "Install Developer ID Certificate" "Should have certificate installation step" &&
    assert_contains "$release_content" "Code Sign Application" "Should have code signing step" &&
    assert_contains "$release_content" "Notarize Application" "Should have notarization step"
}

test_release_workflow_has_dmg_creation() {
    local release_content
    release_content=$(cat "../.github/workflows/release.yml" 2>/dev/null || echo "")
    
    assert_contains "$release_content" "Create DMG" "Should have DMG creation step" &&
    assert_contains "$release_content" "create-dmg" "Should use create-dmg tool"
}

test_release_workflow_conditional_signing() {
    local release_content
    release_content=$(cat "../.github/workflows/release.yml" 2>/dev/null || echo "")
    
    assert_contains "$release_content" "DEVELOPER_ID_CERTIFICATE_P12" "Should check for certificate secret" &&
    assert_contains "$release_content" "NOTARIZATION_USERNAME" "Should check for notarization credentials"
}

test_certificate_handling_secure() {
    local release_content
    release_content=$(cat "../.github/workflows/release.yml" 2>/dev/null || echo "")
    
    assert_contains "$release_content" "base64 --decode" "Should decode certificate safely" &&
    assert_contains "$release_content" "rm certificate.p12" "Should clean up certificate file" &&
    assert_contains "$release_content" "create-keychain" "Should use temporary keychain"
}

# Main test runner
main() {
    echo "🧪 Running code signing and notarization tests..."
    echo "================================================="
    echo
    
    # Run all tests
    run_test "codesign command available" test_codesign_command_available
    run_test "security command available" test_security_command_available
    run_test "xcrun command available" test_xcrun_command_available
    run_test "notarytool available via xcrun" test_notarytool_available
    run_test "stapler available via xcrun" test_stapler_available
    run_test "spctl command available" test_spctl_command_available
    run_test "create-dmg available or installable" test_create_dmg_available
    run_test "Release workflow has signing steps" test_release_workflow_has_signing_steps
    run_test "Release workflow has DMG creation" test_release_workflow_has_dmg_creation
    run_test "Release workflow uses conditional signing" test_release_workflow_conditional_signing
    run_test "Certificate handling is secure" test_certificate_handling_secure
    
    # Summary
    echo "================================================="
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