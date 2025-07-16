//
//  MockScreenCaptureKit.swift
//  screenitTests
//
//  Created by Claude Code on 7/16/25.
//

import Foundation
import CoreGraphics
import AppKit
@testable import screenit

// MARK: - Mock SCDisplay
class MockSCDisplay {
    let displayID: UInt32
    let width: Int
    let height: Int
    let frame: CGRect
    
    init(displayID: UInt32 = 1, width: Int = 1920, height: Int = 1080, frame: CGRect? = nil) {
        self.displayID = displayID
        self.width = width
        self.height = height
        self.frame = frame ?? CGRect(x: 0, y: 0, width: width, height: height)
    }
}

// MARK: - Mock SCRunningApplication
class MockSCRunningApplication {
    let bundleIdentifier: String
    let applicationName: String
    let processID: pid_t
    
    init(bundleIdentifier: String = "com.test.app", 
         applicationName: String = "Test App", 
         processID: pid_t = 1234) {
        self.bundleIdentifier = bundleIdentifier
        self.applicationName = applicationName
        self.processID = processID
    }
}

// MARK: - Mock SCShareableContent
class MockSCShareableContent {
    let displays: [MockSCDisplay]
    let applications: [MockSCRunningApplication]
    
    init(displays: [MockSCDisplay] = [MockSCDisplay()], 
         applications: [MockSCRunningApplication] = [MockSCRunningApplication()]) {
        self.displays = displays
        self.applications = applications
    }
    
    static var mockCurrent: MockSCShareableContent = MockSCShareableContent()
    static var shouldThrowError: Bool = false
    static var errorToThrow: Error? = nil
    
    static func current() async throws -> MockSCShareableContent {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "MockError", code: 1)
        }
        return mockCurrent
    }
}

// MARK: - Mock SCContentFilter
class MockSCContentFilter {
    let display: MockSCDisplay?
    
    init(display: MockSCDisplay) {
        self.display = display
    }
}

// MARK: - Mock SCStreamConfiguration
class MockSCStreamConfiguration {
    var width: Int = 0
    var height: Int = 0
    var sourceRect: CGRect = .zero
    
    init() {}
}

// MARK: - Mock SCScreenshotManager
class MockSCScreenshotManager {
    static var shouldSucceed: Bool = true
    
    static func captureImage(contentFilter: MockSCContentFilter, 
                           configuration: MockSCStreamConfiguration) async throws -> CGImage {
        if !shouldSucceed {
            throw NSError(domain: "MockCaptureError", code: 2)
        }
        
        // Create minimal 1x1 test image
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        return context.makeImage()!
    }
    
    static func reset() {
        shouldSucceed = true
    }
}

// MARK: - Mock Capture Engine for Testing
@MainActor
class MockCaptureEngine: ObservableObject {
    @Published var isCapturing = false
    @Published var capturePermissionGranted = true
    @Published var permissionError: CapturePermissionError?
    @Published var needsPermissionSetup = false
    
    private var mockDisplays: [MockSCDisplay] = []
    
    func setMockDisplays(_ displays: [MockSCDisplay]) {
        mockDisplays = displays
    }
    
    func checkAndRequestPermission() async {
        if MockSCShareableContent.shouldThrowError {
            capturePermissionGranted = false
            permissionError = .permissionDenied
            needsPermissionSetup = true
        } else {
            capturePermissionGranted = true
            permissionError = nil
            needsPermissionSetup = false
        }
    }
    
    func captureArea(_ rect: CGRect) async -> NSImage? {
        guard capturePermissionGranted else { return nil }
        
        isCapturing = true
        defer { isCapturing = false }
        
        do {
            let filter = MockSCContentFilter(display: mockDisplays.first ?? MockSCDisplay())
            let configuration = MockSCStreamConfiguration()
            
            let cgImage = try await MockSCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
            return NSImage(cgImage: cgImage, size: CGSize(width: 1, height: 1))
        } catch {
            return nil
        }
    }
    
    func getAvailableDisplays() -> [MockSCDisplay] {
        return mockDisplays
    }
}