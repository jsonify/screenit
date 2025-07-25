import Foundation
import CoreGraphics
import OSLog

/// Performance monitoring class for screen capture operations
@MainActor
class CapturePerformanceTimer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isTimerRunning: Bool = false
    @Published var lastCaptureDuration: TimeInterval = 0
    @Published var lastImageSize: CGSize = .zero
    @Published var lastMemoryUsage: UInt64 = 0
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.screenit.screenit", category: "CapturePerformanceTimer")
    private var captureMetrics: [CaptureMetrics] = []
    private(set) var startTime: Date?
    
    // MARK: - Performance Constants
    private let targetCaptureTimeSeconds: TimeInterval = 2.0
    private let maxReasonableMemoryMB: UInt64 = 50 // 50MB max reasonable memory usage
    
    // MARK: - Timing Methods
    
    /// Starts the performance timer
    func startTimer() {
        startTime = Date()
        isTimerRunning = true
        logger.debug("Performance timer started")
    }
    
    /// Stops the performance timer and returns the elapsed duration
    /// - Returns: The elapsed time in seconds, or 0 if timer wasn't started
    func stopTimer() -> TimeInterval {
        guard let startTime = startTime else {
            logger.warning("Stop timer called without starting timer")
            return 0
        }
        
        let duration = Date().timeIntervalSince(startTime)
        self.startTime = nil
        isTimerRunning = false
        
        logger.debug("Performance timer stopped: \(duration, format: .fixed(precision: 3))s")
        return duration
    }
    
    // MARK: - Metrics Recording
    
    /// Records capture performance metrics
    /// - Parameters:
    ///   - duration: Time taken for the capture operation
    ///   - imageSize: Size of the captured image
    ///   - memoryUsage: Memory used during capture operation
    func recordCaptureMetrics(duration: TimeInterval, imageSize: CGSize, memoryUsage: UInt64) {
        let metrics = CaptureMetrics(
            duration: duration,
            imageSize: imageSize,
            memoryUsage: memoryUsage,
            timestamp: Date()
        )
        
        captureMetrics.append(metrics)
        
        // Update published properties
        lastCaptureDuration = duration
        lastImageSize = imageSize
        lastMemoryUsage = memoryUsage
        
        // Log performance data
        logger.info("Capture metrics recorded: \(duration, format: .fixed(precision: 3))s, \(imageSize.width, format: .fixed(precision: 0))x\(imageSize.height, format: .fixed(precision: 0)), \(self.formatMemorySize(memoryUsage))")
        
        // Log performance warnings if needed
        if duration > targetCaptureTimeSeconds {
            logger.warning("Capture duration exceeded target: \(duration, format: .fixed(precision: 3))s > \(self.targetCaptureTimeSeconds, format: .fixed(precision: 1))s")
        }
        
        if memoryUsage > maxReasonableMemoryMB * 1024 * 1024 {
            logger.warning("Memory usage exceeded reasonable limit: \(self.formatMemorySize(memoryUsage))")
        }
        
        // Keep only recent metrics (last 100 captures)
        if captureMetrics.count > 100 {
            captureMetrics.removeFirst()
        }
    }
    
    // MARK: - Performance Analysis
    
    /// Returns the average capture time across all recorded metrics
    var averageCaptureTime: TimeInterval {
        guard !captureMetrics.isEmpty else { return 0 }
        
        let totalTime = captureMetrics.reduce(0) { $0 + $1.duration }
        return totalTime / Double(captureMetrics.count)
    }
    
    /// Returns the total number of captures recorded
    var captureCount: Int {
        return captureMetrics.count
    }
    
    /// Returns the total memory usage across all captures
    var totalMemoryUsage: UInt64 {
        return captureMetrics.reduce(0) { $0 + $1.memoryUsage }
    }
    
    /// Returns the average memory usage per capture
    var averageMemoryUsage: UInt64 {
        guard !captureMetrics.isEmpty else { return 0 }
        
        return totalMemoryUsage / UInt64(captureMetrics.count)
    }
    
    /// Checks if current performance is within acceptable targets
    var isPerformanceWithinTargets: Bool {
        guard !captureMetrics.isEmpty else { return true }
        
        let recentAverage = recentAverageCaptureTime(count: 5)
        return recentAverage <= targetCaptureTimeSeconds
    }
    
    /// Returns recent average capture time for the specified number of captures
    /// - Parameter count: Number of recent captures to average
    /// - Returns: Average capture time for recent captures
    private func recentAverageCaptureTime(count: Int) -> TimeInterval {
        guard !captureMetrics.isEmpty else { return 0 }
        
        let recentMetrics = Array(captureMetrics.suffix(count))
        let totalTime = recentMetrics.reduce(0) { $0 + $1.duration }
        return totalTime / Double(recentMetrics.count)
    }
    
    // MARK: - Utility Methods
    
    /// Resets all recorded metrics
    func resetMetrics() {
        captureMetrics.removeAll()
        lastCaptureDuration = 0
        lastImageSize = .zero
        lastMemoryUsage = 0
        
        logger.info("Performance metrics reset")
    }
    
    /// Generates a comprehensive performance report
    var performanceReport: String {
        guard !captureMetrics.isEmpty else {
            return "No capture performance data available"
        }
        
        let avgDuration = averageCaptureTime
        let avgMemory = averageMemoryUsage
        let withinTargets = isPerformanceWithinTargets
        
        return """
        Performance Report:
        - Capture Count: \(captureCount)
        - Average Duration: \(String(format: "%.2f", avgDuration))s
        - Target Duration: \(String(format: "%.1f", targetCaptureTimeSeconds))s
        - Performance Status: \(withinTargets ? "✓ Within Targets" : "⚠ Below Targets")
        - Last Capture: \(String(format: "%.1f", lastImageSize.width))x\(String(format: "%.1f", lastImageSize.height))
        - Average Memory Usage: \(formatMemorySize(avgMemory))
        - Last Memory Usage: \(formatMemorySize(lastMemoryUsage))
        """
    }
    
    /// Formats memory size in human-readable format
    /// - Parameter bytes: Memory size in bytes
    /// - Returns: Formatted string (e.g., "8.3MB")
    private func formatMemorySize(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        if mb >= 1.0 {
            return String(format: "%.1fMB", mb)
        } else {
            let kb = Double(bytes) / 1024
            return String(format: "%.1fKB", kb)
        }
    }
}

// MARK: - Supporting Types

/// Metrics data for a single capture operation
private struct CaptureMetrics {
    let duration: TimeInterval
    let imageSize: CGSize
    let memoryUsage: UInt64
    let timestamp: Date
}