//
//  CaptureEngine.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import Foundation
import ScreenCaptureKit
import SwiftUI

struct TimeoutError: Error {}

func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

enum CapturePermissionError: Error, LocalizedError {
    case permissionDenied
    case systemError(Error)
    case timeout
    case unavailable
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen recording permission denied"
        case .systemError(let error):
            return "System error: \(error.localizedDescription)"
        case .timeout:
            return "Permission request timed out"
        case .unavailable:
            return "Screen capture unavailable"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Please enable screen recording permission in System Settings > Privacy & Security > Screen Recording"
        case .systemError:
            return "Please try restarting the application or your Mac"
        case .timeout:
            return "Please try again or restart the application"
        case .unavailable:
            return "Screen capture is not available on this system"
        }
    }
}

@MainActor
class CaptureEngine: ObservableObject {
    @Published var isCapturing = false
    @Published var capturePermissionGranted = false
    @Published var permissionError: CapturePermissionError?
    @Published var needsPermissionSetup = false
    
    private var availableDisplays: [SCDisplay] = []
    private var availableApps: [SCRunningApplication] = []
    
    init() {
        Task {
            await checkAndRequestPermission()
        }
    }
    
    func checkAndRequestPermission() async {
        do {
            let content = try await withTimeout(seconds: 5.0) {
                try await SCShareableContent.current
            }
            
            if !content.displays.isEmpty {
                capturePermissionGranted = true
                permissionError = nil
                needsPermissionSetup = false
                await updateAvailableContent()
            } else {
                capturePermissionGranted = false
                permissionError = .unavailable
                needsPermissionSetup = true
            }
        } catch is TimeoutError {
            capturePermissionGranted = false
            permissionError = .timeout
            needsPermissionSetup = true
        } catch {
            capturePermissionGranted = false
            if error.localizedDescription.contains("not authorized") || 
               error.localizedDescription.contains("permission") {
                permissionError = .permissionDenied
                needsPermissionSetup = true
            } else {
                permissionError = .systemError(error)
                needsPermissionSetup = false
            }
        }
    }
    
    func retryPermissionCheck() async {
        await checkAndRequestPermission()
    }
    
    func updateAvailableContent() async {
        guard capturePermissionGranted else { return }
        
        do {
            let content = try await SCShareableContent.current
            availableDisplays = content.displays
            availableApps = content.applications
        } catch {
            permissionError = .systemError(error)
            capturePermissionGranted = false
        }
    }
    
    func captureArea(_ rect: CGRect) async -> NSImage? {
        if !capturePermissionGranted {
            await checkAndRequestPermission()
            guard capturePermissionGranted else { return nil }
        }
        
        if availableDisplays.isEmpty {
            await updateAvailableContent()
        }
        
        guard let display = availableDisplays.first else { return nil }
        
        isCapturing = true
        defer { isCapturing = false }
        
        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.width = Int(rect.width)
        configuration.height = Int(rect.height)
        configuration.sourceRect = rect
        configuration.scalesToFit = false
        configuration.showsCursor = false
        
        do {
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
            return NSImage(cgImage: image, size: rect.size)
        } catch {
            permissionError = .systemError(error)
            return nil
        }
    }
    
    func captureFullScreen() async -> NSImage? {
        if availableDisplays.isEmpty {
            await updateAvailableContent()
        }
        
        guard let display = availableDisplays.first else { return nil }
        let rect = CGRect(origin: .zero, size: CGSize(width: display.width, height: display.height))
        return await captureArea(rect)
    }
    
    func samplePixelsAt(point: CGPoint, size: CGSize = CGSize(width: 21, height: 21)) async -> NSImage? {
        guard capturePermissionGranted else { return nil }
        
        if availableDisplays.isEmpty {
            await updateAvailableContent()
        }
        
        guard let display = availableDisplays.first else { return nil }
        
        let halfSize = CGSize(width: size.width / 2, height: size.height / 2)
        let sampleRect = CGRect(
            x: point.x - halfSize.width,
            y: point.y - halfSize.height,
            width: size.width,
            height: size.height
        )
        
        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.width = Int(size.width)
        configuration.height = Int(size.height)
        configuration.sourceRect = sampleRect
        configuration.scalesToFit = false
        configuration.showsCursor = false
        
        do {
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
            return NSImage(cgImage: image, size: size)
        } catch {
            return nil
        }
    }
    
    func getRGBAt(point: CGPoint) async -> (red: Int, green: Int, blue: Int)? {
        guard let sampleImage = await samplePixelsAt(point: point, size: CGSize(width: 1, height: 1)) else {
            return nil
        }
        
        guard let cgImage = sampleImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let pixelData = cgImage.dataProvider?.data
        guard let data = pixelData else { return nil }
        let dataPtr = CFDataGetBytePtr(data)
        guard let ptr = dataPtr else { return nil }
        
        let bytesPerPixel = 4
        let pixelInfo = bytesPerPixel * 0
        
        let red = Int(ptr[pixelInfo])
        let green = Int(ptr[pixelInfo + 1])
        let blue = Int(ptr[pixelInfo + 2])
        
        return (red: red, green: green, blue: blue)
    }
}