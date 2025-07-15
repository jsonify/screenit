# Development Tasks

This file tracks the development roadmap for screenit organized by priority.

## High Priority - Core Functionality

<!-- ### 🏗️ Setup Project Architecture
- **Status**: Open
- **Priority**: High
- **Description**: Reorganize codebase according to planned structure with Core/, UI/, Models/, and Resources/ directories
- **Acceptance Criteria**:
  - [ ] Create Core/ directory with CaptureEngine.swift, AnnotationEngine.swift, DataManager.swift
  - [ ] Create UI/ directory with subdirectories for CaptureOverlay/, AnnotationTools/, HistoryView/, MenuBar/
  - [ ] Create Models/ directory for data models
  - [ ] Move existing files to appropriate locations -->

<!-- ### 📊 Implement Core Data Model
- **Status**: Open
- **Priority**: High
- **Description**: Create CaptureItem and Annotation entities with proper relationships for storing screenshot history
- **Acceptance Criteria**:
  - [ ] Create CoreData.xcdatamodeld file
  - [ ] Define CaptureItem entity (id, timestamp, imageData, thumbnailData, width, height, fileSize)
  - [ ] Define Annotation entity (id, type, position, properties, captureItem relationship)
  - [ ] Implement DataManager class for Core Data operations -->

<!-- ### 🔐 Screen Capture Permissions
- **Status**: Open
- **Priority**: High
- **Description**: Implement ScreenCaptureKit authorization flow and handle permission states
- **Acceptance Criteria**:
  - [ ] Request screen recording permission
  - [ ] Handle permission granted/denied states
  - [ ] Provide user guidance for enabling permissions
  - [ ] Graceful fallback when permissions unavailable -->

### 📐 Basic Area Selection UI
- **Status**: Open
- **Priority**: High
- **Description**: Create crosshair cursor, magnifier window with RGB values, and click-drag rectangle selection
- **Acceptance Criteria**:
  - [ ] Full-screen overlay window
  - [ ] Crosshair cursor with live coordinates
  - [ ] Magnifier window showing pixel zoom and RGB values
  - [ ] Click-and-drag rectangle selection
  - [ ] Escape to cancel, Enter/Space to confirm
  - [ ] Visual feedback (dimmed background, selection highlight)

### 📸 Screen Capture Engine
- **Status**: Open
- **Priority**: High
- **Description**: Implement core screenshot functionality using ScreenCaptureKit for selected areas
- **Acceptance Criteria**:
  - [ ] Capture specific screen regions using ScreenCaptureKit
  - [ ] Handle multiple display configurations
  - [ ] Save captured images to Core Data
  - [ ] Generate thumbnail images for history
  - [ ] Handle capture errors gracefully

## Medium Priority - Key Features

### 🔧 Menu Bar Application
- **Status**: Open
- **Priority**: Medium
- **Description**: Convert to menu bar app with NSStatusItem, dropdown menu, and app lifecycle management
- **Acceptance Criteria**:
  - [ ] Remove main window, implement menu bar only mode
  - [ ] Create NSStatusItem with app icon
  - [ ] Implement dropdown menu (Capture Area, Show History, Preferences, Quit)
  - [ ] Handle app activation/deactivation properly

### ⌨️ Global Keyboard Shortcuts
- **Status**: Open
- **Priority**: Medium
- **Description**: Implement Carbon/Cocoa event monitoring for system-wide hotkeys (Cmd+Shift+4)
- **Acceptance Criteria**:
  - [ ] Register global hotkey for screen capture (Cmd+Shift+4)
  - [ ] Register global hotkey for history (Cmd+Shift+H)
  - [ ] Handle hotkey conflicts gracefully
  - [ ] Allow hotkey customization in preferences

### ✏️ Annotation Tools
- **Status**: Open
- **Priority**: Medium
- **Description**: Implement arrow, text, rectangle, and highlight tools with SwiftUI Canvas
- **Acceptance Criteria**:
  - [ ] Arrow tool with color/thickness options
  - [ ] Text tool with font size/color selection
  - [ ] Rectangle outline tool
  - [ ] Highlight/blur tool
  - [ ] Tool selection toolbar
  - [ ] Undo/redo functionality

### 📚 Capture History Interface
- **Status**: Open
- **Priority**: Medium
- **Description**: Create thumbnail grid view with copy, save, delete actions for recent captures
- **Acceptance Criteria**:
  - [ ] Grid view of recent captures (10 max)
  - [ ] Thumbnail images with metadata overlay
  - [ ] Copy to clipboard action
  - [ ] Save to Desktop quick action
  - [ ] Save As dialog action
  - [ ] Delete from history action
  - [ ] Double-click to re-edit

### 🛡️ Update App Entitlements
- **Status**: Open
- **Priority**: Medium
- **Description**: Configure necessary entitlements for screen capture, file access, and accessibility
- **Acceptance Criteria**:
  - [ ] Screen recording entitlement
  - [ ] File system access entitlements
  - [ ] Accessibility API entitlements (for global hotkeys)
  - [ ] Network entitlements if needed
  - [ ] Sandbox exceptions as required

## Low Priority - Polish

### ⚙️ Preferences Window
- **Status**: Open
- **Priority**: Low
- **Description**: Build settings UI for hotkeys, save location, history retention, and annotation defaults
- **Acceptance Criteria**:
  - [ ] Hotkey customization interface
  - [ ] Default save location picker
  - [ ] History retention count setting
  - [ ] Default annotation tool colors/thickness
  - [ ] Menu bar visibility toggle

### 🧪 Testing Setup
- **Status**: Open
- **Priority**: Low
- **Description**: Add unit tests for capture engine, data models, and UI component testing framework
- **Acceptance Criteria**:
  - [ ] Unit tests for Core Data models
  - [ ] Unit tests for capture engine
  - [ ] UI tests for main workflows
  - [ ] Test data fixtures
  - [ ] Continuous integration setup

---

**Status Legend**: Open | In Progress | Review | Done  
**Priority**: High | Medium | Low

*Last Updated: 2025-07-15*
