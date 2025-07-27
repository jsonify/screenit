import SwiftUI

// MARK: - Complete Capture with Annotation Workflow View

struct CaptureWithAnnotationView: View {
  
  // MARK: - State Management
  
  @StateObject private var captureManager = AnnotationCaptureManager()
  @State private var selectedTool: AnnotationType = .arrow
  @State private var selectedColor: Color = .red
  @State private var showExportOptions = false
  @State private var exportURL: URL?
  
  // MARK: - Body
  
  var body: some View {
    VStack(spacing: 0) {
      if captureManager.isInAnnotationMode {
        annotationModeView
      } else {
        captureSelectionView
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.1))
    .sheet(isPresented: $showExportOptions) {
      exportOptionsSheet
    }
  }
  
  // MARK: - Capture Selection View
  
  private var captureSelectionView: some View {
    VStack(spacing: 20) {
      Text("Capture Screen")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      HStack(spacing: 16) {
        Button("Capture Full Screen") {
          Task {
            await captureManager.captureFullScreenAndStartAnnotation()
          }
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.space)
        
        Button("Capture Area") {
          // This would trigger area selection mode
          // For now, capture a predefined area as demo
          let demoRect = CGRect(x: 100, y: 100, width: 800, height: 600)
          Task {
            await captureManager.captureAreaAndStartAnnotation(demoRect)
          }
        }
        .buttonStyle(.bordered)
        .keyboardShortcut("a", modifiers: .command)
      }
      
      if captureManager.captureEngine.isCapturing {
        ProgressView("Capturing...")
          .progressViewStyle(CircularProgressViewStyle())
      }
    }
    .padding()
  }
  
  // MARK: - Annotation Mode View
  
  private var annotationModeView: some View {
    VStack(spacing: 0) {
      // Toolbar at top
      annotationToolbar
        .background(.ultraThinMaterial)
        .padding(.horizontal)
        .padding(.top, 8)
      
      // Main annotation canvas
      if let image = captureManager.capturedImage {
        GeometryReader { geometry in
          ZStack {
            // Background
            Color.black.opacity(0.3)
            
            // Image and annotation canvas
            VStack {
              ZStack {
                Image(decorative: image, scale: 1.0)
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .shadow(radius: 10)
                
                AnnotationCanvas(
                  annotations: captureManager.annotationEngine.annotations,
                  engine: captureManager.annotationEngine,
                  imageSize: captureManager.imageSize
                )
                .aspectRatio(
                  captureManager.imageSize.width / captureManager.imageSize.height,
                  contentMode: .fit
                )
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
          }
        }
      }
      
      // Bottom action bar
      bottomActionBar
        .background(.ultraThinMaterial)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    .annotationKeyboardShortcuts(
      selectedTool: $selectedTool,
      selectedColor: $selectedColor,
      onToolChange: { tool in
        captureManager.annotationEngine.selectTool(for: tool)
      },
      onColorChange: { color in
        captureManager.annotationEngine.toolState.color = color
      }
    )
  }
  
  // MARK: - Annotation Toolbar
  
  private var annotationToolbar: some View {
    HStack {
      // Tool selection and color picker
      AnnotationToolbarWithKeyboard(
        selectedTool: $selectedTool,
        selectedColor: $selectedColor,
        onToolChange: { tool in
          captureManager.annotationEngine.selectTool(for: tool)
        },
        onColorChange: { color in
          captureManager.annotationEngine.toolState.color = color
        }
      )
      
      Spacer()
      
      // Undo/Redo controls
      HStack {
        Button(action: {
          captureManager.annotationEngine.undo()
        }) {
          Image(systemName: "arrow.uturn.backward")
        }
        .disabled(!captureManager.annotationEngine.canUndo)
        .keyboardShortcut("z", modifiers: .command)
        
        Button(action: {
          captureManager.annotationEngine.redo()
        }) {
          Image(systemName: "arrow.uturn.forward")
        }
        .disabled(!captureManager.annotationEngine.canRedo)
        .keyboardShortcut("z", modifiers: [.command, .shift])
      }
      .buttonStyle(.bordered)
    }
    .padding(.vertical, 8)
  }
  
  // MARK: - Bottom Action Bar
  
  private var bottomActionBar: some View {
    HStack {
      // Cancel button
      Button("Cancel") {
        captureManager.cancelAnnotation()
      }
      .buttonStyle(.bordered)
      .keyboardShortcut(.escape)
      
      Spacer()
      
      // Export progress indicator
      exportProgressView
      
      Spacer()
      
      // Export actions
      HStack(spacing: 12) {
        Button("Copy to Clipboard") {
          Task {
            await captureManager.exportToClipboard()
          }
        }
        .buttonStyle(.bordered)
        .keyboardShortcut("c", modifiers: .command)
        
        Button("Save As...") {
          showExportOptions = true
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut("s", modifiers: .command)
      }
    }
    .padding(.vertical, 8)
  }
  
  // MARK: - Export Progress View
  
  private var exportProgressView: some View {
    Group {
      switch captureManager.exportProgress {
      case .idle:
        EmptyView()
      case .inProgress(let progress):
        HStack {
          ProgressView(value: progress)
            .frame(width: 100)
          Text("Exporting...")
            .font(.caption)
        }
      case .completed:
        HStack {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
          Text("Export Complete")
            .font(.caption)
        }
      case .failed(let error):
        HStack {
          Image(systemName: "exclamationmark.circle.fill")
            .foregroundColor(.red)
          Text(error)
            .font(.caption)
        }
      }
    }
  }
  
  // MARK: - Export Options Sheet
  
  private var exportOptionsSheet: some View {
    VStack(spacing: 20) {
      Text("Export Options")
        .font(.headline)
      
      VStack(alignment: .leading, spacing: 12) {
        Button("Save to Desktop") {
          let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
            .appendingPathComponent("Screenshot-\(Date().timeIntervalSince1970).png")
          
          Task {
            await captureManager.exportToFile(url: url)
          }
          showExportOptions = false
        }
        .buttonStyle(.bordered)
        
        Button("Choose Location...") {
          let panel = NSSavePanel()
          panel.allowedContentTypes = [.png, .jpeg]
          panel.nameFieldStringValue = "Screenshot-\(Date().timeIntervalSince1970).png"
          
          if panel.runModal() == .OK, let url = panel.url {
            Task {
              await captureManager.exportToFile(url: url)
            }
          }
          showExportOptions = false
        }
        .buttonStyle(.borderedProminent)
      }
      
      Button("Cancel") {
        showExportOptions = false
      }
      .buttonStyle(.bordered)
    }
    .padding()
    .frame(width: 300)
  }
}

// MARK: - Preview

#Preview {
  CaptureWithAnnotationView()
    .frame(width: 1200, height: 800)
}