import XCTest
import CoreData

final class SimplePersistenceTest: XCTestCase {
    
    func testCoreDataStackCreation() {
        // Test creating Core Data stack manually without PersistenceManager
        let container = NSPersistentContainer(name: "ScreenitDataModel")
        
        // Use in-memory store
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        
        let expectation = XCTestExpectation(description: "Container loading")
        
        container.loadPersistentStores { _, error in
            XCTAssertNil(error, "Container should load without error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Test context creation
        let context = container.viewContext
        XCTAssertNotNil(context, "View context should be available")
    }
}