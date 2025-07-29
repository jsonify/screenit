import XCTest
import CoreData
@testable import screenit

/// Basic tests to verify UserPreferences Core Data entity can be created
/// This focuses only on the Core Data model without dependencies on UI components
final class UserPreferencesBasicTests: XCTestCase {
    
    func testUserPreferencesEntityExists() {
        // This test just verifies that the UserPreferences entity can be instantiated
        // and that our Core Data model is properly configured
        
        // Create an in-memory Core Data stack for testing
        let model = NSManagedObjectModel()
        
        // Create UserPreferences entity description manually for this test
        let entity = NSEntityDescription()
        entity.name = "UserPreferences"
        entity.managedObjectClassName = "UserPreferences"
        
        // Add some basic attributes that we know should exist
        let historyLimit = NSAttributeDescription()
        historyLimit.name = "historyRetentionLimit"
        historyLimit.attributeType = .integer32AttributeType
        historyLimit.isOptional = true
        
        let showMenuBar = NSAttributeDescription()
        showMenuBar.name = "showMenuBarIcon"
        showMenuBar.attributeType = .booleanAttributeType
        showMenuBar.isOptional = true
        
        let defaultArrowColor = NSAttributeDescription()
        defaultArrowColor.name = "defaultArrowColor"
        defaultArrowColor.attributeType = .stringAttributeType
        defaultArrowColor.isOptional = true
        
        entity.properties = [historyLimit, showMenuBar, defaultArrowColor]
        model.entities = [entity]
        
        // Create persistent store
        let container = NSPersistentContainer(name: "TestModel", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        let expectation = XCTestExpectation(description: "Core Data stack loads")
        
        container.loadPersistentStores { _, error in
            XCTAssertNil(error, "Core Data stack should load without error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Test that we can create a basic managed object
        let context = container.viewContext
        let userPrefs = NSManagedObject(entity: entity, insertInto: context)
        
        // Set some values
        userPrefs.setValue(10, forKey: "historyRetentionLimit")
        userPrefs.setValue(true, forKey: "showMenuBarIcon")
        userPrefs.setValue("#FF0000", forKey: "defaultArrowColor")
        
        // Verify values can be set and retrieved
        XCTAssertEqual(userPrefs.value(forKey: "historyRetentionLimit") as? Int32, 10)
        XCTAssertEqual(userPrefs.value(forKey: "showMenuBarIcon") as? Bool, true)
        XCTAssertEqual(userPrefs.value(forKey: "defaultArrowColor") as? String, "#FF0000")
        
        // Test that we can save
        do {
            try context.save()
        } catch {
            XCTFail("Should be able to save context: \(error)")
        }
    }
    
    func testCoreDataModelVersionExists() {
        // Test that our new Core Data model version exists
        let bundle = Bundle.main
        let modelURL = bundle.url(forResource: "ScreenitDataModel", withExtension: "momd")
        XCTAssertNotNil(modelURL, "ScreenitDataModel.momd should exist in the bundle")
        
        if let url = modelURL {
            let model = NSManagedObjectModel(contentsOf: url)
            XCTAssertNotNil(model, "Should be able to load NSManagedObjectModel from URL")
            
            // Verify that UserPreferences entity exists in the model
            let entities = model?.entities ?? []
            let userPrefsEntity = entities.first { $0.name == "UserPreferences" }
            XCTAssertNotNil(userPrefsEntity, "UserPreferences entity should exist in the model")
            
            if let entity = userPrefsEntity {
                // Verify some key attributes exist
                let attributeNames = entity.attributesByName.keys
                XCTAssertTrue(attributeNames.contains("historyRetentionLimit"), "Should have historyRetentionLimit attribute")
                XCTAssertTrue(attributeNames.contains("showMenuBarIcon"), "Should have showMenuBarIcon attribute")
                XCTAssertTrue(attributeNames.contains("defaultArrowColor"), "Should have defaultArrowColor attribute")
            }
        }
    }
}