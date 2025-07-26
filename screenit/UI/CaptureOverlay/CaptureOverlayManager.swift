import Foundation
import AppKit
import OSLog

/// Manages the capture overlay window and coordinates area selection
@MainActor
class CaptureOverlayManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published var isShowingOverlay: Bool = false
    @Published var lastSelectedArea: CGRect = .zero
    
    private var overlayWindow: CaptureOverlayWindow?
    private let logger = Logger(subsystem: "com.screenit.screenit", category: "CaptureOverlay")
    
    // Callbacks
    private var onAreaSelected: ((CGRect) -> Void)?
    private var onSelectionCancelled: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {
        logger.info("CaptureOverlayManager initialized")
    }
    
    deinit {
        // Note: Cannot call async cleanup from deinit
        // Cleanup should be called manually before deinitialization
        logger.info("CaptureOverlayManager deinitialized")
    }
    
    // MARK: - Public Interface
    
    /// Shows the capture overlay for area selection
    func showAreaSelection(
        onAreaSelected: @escaping (CGRect) -> Void,
        onCancelled: @escaping () -> Void
    ) {
        logger.info("Showing area selection overlay")
        
        // Store callbacks
        self.onAreaSelected = onAreaSelected
        self.onSelectionCancelled = onCancelled
        
        // Hide any existing overlay first
        hideOverlay()
        
        // Create new overlay window
        createOverlayWindow()
        
        // Show the overlay
        guard let overlayWindow = overlayWindow else {
            logger.error("Failed to create overlay window")
            onCancelled()
            return
        }
        
        // Setup window callbacks
        overlayWindow.showForCapture(
            onComplete: { [weak self] rect in
                self?.handleAreaSelected(rect)
            },
            onCancel: { [weak self] in
                self?.handleSelectionCancelled()
            }
        )
        
        isShowingOverlay = true
        logger.info("Area selection overlay displayed")
    }
    
    /// Hides the current overlay
    func hideOverlay() {
        guard isShowingOverlay else { return }
        
        logger.info("Hiding capture overlay")
        
        overlayWindow?.hideOverlay()
        overlayWindow = nil
        isShowingOverlay = false
        
        logger.info("Capture overlay hidden")
    }
    
    /// Cancels the current selection
    func cancelSelection() {
        guard isShowingOverlay else { return }
        
        logger.info("Cancelling area selection")
        handleSelectionCancelled()
    }
    
    // MARK: - Private Methods
    
    private func createOverlayWindow() {
        logger.info("Creating capture overlay window")
        
        overlayWindow = CaptureOverlayWindow()
        logger.info("Overlay window created successfully")
    }
    
    private func handleAreaSelected(_ rect: CGRect) {
        logger.info("Area selected: \(rect.width)x\(rect.height) at (\(rect.origin.x), \(rect.origin.y))")
        
        // Validate selection
        guard rect.width > 0 && rect.height > 0 else {
            logger.warning("Invalid selection area - dimensions too small")
            handleSelectionCancelled()
            return
        }
        
        // Store the selected area
        lastSelectedArea = rect
        
        // Hide overlay
        hideOverlay()
        
        // Call the completion handler
        onAreaSelected?(rect)
        
        // Clear callbacks
        clearCallbacks()
        
        logger.info("Area selection completed successfully")
    }
    
    private func handleSelectionCancelled() {
        logger.info("Area selection cancelled")
        
        // Hide overlay
        hideOverlay()
        
        // Call the cancellation handler
        onSelectionCancelled?()
        
        // Clear callbacks
        clearCallbacks()
        
        logger.info("Area selection cancellation handled")
    }
    
    private func clearCallbacks() {
        onAreaSelected = nil
        onSelectionCancelled = nil
    }
    
    private func cleanup() {
        logger.info("Cleaning up CaptureOverlayManager")
        
        hideOverlay()
        clearCallbacks()
        
        logger.info("CaptureOverlayManager cleanup complete")
    }
    
    // MARK: - Status Properties
    
    /// Whether overlay is currently active
    var isActive: Bool {
        return isShowingOverlay
    }
    
    /// Gets the last selected area dimensions as a user-friendly string
    var lastSelectionDescription: String {
        guard !lastSelectedArea.isEmpty else {
            return "No area selected"
        }
        
        return "\(Int(lastSelectedArea.width)) × \(Int(lastSelectedArea.height)) pixels"
    }
    
    /// Whether we have a valid previous selection
    var hasValidSelection: Bool {
        return !lastSelectedArea.isEmpty && lastSelectedArea.width > 0 && lastSelectedArea.height > 0
    }
}