#!/bin/bash

# Version bumping utility for semantic versioning
# Usage: ./bump_version.sh [current_version] [increment_type]
# Example: ./bump_version.sh v1.2.3 patch → 1.2.4

set -e

# Parse version string and extract major.minor.patch
parse_version() {
    local version="$1"
    
    # Remove 'v' prefix if present
    version="${version#v}"
    
    # Validate version format (major.minor.patch)
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "" >&2
        return 1
    fi
    
    echo "$version"
}

# Increment version based on type (major, minor, patch)
increment_version() {
    local current_version="$1"
    local increment_type="$2"
    
    # Handle initial version creation
    if [[ -z "$current_version" || "$current_version" == "" ]]; then
        case "$increment_type" in
            "major")
                echo "1.0.0"
                return 0
                ;;
            "minor"|"patch")
                echo "0.1.0"
                return 0
                ;;
            *)
                echo "" >&2
                return 1
                ;;
        esac
    fi
    
    # Parse current version
    local parsed_version
    parsed_version=$(parse_version "$current_version")
    if [[ -z "$parsed_version" ]]; then
        echo "" >&2
        return 1
    fi
    
    # Split version into components
    IFS='.' read -r major minor patch <<< "$parsed_version"
    
    # Increment based on type
    case "$increment_type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            echo "" >&2
            return 1
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# Format version with v prefix for git tags
format_version_tag() {
    local version="$1"
    echo "v${version}"
}

# Get latest git tag
get_latest_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo ""
}

# Validate increment type
validate_increment_type() {
    local type="$1"
    case "$type" in
        "major"|"minor"|"patch")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Main function for command-line usage
main() {
    local current_version="$1"
    local increment_type="$2"
    
    # Show usage if no arguments
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 [current_version] [increment_type]"
        echo "       $0 v1.2.3 patch    # → 1.2.4"
        echo "       $0 v1.2.3 minor    # → 1.3.0"
        echo "       $0 v1.2.3 major    # → 2.0.0"
        echo ""
        echo "If current_version is empty, creates initial version:"
        echo "       $0 \"\" patch      # → 0.1.0"
        echo "       $0 \"\" major      # → 1.0.0"
        exit 1
    fi
    
    # Validate increment type
    if ! validate_increment_type "$increment_type"; then
        echo "Error: Invalid increment type '$increment_type'" >&2
        echo "Valid types: major, minor, patch" >&2
        exit 1
    fi
    
    # If no current version provided, try to get from git
    if [[ -z "$current_version" ]]; then
        current_version=$(get_latest_tag)
    fi
    
    # Calculate new version
    local new_version
    new_version=$(increment_version "$current_version" "$increment_type")
    
    if [[ -z "$new_version" ]]; then
        echo "Error: Failed to calculate new version" >&2
        exit 1
    fi
    
    echo "$new_version"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi