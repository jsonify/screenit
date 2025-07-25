# screenit Project Structure

This document provides an overview of the screenit project organization following Agent-OS standards.

## Directory Structure

```
screenit/
├── 📁 .agent-os/                    # Agent-OS specifications and planning
│   ├── product/                     # Product documentation
│   │   ├── mission.md               # Product mission and vision
│   │   ├── tech-stack.md            # Technical architecture
│   │   ├── roadmap.md               # Development roadmap
│   │   └── decisions.md             # Product decisions log
│   └── specs/                       # Feature specifications
│       └── YYYY-MM-DD-feature-name/ # Individual spec directories
│
├── 📁 docs/                         # All project documentation
│   ├── README.md                    # Documentation index
│   ├── AGENT_OS_STANDARDS.md        # Organization standards
│   ├── automation/                  # Build and automation docs
│   │   └── FASTLANE_USAGE.md        # Fastlane guide
│   ├── development/                 # Development guides (TBD)
│   └── deployment/                  # Deployment docs (TBD)
│
├── 📁 scripts/                      # Automation and utility scripts
│   ├── test-runner.sh               # Master test runner
│   └── automation/                  # Build and deployment scripts
│       └── build.sh                 # Core build script
│
├── 📁 tests/                        # All test files
│   ├── test-utils.sh                # Common test utilities
│   ├── fastlane/                    # Fastlane-specific tests
│   │   ├── test_fastlane_config.sh  # Configuration tests
│   │   ├── test_build_lanes.sh      # Build lane tests
│   │   ├── test_dev_workflow.sh     # Development workflow tests
│   │   ├── test_github_integration.sh # GitHub integration tests
│   │   ├── test_release_automation.sh # Release automation tests
│   │   └── test_advanced_automation.sh # Advanced features tests
│   └── integration/                 # Integration tests
│       └── test_integration_complete.sh # Complete integration suite
│
├── 📁 fastlane/                     # Fastlane configuration
│   ├── Fastfile                     # Main Fastlane configuration
│   ├── Appfile                      # App identification
│   └── report.xml                   # Test reports
│
├── 📁 screenit/                     # Source code
│   ├── App/                         # Application entry point
│   ├── Core/                        # Core functionality
│   ├── Models/                      # Data models
│   ├── Resources/                   # Assets and resources
│   └── UI/                          # User interface components
│
├── 📁 dist/                         # Build artifacts (auto-generated)
├── 📁 .tmp/                         # Temporary files (git ignored)
├── 📁 .logs/                        # Test and build logs (git ignored)
│
├── 📄 CLAUDE.md                     # Agent-OS integration
├── 📄 Info.plist                    # App configuration
├── 📄 README.md                     # Project overview
└── 📄 PROJECT_STRUCTURE.md          # This file
```

## Key Principles

### 1. Separation of Concerns
- **Source code** in `screenit/`
- **Tests** in `tests/` with clear categorization
- **Documentation** in `docs/` organized by purpose
- **Scripts** in `scripts/` organized by function
- **Configuration** in dedicated directories (`fastlane/`, `.agent-os/`)

### 2. Consistent Organization
- Tests grouped by functionality (fastlane, integration)
- Documentation grouped by purpose (automation, development, deployment)
- Scripts categorized by type (automation, utilities)
- Clear naming conventions throughout

### 3. Agent-OS Integration
- Specifications in `.agent-os/specs/`
- Product documentation in `.agent-os/product/`
- Task tracking and planning integrated
- Cross-references between specs and implementation

### 4. Cleanup and Maintenance
- Temporary files in `.tmp/` (git ignored)
- Build artifacts in `dist/` (managed by automation)
- Logs in `.logs/` (git ignored)
- Proper cleanup procedures in all scripts

## File Organization Rules

### ✅ Do
- Put tests in `tests/[category]/`
- Put documentation in `docs/[purpose]/`
- Put scripts in `scripts/[type]/`
- Use consistent naming conventions
- Include proper cleanup procedures
- Follow Agent-OS standards

### ❌ Don't
- Put test files in project root
- Put documentation files in project root
- Put utility scripts in project root
- Mix different types of files in same directory
- Leave temporary files uncommitted

## Navigation Guide

### For Developers
- **Start here**: `docs/README.md`
- **Build system**: `docs/automation/FASTLANE_USAGE.md`
- **Run tests**: `./scripts/test-runner.sh`
- **Agent-OS specs**: `.agent-os/specs/`

### For Contributors
- **Organization standards**: `docs/AGENT_OS_STANDARDS.md`
- **Project structure**: `PROJECT_STRUCTURE.md` (this file)
- **Test utilities**: `tests/test-utils.sh`
- **Automation scripts**: `scripts/`

### For Operations
- **Build automation**: `fastlane/`
- **Test suite**: `tests/`
- **Documentation**: `docs/`
- **Deployment**: `docs/deployment/` (TBD)

## Maintenance

This structure should be maintained as the project grows:

1. **New features** → Add specs to `.agent-os/specs/`
2. **New tests** → Add to appropriate `tests/[category]/`
3. **New documentation** → Add to appropriate `docs/[purpose]/`
4. **New scripts** → Add to appropriate `scripts/[type]/`
5. **Updates** → Update cross-references and this structure doc

---

**Standards Compliance**: ✅ Agent-OS Standards v1.0.0  
**Last Updated**: 2025-07-25