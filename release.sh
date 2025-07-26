#!/bin/bash

# 🚀 Awesome Release Tool for screenit
# Usage: ./release.sh [patch|minor|major]
# Example: ./release.sh patch  # 1.0.0 → 1.0.1

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=${DRY_RUN:-0}
VERBOSE=${VERBOSE:-0}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

log_step() {
    echo -e "${BOLD}🔥 $1${NC}"
}

# Source the version bumping utility
if [[ -f "$SCRIPT_DIR/scripts/bump_version.sh" ]]; then
    source "$SCRIPT_DIR/scripts/bump_version.sh"
else
    log_error "Could not find bump_version.sh script"
    exit 1
fi

# Show usage information
show_usage() {
    cat << EOF
🚀 screenit Release Tool

Usage: $0 [patch|minor|major] [options]

Version Types:
  patch    Increment patch version (1.0.0 → 1.0.1)
  minor    Increment minor version (1.0.0 → 1.1.0)
  major    Increment major version (1.0.0 → 2.0.0)

Options:
  --dry-run    Show what would be done without executing
  --verbose    Show detailed output
  --help       Show this help message

Examples:
  $0 patch           # Create patch release
  $0 minor --dry-run # Preview minor release
  $0 major --verbose # Create major release with detailed output

This tool will:
  1. Calculate the new version based on git tags
  2. Update Info.plist with the new version
  3. Run tests to ensure code quality
  4. Commit changes and create git tag
  5. Push to remote, triggering CI/CD pipeline

EOF
}

# Parse command line arguments
parse_arguments() {
    local version_type=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_usage
                exit 0
                ;;
            patch|minor|major)
                if [[ -n "$version_type" ]]; then
                    log_error "Multiple version types specified"
                    return 1
                fi
                version_type="$1"
                ;;
            --dry-run)
                DRY_RUN=1
                ;;
            --verbose)
                VERBOSE=1
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
    
    if [[ -z "$version_type" ]]; then
        log_error "Version type required (patch, minor, or major)"
        show_usage
        exit 1
    fi
    
    echo "$version_type"
}

# Find Info.plist file in the project
find_info_plist() {
    local search_dir="${1:-$PROJECT_ROOT}"
    
    # Common locations for Info.plist in Swift Package projects
    local plist_locations=(
        "$search_dir/screenit/Info.plist"
        "$search_dir/Info.plist"
        "$search_dir/Sources/screenit/Resources/Info.plist"
    )
    
    for plist in "${plist_locations[@]}"; do
        if [[ -f "$plist" ]]; then
            echo "$plist"
            return 0
        fi
    done
    
    # Search recursively as fallback
    find "$search_dir" -name "Info.plist" -type f | head -1
}

# Get current version from git tags
get_current_version() {
    local latest_tag
    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [[ -n "$latest_tag" ]]; then
        echo "$latest_tag"
    else
        log_warning "No existing tags found. Starting from v0.0.0" >&2
        echo "v0.0.0"
    fi
}

# Calculate new version using bump_version.sh
calculate_new_version() {
    local version_type="$1"
    local current_version
    
    current_version=$(get_current_version)
    log_info "Current version: $current_version" >&2
    
    local new_version
    new_version=$(increment_version "$current_version" "$version_type")
    
    if [[ -z "$new_version" ]]; then
        log_error "Failed to calculate new version from $current_version with type $version_type"
        exit 1
    fi
    
    echo "$new_version"
}

# Update Info.plist with new version
update_info_plist() {
    local new_version="$1"
    local plist_path
    
    plist_path=$(find_info_plist)
    
    if [[ -z "$plist_path" || ! -f "$plist_path" ]]; then
        log_warning "Info.plist not found, skipping version update"
        return 0
    fi
    
    log_info "Updating $plist_path with version $new_version"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "DRY RUN: Would update Info.plist CFBundleShortVersionString to $new_version"
        return 0
    fi
    
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $new_version" "$plist_path" 2>/dev/null || {
        log_warning "Could not update CFBundleShortVersionString, trying to add it"
        /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $new_version" "$plist_path"
    }
    
    log_success "Updated Info.plist version to $new_version"
}

# Validate build by running tests
validate_build() {
    log_step "Running tests to validate build..."
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "DRY RUN: Would run swift test"
        return 0
    fi
    
    local test_result
    if [[ $VERBOSE -eq 1 ]]; then
        swift test
        test_result=$?
    else
        swift test > /dev/null 2>&1
        test_result=$?
    fi
    
    if [[ $test_result -eq 0 ]]; then
        log_success "All tests passed"
    else
        log_error "Tests failed! Aborting release."
        log_info "Tip: Use --dry-run to skip tests for testing the workflow"
        exit 1
    fi
}

# Perform git operations
perform_git_operations() {
    local new_version="$1"
    local tag_name="v$new_version"
    
    log_step "Performing git operations..."
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "DRY RUN: Would perform the following git operations:"
        log_warning "  git add ."
        log_warning "  git commit -m '🔖 Bump version to $new_version'"
        log_warning "  git tag $tag_name"
        log_warning "  git push origin main --tags"
        return 0
    fi
    
    # Check if there are changes to commit
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_info "Committing version changes..."
        git add .
        git commit -m "🔖 Bump version to $new_version"
    else
        log_info "No changes to commit"
    fi
    
    # Create and push tag
    log_info "Creating tag $tag_name..."
    git tag "$tag_name"
    
    log_info "Pushing changes and tags..."
    git push origin main --tags
    
    log_success "Git operations completed"
}

# Main release workflow
release_workflow() {
    local version_type="$1"
    
    log_step "🚀 Starting $version_type release workflow..."
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "DRY RUN MODE - No changes will be made"
    fi
    
    # Calculate new version
    local new_version
    new_version=$(calculate_new_version "$version_type")
    log_success "New version: $new_version"
    
    # Update Info.plist
    update_info_plist "$new_version"
    
    # Validate build
    validate_build
    
    # Git operations
    perform_git_operations "$new_version"
    
    # Success message
    if [[ $DRY_RUN -eq 1 ]]; then
        log_success "Dry run completed! Use without --dry-run to execute."
    else
        log_success "✨ Release v$new_version completed successfully!"
        log_info "🔗 GitHub Actions will now build and create the release"
        log_info "🎉 Check https://github.com/your-repo/screenit/releases for the new release"
    fi
}

# Main function
main() {
    # Handle help first
    for arg in "$@"; do
        if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
            show_usage
            exit 0
        fi
    done
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
    
    # Parse arguments
    local version_type
    version_type=$(parse_arguments "$@")
    
    # Run the release workflow
    release_workflow "$version_type"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi