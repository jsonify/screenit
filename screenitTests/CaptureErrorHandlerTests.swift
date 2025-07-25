import XCTest
@testable import screenit

@MainActor
final class CaptureErrorHandlerTests: XCTestCase {
    
    var errorHandler: CaptureErrorHandler!
    
    override func setUp() async throws {
        errorHandler = CaptureErrorHandler()
    }
    
    override func tearDown() async throws {
        errorHandler = nil
    }
    
    // MARK: - Error Message Generation Tests
    
    func testUserFriendlyMessageForNotAuthorized() {
        let message = errorHandler.userFriendlyMessage(for: .notAuthorized)
        
        XCTAssertTrue(message.contains("Screen Recording permission"))
        XCTAssertTrue(message.contains("System Preferences"))
        XCTAssertTrue(message.contains("Privacy & Security"))
    }
    
    func testUserFriendlyMessageForNoDisplaysAvailable() {
        let message = errorHandler.userFriendlyMessage(for: .noDisplaysAvailable)
        
        XCTAssertTrue(message.contains("No displays found"))
        XCTAssertTrue(message.contains("external monitors"))
    }
    
    func testUserFriendlyMessageForCaptureFailed() {
        let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let captureError = CaptureError.captureFailed(underlyingError)
        let message = errorHandler.userFriendlyMessage(for: captureError)
        
        XCTAssertTrue(message.contains("Screen capture failed"))
        XCTAssertTrue(message.contains("Test error"))
    }
    
    func testUserFriendlyMessageForContentDiscoveryFailed() {
        let underlyingError = NSError(domain: "TestDomain", code: 456, userInfo: [NSLocalizedDescriptionKey: "Discovery error"])
        let captureError = CaptureError.contentDiscoveryFailed(underlyingError)
        let message = errorHandler.userFriendlyMessage(for: captureError)
        
        XCTAssertTrue(message.contains("Unable to find screens"))
        XCTAssertTrue(message.contains("Discovery error"))
    }
    
    func testUserFriendlyMessageForInvalidCaptureArea() {
        let message = errorHandler.userFriendlyMessage(for: .invalidCaptureArea)
        
        XCTAssertTrue(message.contains("Invalid capture area"))
        XCTAssertTrue(message.contains("valid area"))
    }
    
    func testUserFriendlyMessageForImageCroppingFailed() {
        let message = errorHandler.userFriendlyMessage(for: .imageCroppingFailed)
        
        XCTAssertTrue(message.contains("Unable to process"))
        XCTAssertTrue(message.contains("try again"))
    }
    
    // MARK: - Error Categorization Tests
    
    func testErrorSeverityForCriticalErrors() {
        XCTAssertEqual(errorHandler.errorSeverity(for: .notAuthorized), .critical)
        XCTAssertEqual(errorHandler.errorSeverity(for: .noDisplaysAvailable), .critical)
    }
    
    func testErrorSeverityForHighErrors() {
        let captureError = CaptureError.captureFailed(NSError(domain: "Test", code: 1))
        XCTAssertEqual(errorHandler.errorSeverity(for: captureError), .high)
        
        let contentError = CaptureError.contentDiscoveryFailed(NSError(domain: "Test", code: 1))
        XCTAssertEqual(errorHandler.errorSeverity(for: contentError), .high)
    }
    
    func testErrorSeverityForMediumErrors() {
        XCTAssertEqual(errorHandler.errorSeverity(for: .invalidCaptureArea), .medium)
        XCTAssertEqual(errorHandler.errorSeverity(for: .imageCroppingFailed), .medium)
    }
    
    // MARK: - Recovery Suggestion Tests
    
    func testRecoverySuggestionForNotAuthorized() {
        let suggestion = errorHandler.recoverySuggestion(for: .notAuthorized)
        
        XCTAssertTrue(suggestion.contains("System Preferences"))
        XCTAssertTrue(suggestion.contains("Privacy & Security"))
        XCTAssertTrue(suggestion.contains("Screen Recording"))
    }
    
    func testRecoverySuggestionForNoDisplaysAvailable() {
        let suggestion = errorHandler.recoverySuggestion(for: .noDisplaysAvailable)
        
        XCTAssertTrue(suggestion.contains("Check connections"))
        XCTAssertTrue(suggestion.contains("restart"))
    }
    
    func testRecoverySuggestionForCaptureFailed() {
        let underlyingError = NSError(domain: "TestDomain", code: 123)
        let captureError = CaptureError.captureFailed(underlyingError)
        let suggestion = errorHandler.recoverySuggestion(for: captureError)
        
        XCTAssertTrue(suggestion.contains("try again"))
        XCTAssertTrue(suggestion.contains("restart"))
    }
    
    // MARK: - Error Logging Tests
    
    func testLogErrorCreatesLogEntry() {
        let error = CaptureError.notAuthorized
        
        // This is a behavior test - we can't easily test log output directly
        // but we can ensure the method doesn't crash
        XCTAssertNoThrow(errorHandler.logError(error, context: "Test context"))
    }
    
    func testLogErrorWithContext() {
        let error = CaptureError.invalidCaptureArea
        let context = "Testing error logging"
        
        XCTAssertNoThrow(errorHandler.logError(error, context: context))
    }
    
    // MARK: - Error Statistics Tests
    
    func testRecordError() {
        let error = CaptureError.notAuthorized
        
        errorHandler.recordError(error)
        
        XCTAssertEqual(errorHandler.errorCount, 1)
        XCTAssertEqual(errorHandler.errorCounts[.notAuthorized], 1)
    }
    
    func testMultipleErrorRecording() {
        errorHandler.recordError(.notAuthorized)
        errorHandler.recordError(.notAuthorized)
        errorHandler.recordError(.noDisplaysAvailable)
        
        XCTAssertEqual(errorHandler.errorCount, 3)
        XCTAssertEqual(errorHandler.errorCounts[.notAuthorized], 2)
        XCTAssertEqual(errorHandler.errorCounts[.noDisplaysAvailable], 1)
    }
    
    func testMostCommonError() {
        errorHandler.recordError(.notAuthorized)
        errorHandler.recordError(.noDisplaysAvailable)
        errorHandler.recordError(.notAuthorized)
        
        XCTAssertEqual(errorHandler.mostCommonError, .notAuthorized)
    }
    
    func testMostCommonErrorWithNoErrors() {
        XCTAssertNil(errorHandler.mostCommonError)
    }
    
    func testResetErrorCounts() {
        errorHandler.recordError(.notAuthorized)
        errorHandler.recordError(.noDisplaysAvailable)
        
        errorHandler.resetErrorCounts()
        
        XCTAssertEqual(errorHandler.errorCount, 0)
        XCTAssertTrue(errorHandler.errorCounts.isEmpty)
        XCTAssertNil(errorHandler.mostCommonError)
    }
    
    // MARK: - Error Report Tests
    
    func testErrorReport() {
        errorHandler.recordError(.notAuthorized)
        errorHandler.recordError(.noDisplaysAvailable)
        errorHandler.recordError(.notAuthorized)
        
        let report = errorHandler.errorReport
        
        XCTAssertTrue(report.contains("Total Errors: 3"))
        XCTAssertTrue(report.contains("notAuthorized: 2"))
        XCTAssertTrue(report.contains("noDisplaysAvailable: 1"))
        XCTAssertTrue(report.contains("Most Common: notAuthorized"))
    }
    
    func testErrorReportWithNoErrors() {
        let report = errorHandler.errorReport
        
        XCTAssertTrue(report.contains("No errors recorded"))
    }
}