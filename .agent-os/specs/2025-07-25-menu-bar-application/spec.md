# Spec Requirements Document

> Spec: Menu Bar Application
> Created: 2025-07-25
> Status: Planning

## Overview

Implement the foundational SwiftUI menu bar application for screenit that provides seamless macOS system integration through NSStatusItem. This serves as the core interface framework for the screen capture functionality and establishes the MVVM architecture pattern for the entire application.

## User Stories

### Primary Interface Access

As a macOS power user, I want to access screenit functionality through a native menu bar icon, so that I can quickly capture screenshots without disrupting my workflow or cluttering my dock.

The application should appear as a clean, unobtrusive menu bar item that provides instant access to capture functionality and settings. Users should be able to right-click for context menus and left-click for primary actions, following standard macOS menu bar conventions.

### System Integration

As a developer who works with multiple applications, I want screenit to integrate seamlessly with macOS system conventions, so that it feels like a native part of the operating system rather than a third-party addition.

The menu bar app should respect system appearance settings (light/dark mode), provide appropriate visual feedback, and follow macOS Human Interface Guidelines for menu bar applications.

## Spec Scope

1. **NSStatusItem Integration** - Create menu bar status item with custom icon and tooltip
2. **SwiftUI Menu Interface** - Implement dropdown menu with primary actions and settings access
3. **MVVM Architecture Setup** - Establish MenuBarManager as the central coordinator following MVVM pattern
4. **Application Lifecycle Management** - Handle app launch, background running, and clean termination
5. **macOS System Integration** - Support for system appearance changes and proper menu bar behavior

## Out of Scope

- Screen capture functionality (Phase 1 - separate spec)
- Global hotkey registration (Phase 1 - separate spec)
- Preferences window implementation (Phase 5)
- Capture history display (Phase 4)

## Expected Deliverable

1. **Functional Menu Bar App** - Application launches and displays properly in menu bar with icon and tooltip
2. **Basic Menu Interface** - Dropdown menu appears on click with placeholder menu items for future functionality
3. **System Integration** - App respects system appearance, shows/hides appropriately, and terminates cleanly