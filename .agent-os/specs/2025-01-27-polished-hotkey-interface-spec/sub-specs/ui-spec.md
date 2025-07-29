# UI Specification

This is the UI specification for the spec detailed in @.agent-os/specs/2025-01-27-polished-hotkey-interface-spec/spec.md

> Created: 2025-01-27
> Version: 1.0.0

## Design System Integration

### Visual Design Language

- **macOS Design Principles**: Follow Human Interface Guidelines for macOS 15+
- **System Integration**: Match native macOS preferences and settings visual patterns
- **Typography**: Use SF Pro system font with appropriate weights and sizes
- **Color Palette**: Utilize system colors for automatic dark/light mode support
- **Spacing**: Apply consistent 8pt grid system for layout alignment

### Component Hierarchy

```
PreferencesView → CapturePreferencesView → 
EnhancedHotkeySection → HotkeyCustomizationModal
```

## Main Interface Components

### 1. Enhanced Hotkey Display Section

**Location**: CapturePreferencesView, replacing current HotkeyCustomizationView

**Visual Specifications**:
- **Layout**: HStack with label and interactive hotkey button
- **Label**: "Capture hotkey:" using `.fontWeight(.medium)` system font
- **Hotkey Button**: 
  - Rounded rectangle background with subtle border
  - Monospace font for hotkey display (SF Mono, 14pt)
  - Minimum width: 120pt, height: 32pt
  - Background: `Color.gray.opacity(0.1)` with 1pt border
  - Hover state: Subtle background highlight
  - Focus ring: System blue focus indicator

**Status Integration**:
- **Success State**: Green checkmark icon with hotkey text
- **Warning State**: Orange warning triangle with validation message
- **Error State**: Red X icon with error text
- **Recording State**: Blue circle with "Recording..." animated text

**Example Layout**:
```
[Capture hotkey:]                    [⌘⇧4] [Customize...]
                                     ✓ Valid hotkey
```

### 2. Hotkey Customization Modal

**Dimensions**: 520pt × 440pt (optimized for content)
**Window Style**: Sheet presentation with background blur
**Title**: "Customize Capture Hotkey"

#### Modal Header
- **Title**: Large, semibold system font (17pt)
- **Close Button**: Standard sheet close button (top-trailing)
- **Divider**: Hairline separator below header

#### Method Selection Picker
- **Style**: Segmented control with 3 options
- **Options**: "Record Keys", "Type Shortcut", "Choose Preset"
- **Styling**: System segmented picker with full width

#### Content Area (Adaptive based on selected method)

##### Record Keys Method
```
┌─────────────────────────────────────────────────┐
│                                                 │
│         Press the keys you want to use         │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │                                           │  │
│  │           [Recording Area]                │  │
│  │                                           │  │
│  │     State: Ready/Recording/Captured       │  │
│  │                                           │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│            [Start Recording]                    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Recording Area Specifications**:
- **Dimensions**: 400pt × 100pt
- **Border**: 2pt rounded rectangle
- **States**:
  - **Ready**: Gray border, "Click to start recording" text
  - **Recording**: Blue border with pulse animation, "Press any key combination"
  - **Captured**: Green border, display captured hotkey in large monospace font

**Visual Feedback**:
- **Pulse Animation**: Subtle border glow during recording (2s duration, infinite)
- **Key Capture**: Immediate visual feedback when keys are pressed
- **Success Animation**: Brief green flash when valid combination captured

##### Type Shortcut Method
```
┌─────────────────────────────────────────────────┐
│                                                 │
│      Enter your hotkey combination below        │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │ cmd+shift+4                               │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  ✓ Valid hotkey combination                     │
│                                                 │
│  Format examples:                               │
│  • cmd+shift+4                                 │
│  • ctrl+shift+s                                │
│  • cmd+f6                                      │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Text Field Specifications**:
- **Style**: Rounded border text field with inset shadow
- **Font**: SF Mono, 16pt (monospace for consistency)
- **Placeholder**: "e.g., cmd+shift+4"
- **Real-time Validation**: Live validation with immediate feedback
- **Autocomplete**: Suggest corrections for common typos

##### Choose Preset Method
```
┌─────────────────────────────────────────────────┐
│                                                 │
│       Select from recommended combinations       │
│                                                 │
│  ┌─────────────┐  ┌─────────────┐              │
│  │  ⌘⇧3        │  │  ⌘⇧4  ✓    │              │
│  └─────────────┘  └─────────────┘              │
│  ┌─────────────┐  ┌─────────────┐              │
│  │  ⌘⇧5        │  │  ⌘⇧S        │              │
│  └─────────────┘  └─────────────┘              │
│  ┌─────────────┐  ┌─────────────┐              │
│  │  ⌃⇧4        │  │  ⌘F6        │              │
│  └─────────────┘  └─────────────┘              │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Preset Grid Specifications**:
- **Layout**: 2-column grid with equal spacing
- **Cell Size**: 120pt × 40pt per preset button
- **Selection**: Blue background for selected preset
- **Typography**: Large, clear hotkey symbols (SF Symbols + text)

#### Validation Feedback Area

**Height**: 60pt (expandable based on content)
**Background**: Subtle background tint based on validation state

**Success State**:
- **Icon**: Green checkmark (SF Symbol: checkmark.circle.fill)
- **Text**: "Valid hotkey combination"
- **Color**: System green

**Warning State**:
- **Icon**: Orange warning triangle (SF Symbol: exclamationmark.triangle.fill)  
- **Text**: Specific warning message with suggestions
- **Color**: System orange

**Error State**:
- **Icon**: Red X (SF Symbol: xmark.circle.fill)
- **Text**: Clear error description with resolution steps
- **Color**: System red

#### Bottom Action Bar

**Layout**: HStack with leading and trailing button groups
**Height**: 52pt with proper padding

```
[Reset to Default]                    [Cancel] [Apply]
```

**Button Specifications**:
- **Reset to Default**: Secondary style, orange text color
- **Cancel**: Standard cancel button
- **Apply**: Primary blue button, disabled when invalid

## Animation and Micro-interactions

### Recording State Transitions
- **Start Recording**: 0.3s ease-in animation to blue state
- **Key Capture**: Immediate highlight flash (0.1s)
- **Success Capture**: 0.5s green flash with scale animation
- **Stop Recording**: 0.3s ease-out return to ready state

### Modal Presentation
- **Entry**: Standard sheet slide-up animation
- **Method Switch**: 0.2s cross-fade between content areas
- **Validation Updates**: 0.15s opacity and color transitions

### Button Interactions
- **Hover States**: Subtle background color shifts (0.1s)
- **Press States**: Brief scale animation (0.05s)
- **Focus States**: System focus ring with proper visibility

## Accessibility Specifications

### VoiceOver Support
- **Hotkey Display**: "Current capture hotkey: Command Shift 4, valid"
- **Recording Area**: "Hotkey recording area, ready to record. Press to start"
- **Validation Messages**: Automatic announcement of validation state changes
- **Modal Navigation**: Proper modal presentation announcement

### Keyboard Navigation
- **Tab Order**: Logical navigation through all interactive elements
- **Escape Key**: Close modal from any focused element
- **Enter Key**: Activate primary action (Apply) when valid
- **Space Key**: Start/stop recording when recording area is focused

### Color and Contrast
- **Minimum Contrast**: WCAG AA compliance (4.5:1 ratio)
- **High Contrast Mode**: Maintain functionality with system high contrast
- **Color Independence**: No information conveyed through color alone

## Responsive Behavior

### Window Resizing
- **Fixed Modal Size**: Modal maintains consistent dimensions
- **Content Scaling**: Internal elements scale appropriately
- **Text Wrapping**: Validation messages wrap gracefully

### Dark Mode Support
- **Automatic Adaptation**: All colors use system semantic colors
- **Focus Indicators**: Maintain visibility in both light and dark modes
- **Border Visibility**: Ensure borders remain visible in all appearance modes

## Error States and Edge Cases

### Permission Errors
```
┌─────────────────────────────────────────────────┐
│  ⚠️ Accessibility Permission Required            │  
│                                                 │
│  screenit needs accessibility permission to     │
│  record global hotkeys.                         │
│                                                 │
│            [Open System Settings]               │
└─────────────────────────────────────────────────┘
```

### Conflict Detection
- **System Conflict**: Warning indicator with conflict description
- **Application Conflict**: Information notice with suggested alternatives
- **Validation Override**: Allow advanced users to proceed with warnings

### Network/System Errors
- **Graceful Fallback**: Disable recording method, show text input
- **Error Recovery**: Automatic retry mechanisms with user feedback
- **Logging Integration**: Detailed error logging for troubleshooting