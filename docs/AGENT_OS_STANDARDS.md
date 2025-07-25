# Agent-OS Standards for screenit Project

This document defines the Agent-OS standards and organizational principles used in the screenit project.

## Directory Organization Standards

### Root Directory Structure
```
screenit/
├── docs/                    # All documentation
│   ├── automation/         # Build and automation docs
│   ├── development/        # Development guides
│   └── deployment/         # Deployment instructions
├── scripts/                # Automation and utility scripts
│   ├── automation/         # Build and deployment scripts
│   └── test-runner.sh      # Master test runner
├── tests/                  # All test files
│   ├── fastlane/          # Fastlane-specific tests
│   ├── integration/       # Integration tests
│   └── test-utils.sh      # Common test utilities
├── fastlane/              # Fastlane configuration
├── screenit/              # Source code
├── .agent-os/             # Agent-OS specifications
└── .tmp/                  # Temporary files (git ignored)
```

### Test Organization Principles

#### 1. Test Directory Structure
- **Location**: All tests in `tests/` directory
- **Categorization**: Tests grouped by functionality (fastlane, integration, unit)
- **Utilities**: Common test utilities in `tests/test-utils.sh`
- **Naming**: Test files follow pattern `test_[feature]_[category].sh`

#### 2. Test File Standards
```bash
#!/bin/bash
# Standard test file header with description
# Follows Agent-OS standards for test organization and cleanup

set -e

# Load test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../test-utils.sh"

# Setup and cleanup
test_setup
trap 'test_cleanup false' EXIT

# Test implementation...

# Standard footer
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit_code=0
    run_tests || exit_code=$?
    test_footer "Test Category" $exit_code
    exit $exit_code
fi
```

#### 3. Cleanup Procedures
All tests must implement proper cleanup:
- **Process Cleanup**: Kill any spawned processes
- **File Cleanup**: Remove temporary files and build artifacts
- **Directory Cleanup**: Clean temporary directories
- **State Reset**: Restore original state when possible

### Script Organization Principles

#### 1. Script Categories
- **`scripts/automation/`**: Build, deployment, and automation scripts
- **`scripts/test-runner.sh`**: Master test runner with Agent-OS standards
- **Root level**: Only essential scripts (minimal)

#### 2. Script Standards
- Proper error handling with `set -e`
- Logging functions for consistent output
- Help documentation with `--help` flag
- Cleanup procedures on exit
- Configuration through environment variables

### Documentation Organization Principles

#### 1. Documentation Structure
- **`docs/automation/`**: Build system, CI/CD, deployment automation
- **`docs/development/`**: Development guides, coding standards, APIs
- **`docs/deployment/`**: Deployment procedures, environment setup

#### 2. Documentation Standards
- **Naming**: Descriptive names in UPPER_CASE.md for main docs
- **Structure**: Consistent sections (Overview, Prerequisites, Usage, Examples)
- **Cross-references**: Use relative paths for internal links
- **Versioning**: Include version and last updated information

## Implementation Standards

### Cleanup Procedures

#### 1. Test Cleanup Checklist
- [ ] Kill all spawned processes (`pkill -f appname`)
- [ ] Remove temporary build artifacts
- [ ] Clean test-specific directories
- [ ] Restore backed-up files
- [ ] Reset environment state

#### 2. Script Cleanup Checklist
- [ ] Trap cleanup on EXIT
- [ ] Handle SIGINT and SIGTERM
- [ ] Remove temporary files and directories
- [ ] Restore original working directory
- [ ] Clean up background processes

### File Organization Rules

#### 1. Never Put in Root Directory
- Test files (use `tests/`)
- Documentation files (use `docs/`)
- Utility scripts (use `scripts/`)
- Temporary files (use `.tmp/`)

#### 2. Root Directory Exceptions
- Core project files (README.md, CLAUDE.md, Info.plist)
- Build configuration (Dockerfile, package.json, etc.)
- Essential one-off scripts that are project entry points

#### 3. Naming Conventions
- **Tests**: `test_[feature]_[category].sh`
- **Scripts**: `[action]-[target].sh` (e.g., `build-release.sh`)
- **Docs**: `[TOPIC]_[TYPE].md` (e.g., `FASTLANE_USAGE.md`)
- **Directories**: lowercase with hyphens (e.g., `automation/`)

## Agent-OS Integration

### Spec Management
- Specifications in `.agent-os/specs/YYYY-MM-DD-feature-name/`
- Task tracking in `tasks.md` files
- Technical specs in `sub-specs/` directories

### Process Integration
1. **Planning**: Use Agent-OS spec creation for new features
2. **Implementation**: Follow task breakdown in specs
3. **Testing**: Use standardized test structure
4. **Documentation**: Organize docs by category
5. **Cleanup**: Always implement proper cleanup procedures

### Quality Gates
- All tests must pass before marking tasks complete
- Documentation must be in proper directories
- Scripts must include proper error handling
- Cleanup procedures must be implemented and tested

## Migration Guidelines

### Moving Existing Files
1. Identify file type (test, script, documentation)
2. Create appropriate directory structure
3. Move files to correct locations
4. Update references and imports
5. Test functionality after move
6. Update any hardcoded paths

### Updating References
- Update `source` statements in test files
- Update documentation links
- Update script paths in automation
- Update .gitignore if needed

## Best Practices

### For Tests
- Use common utilities for consistent behavior
- Implement proper setup and teardown
- Test cleanup procedures themselves
- Make tests idempotent (can run multiple times)
- Include timeout handling for long operations

### For Scripts
- Always include help documentation
- Use configuration variables instead of hardcoded values
- Implement verbose and quiet modes
- Log important actions and results
- Handle edge cases gracefully

### For Documentation
- Keep documentation close to related code
- Include examples for all procedures
- Document prerequisites clearly
- Provide troubleshooting sections
- Keep documentation up-to-date with code changes

---

This document ensures consistent organization and quality across the screenit project following Agent-OS principles.