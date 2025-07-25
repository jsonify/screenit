#!/bin/bash

# Common Test Utilities for screenit
# Agent-OS standardized test functions and cleanup procedures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_TIMEOUT=${TEST_TIMEOUT:-30}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$PROJECT_ROOT/.tmp/tests"
BACKUP_DIR="$PROJECT_ROOT/.tmp/backups"

# Logging functions
test_log_info() {
    echo -e "  ${BLUE}ℹ️${NC} $1"
}

test_log_success() {
    echo -e "  ${GREEN}✅${NC} $1"
}

test_log_warning() {
    echo -e "  ${YELLOW}⚠️${NC} $1"
}

test_log_error() {
    echo -e "  ${RED}❌${NC} $1"
}

# Setup test environment
test_setup() {
    # Create temporary directories
    mkdir -p "$TEMP_DIR" "$BACKUP_DIR"
    
    # Ensure we're in project root
    cd "$PROJECT_ROOT"
    
    # Clean any existing processes
    pkill -f screenit || true
    
    # Ensure dist directory exists
    mkdir -p dist
}

# Cleanup test environment
test_cleanup() {
    local preserve_artifacts=${1:-false}
    
    # Kill any running screenit processes
    pkill -f screenit || true
    
    # Clean temporary build artifacts if not preserving
    if [ "$preserve_artifacts" = false ]; then
        # Remove build artifacts
        [ -d "screenit.app" ] && rm -rf "screenit.app"
        
        # Clean dist directory but preserve it
        if [ -d "dist" ]; then
            find dist -name "*.app" -type d -exec rm -rf {} + 2>/dev/null || true
        fi
    fi
    
    # Always clean temp test directories
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    [ -d "$BACKUP_DIR" ] && rm -rf "$BACKUP_DIR"
}

# Backup a file before testing
test_backup_file() {
    local file_path="$1"
    local backup_name="$2"
    
    if [ -f "$file_path" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file_path" "$BACKUP_DIR/${backup_name}.backup"
        test_log_info "Backed up $file_path"
        return 0
    else
        test_log_warning "File $file_path not found for backup"
        return 1
    fi
}

# Restore a file after testing
test_restore_file() {
    local file_path="$1"
    local backup_name="$2"
    
    if [ -f "$BACKUP_DIR/${backup_name}.backup" ]; then
        cp "$BACKUP_DIR/${backup_name}.backup" "$file_path"
        test_log_info "Restored $file_path"
        return 0
    else
        test_log_warning "Backup file not found for $backup_name"
        return 1
    fi
}

# Run command with timeout and error handling
test_run_command() {
    local timeout_duration="$1"
    local command="$2"
    local description="$3"
    
    test_log_info "Running: $description"
    
    if timeout "$timeout_duration" bash -c "$command" > /dev/null 2>&1; then
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            test_log_error "$description timed out after ${timeout_duration}s"
        else
            test_log_error "$description failed with exit code $exit_code"
        fi
        return $exit_code
    fi
}

# Verify file exists and has expected content
test_verify_file() {
    local file_path="$1"
    local expected_pattern="$2"
    local description="$3"
    
    if [ ! -f "$file_path" ]; then
        test_log_error "$description: File $file_path does not exist"
        return 1
    fi
    
    if [ -n "$expected_pattern" ]; then
        if grep -q "$expected_pattern" "$file_path"; then
            test_log_success "$description: File contains expected content"
            return 0
        else
            test_log_error "$description: File does not contain expected pattern: $expected_pattern"
            return 1
        fi
    else
        test_log_success "$description: File exists"
        return 0
    fi
}

# Verify directory structure
test_verify_directory() {
    local dir_path="$1"
    local description="$2"
    
    if [ -d "$dir_path" ]; then
        test_log_success "$description: Directory exists"
        return 0
    else
        test_log_error "$description: Directory $dir_path does not exist"
        return 1
    fi
}

# Check if command is available
test_check_command() {
    local command="$1"
    local description="$2"
    
    if command -v "$command" > /dev/null 2>&1; then
        test_log_success "$description: Command '$command' available"
        return 0
    else
        test_log_error "$description: Command '$command' not found"
        return 1
    fi
}

# Run fastlane lane safely
test_run_fastlane() {
    local lane="$1"
    local timeout_duration="${2:-$TEST_TIMEOUT}"
    local allow_failure="${3:-false}"
    
    if ! test_run_command "$timeout_duration" "fastlane $lane" "fastlane $lane"; then
        if [ "$allow_failure" = true ]; then
            test_log_warning "fastlane $lane failed (allowed)"
            return 0
        else
            return 1
        fi
    fi
    
    return 0
}

# Validate semantic version format
test_validate_version() {
    local version="$1"
    local description="$2"
    
    if echo "$version" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' > /dev/null; then
        test_log_success "$description: Version format valid ($version)"
        return 0
    else
        test_log_error "$description: Invalid version format ($version)"
        return 1
    fi
}

# Standard test footer
test_footer() {
    local test_name="$1"
    local exit_code="$2"
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        test_log_success "All $test_name tests passed!"
    else
        test_log_error "$test_name tests failed!"
    fi
    
    return $exit_code
}