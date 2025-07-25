import Foundation
import Combine
import SwiftUI

// Import MenuBarManager
@preconcurrency import class screenit.MenuBarManager

// Performance testing for MenuBar application
class PerformanceTests {
    static func runTests() {
        print("Running Performance Tests for Menu Bar App...")
        
        testMemoryUsage()
        testStartupTime()
        testBackgroundOperation()
        
        print("All performance tests completed! ✅")
    }
    
    static func testMemoryUsage() {
        print("\n📊 Testing Memory Usage...")
        
        let manager = MenuBarManager()
        let startMemory = getMemoryUsage()
        
        // Simulate typical usage patterns
        for _ in 0..<100 {
            manager.toggleVisibility()
            manager.showMenuBar()
            manager.hideMenuBar()
        }
        
        let endMemory = getMemoryUsage()
        let memoryIncrease = endMemory - startMemory
        
        print("  Start Memory: \(startMemory) MB")
        print("  End Memory: \(endMemory) MB")
        print("  Memory Increase: \(memoryIncrease) MB")
        
        // Memory increase should be minimal for background operation
        assert(memoryIncrease < 10, "Memory increase should be less than 10MB for typical operations")
        print("✓ Memory usage test passed - minimal memory footprint maintained")
    }
    
    static func testStartupTime() {
        print("\n🚀 Testing Startup Performance...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate app initialization
        let manager = MenuBarManager()
        _ = manager.isVisible // Access initial state
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let startupTime = (endTime - startTime) * 1000 // Convert to milliseconds
        
        print("  Startup time: \(String(format: "%.2f", startupTime)) ms")
        
        // Startup should be under 100ms for responsive feel
        assert(startupTime < 100, "Startup time should be under 100ms")
        print("✓ Startup performance test passed - quick initialization")
    }
    
    static func testBackgroundOperation() {
        print("\n🔄 Testing Background Operation Efficiency...")
        
        let manager = MenuBarManager()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate background idle state
        for _ in 0..<1000 {
            // Menu bar should remain responsive during idle
            _ = manager.isVisible
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let operationTime = (endTime - startTime) * 1000
        
        print("  1000 state checks completed in: \(String(format: "%.2f", operationTime)) ms")
        print("  Average per operation: \(String(format: "%.4f", operationTime/1000)) ms")
        
        // Background operations should be very fast
        assert(operationTime < 10, "Background operations should complete in under 10ms total")
        print("✓ Background operation test passed - efficient idle state")
    }
    
    // Helper function to get memory usage
    static func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
}