import Foundation
import CoreData
import OSLog

/// Manages Core Data stack for screenit application
/// Provides thread-safe access to managed object contexts and handles data persistence
final class PersistenceManager: ObservableObject {
    
    // MARK: - Logger
    
    private let logger = Logger(subsystem: "com.screenit.app", category: "PersistenceManager")
    
    // MARK: - Core Data Stack
    
    /// The Core Data persistent container
    lazy var container: NSPersistentContainer = {
        // Try multiple approaches to find the Core Data model
        let modelName = "ScreenitDataModel"
        var model: NSManagedObjectModel?
        var modelURL: URL?
        
        // Debug: List all available resources
        logger.debug("Debugging bundle resources...")
        if let resourcePath = Bundle.main.resourcePath {
            logger.debug("Main bundle resource path: \(resourcePath)")
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                logger.debug("Bundle contents: \(contents)")
            } catch {
                logger.debug("Could not list bundle contents: \(error)")
            }
        }
        
        // Check for SPM resource bundle
        var bundles = [Bundle.main]
        #if SWIFT_PACKAGE
        bundles.append(Bundle.module)
        logger.debug("Added SPM module bundle")
        #endif
        
        // Try each bundle
        for bundle in bundles {
            logger.debug("Checking bundle: \(bundle.bundlePath)")
            
            // Approach 1: Try compiled .momd format
            if let momdURL = bundle.url(forResource: modelName, withExtension: "momd") {
                logger.info("Found compiled model at: \(momdURL)")
                model = NSManagedObjectModel(contentsOf: momdURL)
                modelURL = momdURL
                break
            }
            
            // Approach 2: Try .xcdatamodeld source format
            if let xcdatamodeldURL = bundle.url(forResource: modelName, withExtension: "xcdatamodeld") {
                logger.info("Found source model at: \(xcdatamodeldURL)")
                model = NSManagedObjectModel(contentsOf: xcdatamodeldURL)
                modelURL = xcdatamodeldURL
                break
            }
        }
        
        // Approach 3: Let NSPersistentContainer find it automatically
        if model == nil {
            logger.info("Using automatic model discovery for: \(modelName)")
            return NSPersistentContainer(name: modelName)
        }
        
        guard let finalModel = model else {
            logger.error("Could not load Core Data model from URL: \(modelURL?.absoluteString ?? "unknown")")
            fatalError("Failed to load Core Data model")
        }
        
        logger.info("Successfully loaded Core Data model from: \(modelURL?.lastPathComponent ?? "unknown")")
        let container = NSPersistentContainer(name: modelName, managedObjectModel: finalModel)
        
        // Configure for in-memory store if needed (for testing)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure store descriptions
        if let storeDescription = container.persistentStoreDescriptions.first {
            // Enable automatic lightweight migration
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            
            // Enable persistent history tracking for CloudKit or multi-app scenarios
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                self.logger.error("Failed to load Core Data store: \(error.localizedDescription)")
                // In production, you might want to handle this more gracefully
                fatalError("Failed to load Core Data store: \(error)")
            } else {
                self.logger.info("Core Data store loaded successfully: \(storeDescription.url?.lastPathComponent ?? "unknown")")
            }
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    /// Main thread managed object context for UI operations
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    /// Flag to indicate if this is an in-memory store (for testing)
    private let inMemory: Bool
    
    // MARK: - Initialization
    
    /// Initialize PersistenceManager
    /// - Parameter inMemory: If true, creates an in-memory store for testing
    init(inMemory: Bool = false) {
        self.inMemory = inMemory
        
        if inMemory {
            logger.info("Initializing PersistenceManager with in-memory store")
        } else {
            logger.info("Initializing PersistenceManager with persistent store")
        }
    }
    
    // MARK: - Context Management
    
    /// Creates a new background context for performing data operations off the main thread
    /// - Returns: A new NSManagedObjectContext configured for background operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    /// Saves the specified context
    /// - Parameters:
    ///   - context: The context to save
    ///   - completion: Completion handler called on the main thread
    func save(context: NSManagedObjectContext, completion: @escaping (Result<Void, Error>) -> Void) {
        context.perform {
            do {
                if context.hasChanges {
                    try context.save()
                    self.logger.debug("Context saved successfully")
                }
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                self.logger.error("Failed to save context: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Saves the view context synchronously (for simple operations)
    /// - Throws: Core Data errors if save fails
    func saveViewContext() throws {
        if viewContext.hasChanges {
            try viewContext.save()
            logger.debug("View context saved successfully")
        }
    }
    
    // MARK: - Data Operations
    
    /// Performs a background operation and saves the context
    /// - Parameter operation: Block to perform on background context
    func performBackgroundTask(_ operation: @escaping (NSManagedObjectContext) -> Void) {
        let context = newBackgroundContext()
        
        context.perform {
            operation(context)
            
            if context.hasChanges {
                do {
                    try context.save()
                    self.logger.debug("Background task completed and saved")
                } catch {
                    self.logger.error("Failed to save background context: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Performs a background operation with completion handler
    /// - Parameters:
    ///   - operation: Block to perform on background context
    ///   - completion: Completion handler called on main thread
    func performBackgroundTask(
        _ operation: @escaping (NSManagedObjectContext) throws -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let context = newBackgroundContext()
        
        context.perform {
            do {
                try operation(context)
                
                if context.hasChanges {
                    try context.save()
                }
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                self.logger.error("Background task failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Batch Operations
    
    /// Deletes objects matching the fetch request
    /// - Parameters:
    ///   - fetchRequest: Request for objects to delete
    ///   - completion: Completion handler called on main thread
    func batchDelete<T: NSManagedObject>(
        _ fetchRequest: NSFetchRequest<T>,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        deleteRequest.resultType = .resultTypeCount
        
        performBackgroundTask { context in
            let result = try context.execute(deleteRequest) as! NSBatchDeleteResult
            let deletedCount = result.result as! Int
            
            DispatchQueue.main.async {
                completion(.success(deletedCount))
            }
        } completion: { result in
            if case .failure(let error) = result {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Cleanup
    
    /// Performs cleanup operations like removing orphaned data
    func performCleanup() {
        logger.info("Starting database cleanup")
        
        performBackgroundTask { context in
            // Add cleanup logic here if needed
            // For example, removing old captures beyond retention limit
            self.logger.debug("Database cleanup completed")
        }
    }
}

// MARK: - Singleton Access

extension PersistenceManager {
    /// Shared instance for application-wide use
    static let shared = PersistenceManager()
}