import Foundation
import OSLog

/// Centralized error handling for screen capture operations
@MainActor
class CaptureErrorHandler: ObservableObject {
    
    // MARK: - Published Properties
    @Published var errorCounts: [CaptureError: Int] = [:]
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.screenit.screenit", category: "CaptureErrorHandler")
    
    // MARK: - Error Message Generation
    
    /// Generates a user-friendly error message for the given capture error
    /// - Parameter error: The capture error to generate a message for
    /// - Returns: A user-friendly error message with actionable guidance
    func userFriendlyMessage(for error: CaptureError) -> String {
        switch error {
        case .notAuthorized:
            return """
            Screen Recording permission is required to capture screenshots.
            
            To enable:
            1. Open System Preferences > Privacy & Security
            2. Click "Screen Recording" in the sidebar
            3. Enable screenit in the list
            4. Restart screenit
            """
            
        case .authorizationFailed(let underlyingError):
            return """
            Failed to get Screen Recording permission.
            
            Error: \(underlyingError.localizedDescription)
            
            Please try:
            1. Checking System Preferences > Privacy & Security > Screen Recording
            2. Removing and re-adding screenit to the list
            3. Restarting your Mac if the issue persists
            """
            
        case .contentDiscoveryFailed(let underlyingError):
            return """
            Unable to find screens and windows to capture.
            
            Error: \(underlyingError.localizedDescription)
            
            This might happen if:
            - External monitors were recently connected/disconnected
            - The system is under heavy load
            - macOS is updating display configurations
            
            Please try again in a moment.
            """
            
        case .noDisplaysAvailable:
            return """
            No displays found for screen capture.
            
            This can happen if:
            - All external monitors are disconnected
            - Display drivers are not responding
            - The system is in a transitional state
            
            Please check your display connections and try again.
            """
            
        case .captureFailed(let underlyingError):
            return """
            Screen capture failed to complete.
            
            Error: \(underlyingError.localizedDescription)
            
            This might be due to:
            - Insufficient system resources
            - Another app blocking screen capture
            - Temporary system issue
            
            Please try again or restart screenit if the problem persists.
            """
            
        case .imageCroppingFailed:
            return """
            Unable to process the captured image.
            
            This can happen with:
            - Very large capture areas
            - Low system memory
            - Invalid capture coordinates
            
            Please try selecting a smaller area or try again.
            """
            
        case .invalidCaptureArea:
            return """
            Invalid capture area selected.
            
            Please ensure you select a valid area on the screen:
            - The area must be within screen bounds
            - Width and height must be greater than 0
            - The coordinates must be valid
            
            Try selecting the area again.
            """
        }
    }
    
    // MARK: - Error Categorization
    
    /// Error severity levels for prioritizing error handling
    enum ErrorSeverity {
        case critical  // Prevents all functionality
        case high      // Prevents current operation
        case medium    // Degrades user experience
        case low       // Minor issues
    }
    
    /// Determines the severity level of a capture error
    /// - Parameter error: The capture error to evaluate
    /// - Returns: The severity level of the error
    func errorSeverity(for error: CaptureError) -> ErrorSeverity {
        switch error {
        case .notAuthorized, .noDisplaysAvailable:
            return .critical
            
        case .authorizationFailed, .contentDiscoveryFailed, .captureFailed:
            return .high
            
        case .invalidCaptureArea, .imageCroppingFailed:
            return .medium
        }
    }
    
    // MARK: - Recovery Suggestions
    
    /// Provides specific recovery suggestions for an error
    /// - Parameter error: The capture error to provide suggestions for
    /// - Returns: Actionable recovery suggestions
    func recoverySuggestion(for error: CaptureError) -> String {
        switch error {
        case .notAuthorized:
            return "Enable Screen Recording permission in System Preferences > Privacy & Security"
            
        case .authorizationFailed:
            return "Check Screen Recording permissions and restart the app"
            
        case .contentDiscoveryFailed:
            return "Wait a moment and try again, or restart the app if the issue persists"
            
        case .noDisplaysAvailable:
            return "Check display connections and restart the app"
            
        case .captureFailed:
            return "Close other apps that might be using screen capture, then try again"
            
        case .imageCroppingFailed:
            return "Try capturing a smaller area or restart the app"
            
        case .invalidCaptureArea:
            return "Select a valid area within the screen bounds"
        }
    }
    
    // MARK: - Error Logging
    
    /// Logs an error with appropriate context and severity
    /// - Parameters:
    ///   - error: The capture error to log
    ///   - context: Additional context about when/where the error occurred
    func logError(_ error: CaptureError, context: String = "") {
        let severity = errorSeverity(for: error)
        let contextInfo = context.isEmpty ? "" : " Context: \(context)"
        
        switch severity {
        case .critical:
            logger.critical("Critical capture error: \(error.localizedDescription)\(contextInfo)")
            
        case .high:
            logger.error("High-severity capture error: \(error.localizedDescription)\(contextInfo)")
            
        case .medium:
            logger.warning("Medium-severity capture error: \(error.localizedDescription)\(contextInfo)")
            
        case .low:
            logger.info("Low-severity capture error: \(error.localizedDescription)\(contextInfo)")
        }
        
        // Record error for statistics
        recordError(error)
    }
    
    // MARK: - Error Statistics
    
    /// Records an error occurrence for statistical tracking
    /// - Parameter error: The error to record
    func recordError(_ error: CaptureError) {
        let normalizedError = normalizeError(error)
        errorCounts[normalizedError, default: 0] += 1
        
        logger.debug("Error recorded: \(normalizedError). Total count: \(self.errorCounts[normalizedError, default: 0])")
    }
    
    /// Total number of errors recorded
    var errorCount: Int {
        return errorCounts.values.reduce(0, +)
    }
    
    /// Returns the most frequently occurring error
    var mostCommonError: CaptureError? {
        return errorCounts.max(by: { $0.value < $1.value })?.key
    }
    
    /// Resets all error statistics
    func resetErrorCounts() {
        errorCounts.removeAll()
        logger.info("Error statistics reset")
    }
    
    /// Generates a comprehensive error report
    var errorReport: String {
        guard !errorCounts.isEmpty else {
            return "No errors recorded"
        }
        
        let totalErrors = errorCount
        let sortedErrors = errorCounts.sorted { $0.value > $1.value }
        
        var report = "Error Report:\n"
        report += "Total Errors: \(totalErrors)\n\n"
        
        for (error, count) in sortedErrors {
            let percentage = Double(count) / Double(totalErrors) * 100
            report += "\(normalizeErrorName(error)): \(count) (\(String(format: "%.1f", percentage))%)\n"
        }
        
        if let mostCommon = mostCommonError {
            report += "\nMost Common: \(normalizeErrorName(mostCommon))"
        }
        
        return report
    }
    
    // MARK: - Private Helper Methods
    
    /// Normalizes errors with associated values for statistical purposes
    /// (e.g., different .captureFailed errors with different underlying errors are treated as the same type)
    private func normalizeError(_ error: CaptureError) -> CaptureError {
        switch error {
        case .notAuthorized:
            return .notAuthorized
        case .authorizationFailed:
            return .authorizationFailed(NSError(domain: "Normalized", code: 0))
        case .contentDiscoveryFailed:
            return .contentDiscoveryFailed(NSError(domain: "Normalized", code: 0))
        case .noDisplaysAvailable:
            return .noDisplaysAvailable
        case .captureFailed:
            return .captureFailed(NSError(domain: "Normalized", code: 0))
        case .imageCroppingFailed:
            return .imageCroppingFailed
        case .invalidCaptureArea:
            return .invalidCaptureArea
        }
    }
    
    /// Returns a clean name for the error type
    private func normalizeErrorName(_ error: CaptureError) -> String {
        switch error {
        case .notAuthorized:
            return "notAuthorized"
        case .authorizationFailed:
            return "authorizationFailed"
        case .contentDiscoveryFailed:
            return "contentDiscoveryFailed"
        case .noDisplaysAvailable:
            return "noDisplaysAvailable"
        case .captureFailed:
            return "captureFailed"
        case .imageCroppingFailed:
            return "imageCroppingFailed"
        case .invalidCaptureArea:
            return "invalidCaptureArea"
        }
    }
}
