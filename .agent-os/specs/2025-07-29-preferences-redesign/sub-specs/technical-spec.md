# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-29-preferences-redesign/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Technical Requirements

- SwiftUI-based sidebar navigation with proper selection state management
- Maintain existing PreferencesManager and Core Data integration 
- Implement icon-based navigation matching design mocks exactly
- Responsive layout that works with the current window size constraints (600x500)
- Proper data binding for all new and reorganized preference settings
- Preserve existing functionality while reorganizing UI presentation
- Add support for new preference options shown in mocks (file formats, cursor modes, etc.)

## Approach Options

**Option A:** Complete Rewrite of PreferencesView
- Pros: Clean implementation, easier to match exact design specifications
- Cons: Higher risk of breaking existing functionality, more extensive testing required

**Option B:** Incremental Refactoring with Component Reuse (Selected)
- Pros: Lower risk by preserving existing data bindings, incremental testing possible
- Cons: May require more careful refactoring to achieve exact design match

**Option C:** Hybrid Approach with New Container
- Pros: Can preserve existing views as fallback, flexible migration path
- Cons: Code duplication, complexity in maintaining two preference systems

**Rationale:** Option B selected because it minimizes risk of breaking existing Core Data bindings and preferences functionality while allowing systematic implementation of the new design. The existing PreferencesManager and data model are working well and should be preserved.

## External Dependencies

**No new external dependencies required** - Implementation will use existing SwiftUI, Core Data, and macOS system frameworks already in use by the project.

## UI Architecture

**Main Components:**
1. **PreferencesSidebarView** - Left sidebar with icon navigation
2. **PreferencesContentView** - Right content area container  
3. **Redesigned Preference Panels** - Updated panels matching mock designs
4. **PreferencesToolbarView** - Top toolbar if needed for window controls

**Navigation State Management:**
- Use @State for selected tab tracking
- Implement proper selection highlighting and transitions
- Support keyboard navigation between sidebar items

**Data Binding Strategy:**
- Maintain existing EnvironmentObject pattern with PreferencesManager
- Preserve all current Binding patterns for Core Data integration
- Add new binding properties as needed for new settings

## New Preferences Model Extensions

**Additional Properties Needed:**
- File format selection (PNG/JPEG options)
- Retina scaling preferences  
- Color management settings
- Frame and background options
- Cursor display modes
- Self-timer interval settings
- Screen freeze options
- Crosshair mode configurations
- Multi-display preferences
- Auto-close behaviors
- File naming patterns
- Text recognition settings

**Core Data Migration:**
- Add new optional properties to UserPreferences entity
- Provide sensible defaults for all new settings
- Ensure backward compatibility with existing preference data