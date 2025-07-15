//
//  Annotation.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import Foundation
import CoreData

@objc(Annotation)
public class Annotation: NSManagedObject {
    
}

extension Annotation {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Annotation> {
        return NSFetchRequest<Annotation>(entityName: "Annotation")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var positionX: Double
    @NSManaged public var positionY: Double
    @NSManaged public var sizeWidth: Double
    @NSManaged public var sizeHeight: Double
    @NSManaged public var color: String?
    @NSManaged public var thickness: Double
    @NSManaged public var text: String?
    @NSManaged public var fontSize: Double
    @NSManaged public var captureItem: CaptureItem?
    
}

extension Annotation : Identifiable {
    
}