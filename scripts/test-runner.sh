#!/bin/bash

# Master Test Runner for screenit
# Follows Agent-OS standards for test organization and cleanup

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$PROJECT_ROOT/tests"
TEMP_DIR="$PROJECT_ROOT/.tmp"
LOGS_DIR="$PROJECT_ROOT/.logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cleanup function
cleanup() {
    log_info "Starting cleanup procedures..."
    
    # Clean temporary directories
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        log_info "Cleaned temporary directory"
    fi
    
    # Clean build artifacts
    if [ -d "$PROJECT_ROOT/screenit.app" ]; then
        rm -rf "$PROJECT_ROOT/screenit.app"
        log_info "Cleaned build artifacts"
    fi
    
    # Ensure dist directory exists but is clean of test artifacts
    mkdir -p "$PROJECT_ROOT/dist"
    
    # Clean any leftover processes
    pkill -f screenit || true
    
    log_success "Cleanup completed"
}

# Setup function
setup() {
    log_info "Setting up test environment..."
    
    # Create necessary directories
    mkdir -p "$TEMP_DIR" "$LOGS_DIR"
    
    # Ensure we're in the project root
    cd "$PROJECT_ROOT"
    
    # Verify prerequisites
    if ! command -v fastlane > /dev/null 2>&1; then
        log_error "Fastlane not installed"
        exit 1
    fi
    
    log_success "Test environment setup completed"
}

# Run fastlane tests
run_fastlane_tests() {
    log_info "Running Fastlane tests..."
    
    local test_files=(
        "test_fastlane_config.sh"
        "test_build_lanes.sh"
        "test_dev_workflow.sh"
        "test_github_integration.sh"
        "test_release_automation.sh"
        "test_advanced_automation.sh"
    )
    
    local failed_tests=()
    
    for test_file in "${test_files[@]}"; do
        local test_path="$TESTS_DIR/fastlane/$test_file"
        
        if [ -f "$test_path" ]; then
            log_info "Running $test_file..."
            
            if "$test_path" > "$LOGS_DIR/${test_file%.sh}.log" 2>&1; then
                log_success "$test_file passed"
            else
                log_error "$test_file failed"
                failed_tests+=("$test_file")
            fi
        else
            log_warning "$test_file not found at $test_path"
        fi
    done
    
    if [ ${#failed_tests[@]} -eq 0 ]; then
        log_success "All Fastlane tests passed"
        return 0
    else
        log_error "Failed tests: ${failed_tests[*]}"
        return 1
    fi
}

# Run integration tests
run_integration_tests() {
    log_info "Running Integration tests..."
    
    local test_path="$TESTS_DIR/integration/test_integration_complete.sh"
    
    if [ -f "$test_path" ]; then
        log_info "Running integration test suite..."
        
        if "$test_path" > "$LOGS_DIR/integration_complete.log" 2>&1; then
            log_success "Integration tests passed"
            return 0
        else
            log_error "Integration tests failed"
            return 1
        fi
    else
        log_warning "Integration test not found at $test_path"
        return 1
    fi
}

# Display test results summary
display_summary() {
    log_info "Test Results Summary:"
    echo ""
    
    # Count log files to determine test results
    local total_tests=0
    local passed_tests=0
    
    if [ -d "$LOGS_DIR" ]; then
        for log_file in "$LOGS_DIR"/*.log; do
            if [ -f "$log_file" ]; then
                total_tests=$((total_tests + 1))
                if grep -q "✅.*passed" "$log_file"; then
                    passed_tests=$((passed_tests + 1))
                fi
            fi
        done
    fi
    
    echo "  Total Tests: $total_tests"
    echo "  Passed: $passed_tests"
    echo "  Failed: $((total_tests - passed_tests))"
    echo ""
    
    if [ $passed_tests -eq $total_tests ] && [ $total_tests -gt 0 ]; then
        log_success "🎉 All tests passed!"
        return 0
    else
        log_error "❌ Some tests failed. Check logs in $LOGS_DIR"
        return 1
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

# Main execution
main() {
    log_info "Starting screenit test suite with Agent-OS standards..."
    
    # Setup environment
    setup
    
    # Parse command line arguments
    local run_fastlane=true
    local run_integration=true
    local skip_cleanup=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fastlane-only)
                run_integration=false
                shift
                ;;
            --integration-only)
                run_fastlane=false
                shift
                ;;
            --skip-cleanup)
                skip_cleanup=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --fastlane-only     Run only Fastlane tests"
                echo "  --integration-only  Run only integration tests"
                echo "  --skip-cleanup      Skip cleanup procedures"
                echo "  --help             Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    local exit_code=0
    
    # Run tests
    if [ "$run_fastlane" = true ]; then
        if ! run_fastlane_tests; then
            exit_code=1
        fi
    fi
    
    if [ "$run_integration" = true ]; then
        if ! run_integration_tests; then
            exit_code=1
        fi
    fi
    
    # Display results
    if ! display_summary; then
        exit_code=1
    fi
    
    # Skip cleanup if requested
    if [ "$skip_cleanup" = true ]; then
        trap - EXIT
        log_info "Skipping cleanup as requested"
    fi
    
    exit $exit_code
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi