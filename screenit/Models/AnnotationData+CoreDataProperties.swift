import Foundation
import CoreData

extension AnnotationData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AnnotationData> {
        return NSFetchRequest<AnnotationData>(entityName: "AnnotationData")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var normalizedX: Float
    @NSManaged public var normalizedY: Float
    @NSManaged public var normalizedWidth: Float
    @NSManaged public var normalizedHeight: Float
    @NSManaged public var colorHex: String?
    @NSManaged public var thickness: Double
    @NSManaged public var properties: Data?
    @NSManaged public var timestamp: Date?
    @NSManaged public var captureItem: CaptureItem?

}

extension AnnotationData : Identifiable {

}