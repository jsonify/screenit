import XCTest
import CoreData
@testable import screenit

final class PersistenceManagerTests: XCTestCase {
    
    var persistenceManager: PersistenceManager!
    var testContainer: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory store for testing
        persistenceManager = PersistenceManager(inMemory: true)
        testContainer = persistenceManager.container
    }
    
    override func tearDown() {
        persistenceManager = nil
        testContainer = nil
        super.tearDown()
    }
    
    // MARK: - Core Data Stack Tests
    
    func testPersistenceManagerInitialization() {
        // Given
        let manager = PersistenceManager(inMemory: true)
        
        // When & Then
        XCTAssertNotNil(manager.container, "Container should be initialized")
        XCTAssertNotNil(manager.viewContext, "View context should be available")
        XCTAssertEqual(manager.container.name, "ScreenitDataModel", "Container should have correct name")
    }
    
    func testInMemoryStoreConfiguration() {
        // Given
        let manager = PersistenceManager(inMemory: true)
        
        // When
        let storeDescription = manager.container.persistentStoreDescriptions.first
        
        // Then
        XCTAssertNotNil(storeDescription, "Store description should exist")
        XCTAssertEqual(storeDescription?.url, URL(fileURLWithPath: "/dev/null"), "In-memory store should use /dev/null URL")
    }
    
    func testBackgroundContextCreation() {
        // Given & When
        let backgroundContext = persistenceManager.newBackgroundContext()
        
        // Then
        XCTAssertNotNil(backgroundContext, "Background context should be created")
        XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType, "Background context should use private queue")
        XCTAssertEqual(backgroundContext.parent, persistenceManager.viewContext, "Background context should have view context as parent")
    }
    
    func testContextSaving() {
        // Given
        let backgroundContext = persistenceManager.newBackgroundContext()
        let expectation = XCTestExpectation(description: "Context save completion")
        
        // When
        persistenceManager.save(context: backgroundContext) { result in
            // Then
            switch result {
            case .success:
                XCTAssertTrue(true, "Save should succeed")
            case .failure(let error):
                XCTFail("Save should not fail: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testContextSavingWithError() {
        // Given
        let backgroundContext = persistenceManager.newBackgroundContext()
        
        // Create an invalid managed object to trigger save error
        let entity = NSEntityDescription.entity(forEntityName: "CaptureItem", in: backgroundContext)!
        let captureItem = NSManagedObject(entity: entity, insertInto: backgroundContext)
        // Don't set required attributes to trigger validation error
        
        let expectation = XCTestExpectation(description: "Context save error handling")
        
        // When
        persistenceManager.save(context: backgroundContext) { result in
            // Then
            switch result {
            case .success:
                XCTFail("Save should fail with invalid data")
            case .failure(let error):
                XCTAssertTrue(error is NSError, "Error should be NSError type")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testViewContextConfiguration() {
        // Given & When
        let viewContext = persistenceManager.viewContext
        
        // Then
        XCTAssertEqual(viewContext.concurrencyType, .mainQueueConcurrencyType, "View context should use main queue")
        XCTAssertTrue(viewContext.automaticallyMergesChangesFromParent, "View context should auto-merge changes")
    }
    
    func testContainerLoadingCompletes() {
        // Given
        let manager = PersistenceManager(inMemory: true)
        let expectation = XCTestExpectation(description: "Container loading")
        
        // When
        manager.container.loadPersistentStores { _, error in
            // Then
            XCTAssertNil(error, "Container loading should complete without error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}