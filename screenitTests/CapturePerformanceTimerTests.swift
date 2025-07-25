import XCTest
@testable import screenit

@MainActor
final class CapturePerformanceTimerTests: XCTestCase {
    
    var performanceTimer: CapturePerformanceTimer!
    
    override func setUp() async throws {
        performanceTimer = CapturePerformanceTimer()
    }
    
    override func tearDown() async throws {
        performanceTimer = nil
    }
    
    // MARK: - Timing Tests
    
    func testStartTimer() {
        performanceTimer.startTimer()
        XCTAssertNotNil(performanceTimer.startTime)
        XCTAssertTrue(performanceTimer.isTimerRunning)
    }
    
    func testStopTimer() {
        performanceTimer.startTimer()
        let duration = performanceTimer.stopTimer()
        
        XCTAssertFalse(performanceTimer.isTimerRunning)
        XCTAssertGreaterThan(duration, 0)
        XCTAssertLessThan(duration, 1.0) // Should be very quick for this test
    }
    
    func testStopTimerWithoutStart() {
        let duration = performanceTimer.stopTimer()
        XCTAssertEqual(duration, 0)
        XCTAssertFalse(performanceTimer.isTimerRunning)
    }
    
    func testMultipleStartCalls() {
        performanceTimer.startTimer()
        let firstStartTime = performanceTimer.startTime
        
        // Second start should update the start time
        performanceTimer.startTimer()
        let secondStartTime = performanceTimer.startTime
        
        XCTAssertNotEqual(firstStartTime, secondStartTime)
        XCTAssertTrue(performanceTimer.isTimerRunning)
    }
    
    // MARK: - Metrics Tests
    
    func testRecordCaptureMetrics() {
        let duration = 1.5
        let imageSize = CGSize(width: 1920, height: 1080)
        let memoryUsage: UInt64 = 8294400 // 1920 * 1080 * 4 bytes per pixel
        
        performanceTimer.recordCaptureMetrics(
            duration: duration,
            imageSize: imageSize,
            memoryUsage: memoryUsage
        )
        
        XCTAssertEqual(performanceTimer.lastCaptureDuration, duration)
        XCTAssertEqual(performanceTimer.lastImageSize, imageSize)
        XCTAssertEqual(performanceTimer.lastMemoryUsage, memoryUsage)
    }
    
    func testAverageCaptureTime() {
        // Record multiple capture times
        performanceTimer.recordCaptureMetrics(duration: 1.0, imageSize: CGSize(width: 100, height: 100), memoryUsage: 1000)
        performanceTimer.recordCaptureMetrics(duration: 2.0, imageSize: CGSize(width: 100, height: 100), memoryUsage: 1000)
        performanceTimer.recordCaptureMetrics(duration: 3.0, imageSize: CGSize(width: 100, height: 100), memoryUsage: 1000)
        
        XCTAssertEqual(performanceTimer.averageCaptureTime, 2.0)
    }
    
    func testAverageCaptureTimeWithNoData() {
        XCTAssertEqual(performanceTimer.averageCaptureTime, 0)
    }
    
    func testCaptureCount() {
        XCTAssertEqual(performanceTimer.captureCount, 0)
        
        performanceTimer.recordCaptureMetrics(duration: 1.0, imageSize: CGSize(width: 100, height: 100), memoryUsage: 1000)
        XCTAssertEqual(performanceTimer.captureCount, 1)
        
        performanceTimer.recordCaptureMetrics(duration: 2.0, imageSize: CGSize(width: 100, height: 100), memoryUsage: 1000)
        XCTAssertEqual(performanceTimer.captureCount, 2)
    }
    
    // MARK: - Memory Usage Tests
    
    func testTotalMemoryUsage() {
        performanceTimer.recordCaptureMetrics(duration: 1.0, imageSize: CGSize(width: 100, height: 100), memoryUsage: 1000)
        performanceTimer.recordCaptureMetrics(duration: 2.0, imageSize: CGSize(width: 200, height: 200), memoryUsage: 2000)
        
        XCTAssertEqual(performanceTimer.totalMemoryUsage, 3000)
    }
    
    func testAverageMemoryUsage() {
        performanceTimer.recordCaptureMetrics(duration: 1.0, imageSize: CGSize(width: 100, height: 100), memoryUsage: 1000)
        performanceTimer.recordCaptureMetrics(duration: 2.0, imageSize: CGSize(width: 200, height: 200), memoryUsage: 3000)
        
        XCTAssertEqual(performanceTimer.averageMemoryUsage, 2000)
    }
    
    // MARK: - Reset Tests
    
    func testResetMetrics() {
        performanceTimer.recordCaptureMetrics(duration: 1.0, imageSize: CGSize(width: 100, height: 100), memoryUsage: 1000)
        performanceTimer.resetMetrics()
        
        XCTAssertEqual(performanceTimer.captureCount, 0)
        XCTAssertEqual(performanceTimer.averageCaptureTime, 0)
        XCTAssertEqual(performanceTimer.totalMemoryUsage, 0)
        XCTAssertEqual(performanceTimer.lastCaptureDuration, 0)
        XCTAssertEqual(performanceTimer.lastImageSize, .zero)
        XCTAssertEqual(performanceTimer.lastMemoryUsage, 0)
    }
    
    // MARK: - Performance Threshold Tests
    
    func testIsPerformanceWithinTargets() {
        // Test with good performance
        performanceTimer.recordCaptureMetrics(duration: 1.0, imageSize: CGSize(width: 1920, height: 1080), memoryUsage: 1000000)
        XCTAssertTrue(performanceTimer.isPerformanceWithinTargets)
        
        // Test with poor performance
        performanceTimer.recordCaptureMetrics(duration: 5.0, imageSize: CGSize(width: 1920, height: 1080), memoryUsage: 1000000)
        XCTAssertFalse(performanceTimer.isPerformanceWithinTargets)
    }
    
    func testPerformanceReport() {
        performanceTimer.recordCaptureMetrics(duration: 1.5, imageSize: CGSize(width: 1920, height: 1080), memoryUsage: 8294400)
        
        let report = performanceTimer.performanceReport
        
        XCTAssertTrue(report.contains("Capture Count: 1"))
        XCTAssertTrue(report.contains("Average Duration: 1.50s"))
        XCTAssertTrue(report.contains("Last Capture: 1920.0x1080.0"))
        XCTAssertTrue(report.contains("Memory Usage: 8.3MB"))
    }
}