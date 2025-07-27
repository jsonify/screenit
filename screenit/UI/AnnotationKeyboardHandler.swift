import SwiftUI

// MARK: - Keyboard Shortcut Handler for Annotation Tools

struct AnnotationKeyboardHandler: ViewModifier {
  let selectedTool: Binding<AnnotationType>
  let selectedColor: Binding<Color>
  let onToolChange: (AnnotationType) -> Void
  let onColorChange: (Color) -> Void
  
  func body(content: Content) -> some View {
    content
      .onKeyPress(.init("a"), action: {
        changeToTool(.arrow)
        return .handled
      })
      .onKeyPress(.init("t"), action: {
        changeToTool(.text)
        return .handled
      })
      .onKeyPress(.init("r"), action: {
        changeToTool(.rectangle)
        return .handled
      })
      .onKeyPress(.init("h"), action: {
        changeToTool(.highlight)
        return .handled
      })
      .onKeyPress(.init("b"), action: {
        changeToTool(.blur)
        return .handled
      })
      // Color shortcuts (optional)
      .onKeyPress(.init("1"), action: {
        changeToColor(.red)
        return .handled
      })
      .onKeyPress(.init("2"), action: {
        changeToColor(.blue)
        return .handled
      })
      .onKeyPress(.init("3"), action: {
        changeToColor(.green)
        return .handled
      })
      .onKeyPress(.init("4"), action: {
        changeToColor(.yellow)
        return .handled
      })
      .onKeyPress(.init("5"), action: {
        changeToColor(.orange)
        return .handled
      })
      .onKeyPress(.init("6"), action: {
        changeToColor(.purple)
        return .handled
      })
  }
  
  private func changeToTool(_ tool: AnnotationType) {
    selectedTool.wrappedValue = tool
    onToolChange(tool)
  }
  
  private func changeToColor(_ color: Color) {
    selectedColor.wrappedValue = color
    onColorChange(color)
  }
}

// MARK: - View Extension for Easy Access

extension View {
  func annotationKeyboardShortcuts(
    selectedTool: Binding<AnnotationType>,
    selectedColor: Binding<Color>,
    onToolChange: @escaping (AnnotationType) -> Void,
    onColorChange: @escaping (Color) -> Void
  ) -> some View {
    self.modifier(
      AnnotationKeyboardHandler(
        selectedTool: selectedTool,
        selectedColor: selectedColor,
        onToolChange: onToolChange,
        onColorChange: onColorChange
      )
    )
  }
}

// MARK: - Annotation Toolbar with Keyboard Support

struct AnnotationToolbarWithKeyboard: View {
  @Binding var selectedTool: AnnotationType
  @Binding var selectedColor: Color
  
  let onToolChange: (AnnotationType) -> Void
  let onColorChange: (Color) -> Void
  
  var body: some View {
    AnnotationToolbar(
      selectedTool: $selectedTool,
      selectedColor: $selectedColor,
      onToolChange: onToolChange,
      onColorChange: onColorChange
    )
    .annotationKeyboardShortcuts(
      selectedTool: $selectedTool,
      selectedColor: $selectedColor,
      onToolChange: onToolChange,
      onColorChange: onColorChange
    )
    .focusable()
  }
}

#Preview {
  AnnotationToolbarWithKeyboard(
    selectedTool: .constant(.arrow),
    selectedColor: .constant(.red),
    onToolChange: { tool in
      print("Tool changed to: \(tool)")
    },
    onColorChange: { color in
      print("Color changed to: \(color)")
    }
  )
  .frame(width: 400)
  .padding()
}