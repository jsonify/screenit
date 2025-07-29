import Foundation
import SwiftUI
import Cocoa
import Combine

// MARK: - Post-Capture Preview Manager

class PostCapturePreviewManager: ObservableObject {
    
    // MARK: - Static Configuration
    
    static let previewSize = NSSize(width: 300, height: 220)
    static let edgeMargin: CGFloat = 20
    
    // MARK: - Published Properties
    
    @Published var isShowing: Bool = false
    @Published var isTimerActive: Bool = false
    @Published var remainingTime: TimeInterval = 0
    
    // MARK: - Properties
    
    private(set) var currentImage: CGImage?
    private(set) var timeoutDuration: TimeInterval
    
    // MARK: - Private Properties
    
    private var previewWindow: NSPanel?
    private var timer: AnyCancellable?
    private var timerStartTime: Date?
    private var onAnnotateCallback: (() -> Void)?
    private var onDismissCallback: (() -> Void)?
    
    // MARK: - Timer Update Callback (for testing)
    
    var onTimerUpdate: ((TimeInterval) -> Void)?
    
    // MARK: - Initialization
    
    init(timeoutDuration: TimeInterval = 6.0) {
        self.timeoutDuration = timeoutDuration
        self.remainingTime = timeoutDuration
    }
    
    deinit {
        // Synchronous cleanup for deinit - cannot use async
        timer?.cancel()
        timer = nil
        timerStartTime = nil
        
        if let window = previewWindow {
            DispatchQueue.main.async {
                window.orderOut(nil)
                window.contentViewController = nil
            }
        }
        previewWindow = nil
    }
    
    // MARK: - Public Interface
    
    /// Shows the preview with the captured image and action callbacks
    @MainActor
    func showPreview(
        image: CGImage,
        onAnnotate: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        print("📱 [DEBUG] PostCapturePreviewManager.showPreview() called")
        
        // Clean up any existing preview
        if isShowing {
            hidePreview()
        }
        
        // Store image and callbacks
        currentImage = image
        onAnnotateCallback = onAnnotate
        onDismissCallback = onDismiss
        
        // Create and show preview window
        createPreviewWindow()
        positionPreviewWindow()
        
        // Update state
        isShowing = true
        
        // Start auto-dismiss timer
        startTimer()
        
        print("✅ [DEBUG] Preview window shown successfully")
    }
    
    /// Hides the preview window and cleans up resources
    @MainActor
    func hidePreview() {
        print("📱 [DEBUG] PostCapturePreviewManager.hidePreview() called")
        
        guard isShowing else { return }
        
        // Stop timer
        stopTimer()
        
        // Hide and clean up window
        if let window = previewWindow {
            window.orderOut(nil)
            window.contentViewController = nil
        }
        previewWindow = nil
        
        // Clear state
        isShowing = false
        currentImage = nil
        onAnnotateCallback = nil
        onDismissCallback = nil
        remainingTime = timeoutDuration
        
        print("✅ [DEBUG] Preview window hidden and cleaned up")
    }
    
    /// Cleans up all resources
    @MainActor
    func cleanup() {
        print("📱 [DEBUG] PostCapturePreviewManager.cleanup() called")
        hidePreview()
    }
    
    // MARK: - Action Handlers
    
    /// Handles the annotate button action
    @MainActor
    func handleAnnotateAction() {
        print("📱 [DEBUG] Annotate action triggered")
        
        guard isShowing else { return }
        
        // Stop timer and hide preview
        stopTimer()
        
        // Call callback before hiding to ensure proper state
        let callback = onAnnotateCallback
        hidePreview()
        callback?()
    }
    
    /// Handles the dismiss button action
    @MainActor
    func handleDismissAction() {
        print("📱 [DEBUG] Dismiss action triggered")
        
        guard isShowing else { return }
        
        // Stop timer and hide preview
        stopTimer()
        
        // Call callback before hiding to ensure proper state
        let callback = onDismissCallback
        hidePreview()
        callback?()
    }
    
    // MARK: - Timer Management
    
    /// Starts the auto-dismiss timer
    @MainActor
    func startTimer() {
        print("📱 [DEBUG] Starting auto-dismiss timer (\(timeoutDuration)s)")
        
        stopTimer() // Ensure no existing timer
        
        timerStartTime = Date()
        remainingTime = timeoutDuration
        isTimerActive = true
        
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    /// Stops the auto-dismiss timer
    @MainActor
    func stopTimer() {
        timer?.cancel()
        timer = nil
        timerStartTime = nil
        isTimerActive = false
    }
    
    /// Resets the timer to the full timeout duration
    @MainActor
    func resetTimer() {
        guard isShowing else { return }
        
        print("📱 [DEBUG] Resetting timer")
        startTimer()
    }
    
    /// Updates the timer countdown
    @MainActor
    private func updateTimer() {
        guard let startTime = timerStartTime, isTimerActive else {
            stopTimer()
            return
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        remainingTime = max(0, timeoutDuration - elapsed)
        
        // Notify test observers
        onTimerUpdate?(remainingTime)
        
        // Check if time is up
        if remainingTime <= 0 {
            print("📱 [DEBUG] Auto-dismiss timer expired")
            handleTimeoutDismiss()
        }
    }
    
    /// Handles timeout-based dismissal
    @MainActor
    private func handleTimeoutDismiss() {
        guard isShowing else { return }
        
        stopTimer()
        
        // Call dismiss callback
        let callback = onDismissCallback
        hidePreview()
        callback?()
    }
    
    // MARK: - Window Management
    
    /// Creates the preview window
    @MainActor
    private func createPreviewWindow() {
        print("📱 [DEBUG] Creating preview window")
        
        // Create the SwiftUI content view
        let contentView = PostCapturePreviewView(manager: self)
        let hostingController = NSHostingController(rootView: contentView)
        
        // Create NSPanel with appropriate configuration
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.previewSize),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Configure panel properties
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.contentViewController = hostingController
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Make the panel accept key events for keyboard interaction
        panel.acceptsMouseMovedEvents = true
        
        previewWindow = panel
        
        print("✅ [DEBUG] Preview window created")
    }
    
    /// Positions the preview window on screen
    @MainActor
    private func positionPreviewWindow() {
        guard let window = previewWindow else { return }
        
        print("📱 [DEBUG] Positioning preview window")
        
        // Determine target screen (cursor location or main screen)
        let targetScreen = screenContainingCursor() ?? NSScreen.main ?? NSScreen.screens.first!
        
        // Calculate position
        let position = calculatePreviewPosition(for: targetScreen)
        
        // Set window position and show
        window.setFrameOrigin(position)
        window.orderFront(nil)
        
        print("✅ [DEBUG] Preview window positioned at \(position)")
    }
    
    // MARK: - Screen Positioning Logic
    
    /// Calculates the optimal preview position for the given screen
    func calculatePreviewPosition(for screen: NSScreen) -> NSPoint {
        let screenFrame = screen.visibleFrame
        
        // Calculate bottom-right corner position with margins
        let desiredX = screenFrame.maxX - Self.previewSize.width - Self.edgeMargin
        let desiredY = screenFrame.minY + Self.edgeMargin
        
        let desiredPosition = NSPoint(x: desiredX, y: desiredY)
        
        // Apply constraints to ensure the window fits on screen
        return calculateConstrainedPosition(
            desiredPosition: desiredPosition,
            screenFrame: screenFrame
        )
    }
    
    /// Calculates a constrained position that ensures the window fits within screen bounds
    func calculateConstrainedPosition(
        desiredPosition: NSPoint,
        screenFrame: NSRect
    ) -> NSPoint {
        var constrainedX = desiredPosition.x
        var constrainedY = desiredPosition.y
        
        // Ensure window doesn't go off the right edge
        if constrainedX + Self.previewSize.width > screenFrame.maxX {
            constrainedX = screenFrame.maxX - Self.previewSize.width - Self.edgeMargin
        }
        
        // Ensure window doesn't go off the left edge
        if constrainedX < screenFrame.minX {
            constrainedX = screenFrame.minX + Self.edgeMargin
        }
        
        // Ensure window doesn't go off the top edge
        if constrainedY + Self.previewSize.height > screenFrame.maxY {
            constrainedY = screenFrame.maxY - Self.previewSize.height - Self.edgeMargin
        }
        
        // Ensure window doesn't go off the bottom edge
        if constrainedY < screenFrame.minY {
            constrainedY = screenFrame.minY + Self.edgeMargin
        }
        
        return NSPoint(x: constrainedX, y: constrainedY)
    }
    
    /// Finds the screen containing the cursor, if any
    private func screenContainingCursor() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        }
    }
}

// MARK: - Preview View

struct PostCapturePreviewView: View {
    @ObservedObject var manager: PostCapturePreviewManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Image thumbnail
            if let image = manager.currentImage {
                Image(decorative: image, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 150)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Dismiss") {
                    manager.handleDismissAction()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Annotate") {
                    manager.handleAnnotateAction()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
            }
            
            // Timer indicator (if active)
            if manager.isTimerActive {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(manager.remainingTime))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .frame(width: PostCapturePreviewManager.previewSize.width - 20,
               height: PostCapturePreviewManager.previewSize.height - 20)
        .onAppear {
            // Reset timer when view appears (in case of hover interactions)
            if manager.isShowing {
                manager.resetTimer()
            }
        }
    }
}