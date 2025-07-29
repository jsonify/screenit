import Foundation
import SwiftUI
import CoreGraphics
import UniformTypeIdentifiers

// MARK: - Annotation-Enabled Capture Manager

@MainActor
class AnnotationCaptureManager: ObservableObject {
  
  // MARK: - Dependencies
  
  let captureEngine: CaptureEngine
  let annotationEngine: AnnotationEngine
  
  // MARK: - Published Properties
  
  @Published var capturedImage: CGImage?
  @Published var imageSize: CGSize = .zero
  @Published var isInAnnotationMode: Bool = false
  @Published var exportProgress: ExportProgress = .idle
  
  // MARK: - Initialization
  
  init(captureEngine: CaptureEngine? = nil, annotationEngine: AnnotationEngine? = nil) {
    if let captureEngine = captureEngine {
      self.captureEngine = captureEngine
    } else {
      self.captureEngine = CaptureEngine.shared
    }
    self.annotationEngine = annotationEngine ?? AnnotationEngine()
  }
  
  // MARK: - Capture and Annotate Workflow
  
  func captureFullScreenAndStartAnnotation() async -> Bool {
    guard let image = await captureEngine.captureFullScreen() else {
      return false
    }
    
    return await startAnnotationSession(with: image)
  }
  
  func captureAreaAndStartAnnotation(_ rect: CGRect) async -> Bool {
    guard let image = await captureEngine.captureArea(rect) else {
      return false
    }
    
    return await startAnnotationSession(with: image)
  }
  
  func startAnnotationSession(with image: CGImage) async -> Bool {
    capturedImage = image
    imageSize = CGSize(width: image.width, height: image.height)
    
    annotationEngine.startAnnotationSession(for: imageSize)
    isInAnnotationMode = true
    
    return true
  }
  
  // MARK: - Annotation Session Management
  
  func finishAnnotation() -> AnnotatedCaptureResult? {
    guard let image = capturedImage else { return nil }
    
    let annotations = annotationEngine.endAnnotationSession()
    isInAnnotationMode = false
    
    return AnnotatedCaptureResult(
      originalImage: image,
      annotations: annotations,
      imageSize: imageSize
    )
  }
  
  func cancelAnnotation() {
    annotationEngine.cancelAnnotationSession()
    isInAnnotationMode = false
    capturedImage = nil
    imageSize = .zero
  }
  
  // MARK: - Export Functionality
  
  func exportToClipboard() async -> Bool {
    guard let result = finishAnnotation() else { return false }
    
    exportProgress = .inProgress(0.0)
    
    do {
      let exportedImage = try await renderAnnotatedImage(result)
      
      exportProgress = .inProgress(0.8)
      
      let success = await copyToClipboard(exportedImage)
      
      exportProgress = success ? .completed : .failed("Failed to copy to clipboard")
      
      return success
    } catch {
      exportProgress = .failed(error.localizedDescription)
      return false
    }
  }
  
  func exportToFile(url: URL) async -> Bool {
    guard let result = finishAnnotation() else { return false }
    
    exportProgress = .inProgress(0.0)
    
    do {
      let exportedImage = try await renderAnnotatedImage(result)
      
      exportProgress = .inProgress(0.8)
      
      let success = await saveToFile(exportedImage, url: url)
      
      exportProgress = success ? .completed : .failed("Failed to save file")
      
      return success
    } catch {
      exportProgress = .failed(error.localizedDescription)
      return false
    }
  }
  
  // MARK: - Private Rendering Methods
  
  private func renderAnnotatedImage(_ result: AnnotatedCaptureResult) async throws -> CGImage {
    return try await withCheckedThrowingContinuation { continuation in
      let renderer = ImageRenderer(content: 
        AnnotatedImageView(
          image: result.originalImage,
          annotations: result.annotations,
          imageSize: result.imageSize
        )
      )
      
      renderer.scale = 2.0 // Retina quality
      
      DispatchQueue.main.async {
        if let image = renderer.cgImage {
          continuation.resume(returning: image)
        } else {
          continuation.resume(throwing: ExportError.renderingFailed)
        }
      }
    }
  }
  
  private func copyToClipboard(_ image: CGImage) async -> Bool {
    return await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let imageData = NSImage(cgImage: image, size: .zero).tiffRepresentation
        let success = pasteboard.setData(imageData, forType: .tiff)
        
        continuation.resume(returning: success)
      }
    }
  }
  
  private func saveToFile(_ image: CGImage, url: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
          continuation.resume(returning: false)
          return
        }
        
        CGImageDestinationAddImage(destination, image, nil)
        let success = CGImageDestinationFinalize(destination)
        
        continuation.resume(returning: success)
      }
    }
  }
}

// MARK: - Supporting Models

struct AnnotatedCaptureResult {
  let originalImage: CGImage
  let annotations: [Annotation]
  let imageSize: CGSize
}

enum ExportProgress: Equatable {
  case idle
  case inProgress(Double)
  case completed
  case failed(String)
}

enum ExportError: Error, LocalizedError {
  case renderingFailed
  case noImageAvailable
  case fileWriteFailed
  
  var errorDescription: String? {
    switch self {
    case .renderingFailed:
      return "Failed to render annotated image"
    case .noImageAvailable:
      return "No captured image available"
    case .fileWriteFailed:
      return "Failed to write image to file"
    }
  }
}

// MARK: - Annotated Image View for Rendering

struct AnnotatedImageView: View {
  let image: CGImage
  let annotations: [Annotation]
  let imageSize: CGSize
  
  var body: some View {
    ZStack {
      Image(decorative: image, scale: 1.0)
        .resizable()
        .aspectRatio(contentMode: .fit)
      
      AnnotationCanvas(
        annotations: annotations,
        engine: AnnotationEngine(), // Temporary engine for rendering only
        imageSize: imageSize
      )
    }
    .frame(width: imageSize.width, height: imageSize.height)
  }
}

// MARK: - Extension for CGImage Conversion

extension CGImage {
  var nsImage: NSImage {
    NSImage(cgImage: self, size: .zero)
  }
}