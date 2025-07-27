import SwiftUI
import AppKit

/// A transparent window that overlays the entire screen for area selection
class CaptureOverlayWindow: NSWindow {
    
    private let overlayView: CaptureOverlayView
    private var magnifierWindow: MagnifierWindow?
    private var onCaptureComplete: ((CGRect) -> Void)?
    private var onCancelCapture: (() -> Void)?
    
    init() {
        // Create the overlay view
        self.overlayView = CaptureOverlayView()
        
        // Initialize window with screen bounds
        let screenFrame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
        
        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupOverlayView()
    }
    
    private func setupWindow() {
        // Window configuration for overlay
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)))
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.isMovableByWindowBackground = false
        self.canHide = false
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Ensure window covers all screens
        if let mainScreen = NSScreen.main {
            self.setFrame(mainScreen.frame, display: true)
        }
        
        print("CaptureOverlayWindow configured with frame: \(self.frame)")
    }
    
    private func setupOverlayView() {
        // Create hosting controller for SwiftUI view with callbacks
        let overlayViewWithCallbacks = overlayView
            .onSelection { [weak self] rect in
                self?.handleSelectionComplete(rect)
            }
            .onCancel { [weak self] in
                self?.handleCancelSelection()
            }
            .onCursorMove { [weak self] position in
                self?.handleCursorMoved(to: position)
            }
        
        let hostingController = NSHostingController(rootView: overlayViewWithCallbacks)
        hostingController.view.frame = self.contentView?.bounds ?? self.frame
        
        // Configure hosting view
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Set as content view
        self.contentView = hostingController.view
        
        print("CaptureOverlayView configured and added to window")
    }
    
    // MARK: - Public Interface
    
    /// Shows the overlay window for area selection
    func showForCapture(onComplete: @escaping (CGRect) -> Void, onCancel: @escaping () -> Void) {
        self.onCaptureComplete = onComplete
        self.onCancelCapture = onCancel
        
        // Create and setup magnifier window
        setupMagnifierWindow()
        
        // Note: Reset will be handled by the SwiftUI view automatically when it reappears
        
        // Show window
        self.makeKeyAndOrderFront(nil)
        
        // Ensure we're at the front
        NSApp.activate(ignoringOtherApps: true)
        
        print("CaptureOverlayWindow shown for area selection with magnifier")
    }
    
    /// Hides the overlay window
    func hideOverlay() {
        // Hide magnifier window first
        magnifierWindow?.hideMagnifier()
        magnifierWindow = nil
        
        self.orderOut(nil)
        print("CaptureOverlayWindow and magnifier hidden")
    }
    
    // MARK: - Selection Handling
    
    private func handleSelectionComplete(_ rect: CGRect) {
        print("Selection completed with rect: \(rect)")
        
        // Convert rect to screen coordinates if needed
        let screenRect = convertToScreenCoordinates(rect)
        
        // Hide overlay first
        hideOverlay()
        
        // Call completion handler
        onCaptureComplete?(screenRect)
    }
    
    private func handleCancelSelection() {
        print("Selection cancelled")
        
        // Hide overlay
        hideOverlay()
        
        // Call cancel handler
        onCancelCapture?()
    }
    
    private func convertToScreenCoordinates(_ rect: CGRect) -> CGRect {
        // SwiftUI uses different coordinate system than screen capture
        // Convert from window coordinates to screen coordinates
        guard let screen = NSScreen.main else { return rect }
        
        let screenHeight = screen.frame.height
        let convertedY = screenHeight - rect.origin.y - rect.height
        
        return CGRect(
            x: rect.origin.x,
            y: convertedY,
            width: rect.width,
            height: rect.height
        )
    }
    
    // MARK: - Window Events
    
    override func keyDown(with event: NSEvent) {
        // Handle escape key to cancel
        if event.keyCode == 53 { // Escape key
            handleCancelSelection()
        } else {
            super.keyDown(with: event)
        }
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    // MARK: - Magnifier Integration
    
    /// Sets up the magnifier window
    private func setupMagnifierWindow() {
        magnifierWindow = MagnifierWindow()
        print("MagnifierWindow created and configured")
    }
    
    /// Handles cursor movement to update magnifier
    private func handleCursorMoved(to position: CGPoint) {
        // Convert SwiftUI coordinates to screen coordinates
        let screenPosition = convertToScreenCoordinates(CGRect(origin: position, size: CGSize(width: 1, height: 1))).origin
        
        // Update magnifier window
        magnifierWindow?.showMagnifier(at: screenPosition)
    }
}