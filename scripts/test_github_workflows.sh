#!/bin/bash

# Test framework for GitHub Actions workflows
# Usage: ./test_github_workflows.sh

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

assert_file_exists() {
    local file_path="$1"
    local message="$2"
    
    if [[ -f "$file_path" ]]; then
        return 0
    else
        echo "  File not found: $file_path"
        [[ -n "$message" ]] && echo "  Message: $message"
        return 1
    fi
}

assert_directory_exists() {
    local dir_path="$1"
    local message="$2"
    
    if [[ -d "$dir_path" ]]; then
        return 0
    else
        echo "  Directory not found: $dir_path"
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

assert_yaml_valid() {
    local file_path="$1"
    local message="$2"
    
    # Check if file exists first
    if [[ ! -f "$file_path" ]]; then
        echo "  File not found: $file_path"
        return 1
    fi
    
    # Try to parse YAML (basic validation)
    if python3 -c "import yaml; yaml.safe_load(open('$file_path'))" 2>/dev/null; then
        return 0
    else
        echo "  Invalid YAML syntax in: $file_path"
        [[ -n "$message" ]] && echo "  Message: $message"
        return 1
    fi
}

# Test functions
test_workflows_directory_exists() {
    assert_directory_exists "../.github/workflows" "Workflows directory should exist"
}

test_ci_workflow_exists() {
    assert_file_exists "../.github/workflows/ci.yml" "CI workflow file should exist"
}

test_ci_workflow_syntax() {
    assert_yaml_valid "../.github/workflows/ci.yml" "CI workflow should have valid YAML syntax"
}

test_ci_workflow_structure() {
    local ci_content
    ci_content=$(cat "../.github/workflows/ci.yml" 2>/dev/null || echo "")
    
    assert_contains "$ci_content" "name:" "Workflow should have a name" &&
    assert_contains "$ci_content" "on:" "Workflow should have triggers" &&
    assert_contains "$ci_content" "jobs:" "Workflow should have jobs" &&
    assert_contains "$ci_content" "runs-on: macos-latest" "Should use macOS runner"
}

test_ci_workflow_triggers() {
    local ci_content
    ci_content=$(cat "../.github/workflows/ci.yml" 2>/dev/null || echo "")
    
    assert_contains "$ci_content" "pull_request:" "Should trigger on pull requests" &&
    assert_contains "$ci_content" "push:" "Should trigger on pushes"
}

test_ci_workflow_build_steps() {
    local ci_content
    ci_content=$(cat "../.github/workflows/ci.yml" 2>/dev/null || echo "")
    
    assert_contains "$ci_content" "actions/checkout" "Should checkout code" &&
    assert_contains "$ci_content" "swift build" "Should build with swift" &&
    assert_contains "$ci_content" "swift test" "Should run tests"
}

test_release_workflow_exists() {
    assert_file_exists "../.github/workflows/release.yml" "Release workflow file should exist"
}

test_release_workflow_syntax() {
    assert_yaml_valid "../.github/workflows/release.yml" "Release workflow should have valid YAML syntax"
}

test_release_workflow_triggers() {
    local release_content
    release_content=$(cat "../.github/workflows/release.yml" 2>/dev/null || echo "")
    
    assert_contains "$release_content" "tags:" "Should trigger on tags" &&
    assert_contains "$release_content" "- 'v*'" "Should trigger on version tags"
}

test_release_workflow_structure() {
    local release_content
    release_content=$(cat "../.github/workflows/release.yml" 2>/dev/null || echo "")
    
    assert_contains "$release_content" "name:" "Workflow should have a name" &&
    assert_contains "$release_content" "jobs:" "Workflow should have jobs" &&
    assert_contains "$release_content" "runs-on: macos-latest" "Should use macOS runner"
}

# Main test runner
main() {
    echo "🧪 Running GitHub Actions workflow tests..."
    echo "=========================================="
    echo
    
    # Run all tests
    run_test "Workflows directory exists" test_workflows_directory_exists
    run_test "CI workflow file exists" test_ci_workflow_exists
    run_test "CI workflow has valid YAML syntax" test_ci_workflow_syntax
    run_test "CI workflow has proper structure" test_ci_workflow_structure
    run_test "CI workflow has correct triggers" test_ci_workflow_triggers
    run_test "CI workflow has build steps" test_ci_workflow_build_steps
    run_test "Release workflow file exists" test_release_workflow_exists
    run_test "Release workflow has valid YAML syntax" test_release_workflow_syntax
    run_test "Release workflow has correct triggers" test_release_workflow_triggers
    run_test "Release workflow has proper structure" test_release_workflow_structure
    
    # Summary
    echo "=========================================="
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