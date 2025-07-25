# screenit Documentation

Comprehensive documentation for the screenit macOS application following Agent-OS organization standards.

## Documentation Structure

### 📁 automation/
Build automation, CI/CD, and deployment documentation.

- **[FASTLANE_USAGE.md](automation/FASTLANE_USAGE.md)** - Complete Fastlane build automation guide
  - Build lanes, development workflows, GitHub integration
  - Release automation, version management
  - Troubleshooting and examples

### 📁 development/
Development guides, coding standards, and API documentation.

*Documentation to be added as development progresses.*

### 📁 deployment/
Deployment procedures and environment setup.

*Documentation to be added as deployment procedures are established.*

## Quick Links

### Getting Started
- [Agent-OS Standards](AGENT_OS_STANDARDS.md) - Project organization and standards
- [Fastlane Usage Guide](automation/FASTLANE_USAGE.md) - Build automation

### Testing
- Test structure defined in [Agent-OS Standards](AGENT_OS_STANDARDS.md#test-organization-principles)
- Run tests with `./scripts/test-runner.sh`

### Build System
- [Fastlane Configuration](automation/FASTLANE_USAGE.md#configuration)
- [Available Build Lanes](automation/FASTLANE_USAGE.md#available-lanes)

## Contributing

When adding new documentation:

1. **Follow the directory structure** defined in [Agent-OS Standards](AGENT_OS_STANDARDS.md)
2. **Use consistent naming** conventions (UPPER_CASE.md for main docs)
3. **Include proper sections** (Overview, Prerequisites, Usage, Examples)
4. **Update this index** when adding new documentation
5. **Cross-reference related docs** using relative paths

## Standards Compliance

This documentation structure follows Agent-OS principles:

- ✅ Organized by purpose (automation, development, deployment)
- ✅ Consistent naming conventions
- ✅ Proper cross-referencing
- ✅ Clear directory structure
- ✅ Comprehensive coverage of project aspects

---

**Last Updated**: 2025-07-25  
**Standards Version**: 1.0.0