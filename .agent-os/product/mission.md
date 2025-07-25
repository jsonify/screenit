# Product Mission

> Last Updated: 2025-01-27
> Version: 1.0.0

## Pitch

screenit is an open source CleanShot X alternative for macOS 15+ that provides pixel-perfect screen capture with professional annotation tools, capture history, and seamless menu bar integration.

## Users

### Primary Customers

- **macOS Power Users**: Professionals who need advanced screenshot capabilities with precision and professional annotation tools
- **Open Source Advocates**: Users who prefer open source alternatives to commercial tools like CleanShot X
- **Developers & Designers**: Technical professionals who need pixel-perfect capture with RGB color sampling and precise measurement tools

### User Personas

**Professional Developer** (25-45 years old)
- **Role:** Software Engineer, Designer, Technical Writer
- **Context:** Daily screenshot needs for documentation, bug reports, design reviews, and tutorials
- **Pain Points:** CleanShot X is expensive, limited customization, vendor lock-in, no source code access
- **Goals:** Pixel-perfect captures, efficient annotation workflow, reliable history management, customizable hotkeys

**Design Professional** (25-40 years old)
- **Role:** UI/UX Designer, Product Manager, Marketing Professional
- **Context:** Creating documentation, design presentations, user guides, and marketing materials
- **Pain Points:** Need professional-quality annotations, color sampling, precise measurements, export flexibility
- **Goals:** Professional annotation tools, color picker functionality, flexible export options, seamless workflow integration

## The Problem

### Expensive Commercial Tools with Limited Control

CleanShot X costs $29+ with subscription model and provides no source code access or customization options. Users are locked into vendor decisions and pricing structures.

**Our Solution:** Provide a free, open source alternative with full customization and community-driven development.

### Limited macOS Native Screenshot Capabilities

Built-in macOS screenshot tools lack professional annotation features, history management, and advanced capture modes like scrolling capture.

**Our Solution:** Professional-grade annotation tools, persistent capture history with Core Data, and advanced capture modes.

### Poor Integration with Developer Workflows

Most screenshot tools don't integrate well with developer needs like pixel-perfect RGB sampling, coordinate display, and precise measurement tools.

**Our Solution:** Developer-focused features including RGB color picker, pixel coordinates, magnifier tool, and precise measurement capabilities.

## Differentiators

### Open Source with Full Customization

Unlike CleanShot X and other commercial tools, we provide complete source code access with MIT license. This results in community-driven feature development and zero vendor lock-in.

### Developer-First Design

Unlike general screenshot tools, we prioritize developer needs with pixel-perfect accuracy, RGB color sampling, coordinate display, and technical annotation tools. This results in superior workflow integration for technical professionals.

### macOS-Native Performance

Unlike cross-platform tools, we use ScreenCaptureKit and SwiftUI for optimal macOS performance and system integration. This results in faster capture speeds and better system resource efficiency.

## Key Features

### Core Features

- **Pixel-Perfect Area Selection:** Crosshair cursor with live coordinates and magnifier window showing RGB values
- **Professional Annotation Tools:** Arrow, text, rectangle, and highlight tools with customizable colors and thickness
- **Persistent Capture History:** Core Data backend storing 10+ recent captures with metadata and thumbnails
- **Global Hotkey System:** Customizable keyboard shortcuts (default Cmd+Shift+4) for instant capture access

### Advanced Features

- **RGB Color Sampling:** Real-time color picker with hex/RGB values during capture selection
- **Menu Bar Integration:** Lightweight menu bar app with quick access to captures and preferences
- **Flexible Export Options:** Copy to clipboard, quick save to Desktop, or Save As with custom locations
- **Annotation Persistence:** Save and re-edit annotations on historical captures

### Future Features

- **Scrolling Capture:** Capture entire web pages and long documents automatically
- **Screen Recording:** Video capture with annotation overlay capabilities