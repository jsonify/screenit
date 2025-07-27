import SwiftUI

struct AnnotationToolbar: View {
  @Binding var selectedTool: AnnotationType
  @Binding var selectedColor: Color
  
  let onToolChange: (AnnotationType) -> Void
  let onColorChange: (Color) -> Void
  
  @State private var showColorPicker = false
  
  static let predefinedColors: [Color] = [
    .red, .blue, .green, .yellow, .orange, .purple
  ]
  
  var body: some View {
    HStack(spacing: 12) {
      // Tool Selection Section
      HStack(spacing: 8) {
        ForEach(AnnotationType.allCases, id: \.self) { tool in
          ToolButton(
            tool: tool,
            isSelected: selectedTool == tool,
            action: {
              selectedTool = tool
              onToolChange(tool)
            }
          )
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(.ultraThinMaterial)
      .cornerRadius(8)
      
      // Color Selection Section
      HStack(spacing: 6) {
        // Predefined Colors
        ForEach(Self.predefinedColors, id: \.self) { color in
          ColorButton(
            color: color,
            isSelected: selectedColor == color,
            action: {
              selectedColor = color
              onColorChange(color)
            }
          )
        }
        
        // Custom Color Picker
        Button(action: {
          showColorPicker.toggle()
        }) {
          ZStack {
            Circle()
              .fill(
                LinearGradient(
                  colors: [.red, .orange, .yellow, .green, .blue, .purple],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: 24, height: 24)
            
            Image(systemName: "plus")
              .font(.system(size: 10, weight: .bold))
              .foregroundColor(.white)
          }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showColorPicker) {
          ColorPicker("Select Color", selection: $selectedColor)
            .onChange(of: selectedColor) { _, newColor in
              onColorChange(newColor)
            }
            .padding()
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(.ultraThinMaterial)
      .cornerRadius(8)
    }
    .padding(12)
    .background(.regularMaterial)
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
  }
}

struct ToolButton: View {
  let tool: AnnotationType
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      VStack(spacing: 2) {
        Image(systemName: tool.icon)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(isSelected ? .white : .primary)
        
        Text(tool.keyboardShortcut)
          .font(.system(size: 9, weight: .medium))
          .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
      }
      .frame(width: 40, height: 36)
      .background(isSelected ? Color.accentColor : .clear)
      .cornerRadius(6)
    }
    .buttonStyle(.plain)
    .help("\(tool.name) (\(tool.keyboardShortcut))")
  }
}

struct ColorButton: View {
  let color: Color
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Circle()
        .fill(color)
        .frame(width: 24, height: 24)
        .overlay(
          Circle()
            .stroke(.white, lineWidth: isSelected ? 3 : 0)
        )
        .overlay(
          Circle()
            .stroke(.primary.opacity(0.2), lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
  }
}

// Extension to support toolbar functionality
extension AnnotationType {
  var icon: String {
    switch self {
    case .arrow: return "arrow.up.right"
    case .text: return "textformat"
    case .rectangle: return "rectangle"
    case .highlight: return "highlighter"
    case .blur: return "eye.slash"
    }
  }
  
  var name: String {
    switch self {
    case .arrow: return "Arrow"
    case .text: return "Text"
    case .rectangle: return "Rectangle"
    case .highlight: return "Highlight"
    case .blur: return "Blur"
    }
  }
  
  var keyboardShortcut: String {
    switch self {
    case .arrow: return "A"
    case .text: return "T"
    case .rectangle: return "R"
    case .highlight: return "H"
    case .blur: return "B"
    }
  }
}

#Preview {
  AnnotationToolbar(
    selectedTool: .constant(.arrow),
    selectedColor: .constant(.red),
    onToolChange: { _ in },
    onColorChange: { _ in }
  )
  .frame(width: 400)
  .padding()
}