//
//  CaptureItem.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import Foundation
import CoreData

@objc(CaptureItem)
public class CaptureItem: NSManagedObject {
    
}

extension CaptureItem {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CaptureItem> {
        return NSFetchRequest<CaptureItem>(entityName: "CaptureItem")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var imageData: Data?
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var width: Int32
    @NSManaged public var height: Int32
    @NSManaged public var fileSize: Int64
    @NSManaged public var annotations: NSSet?
    
}

extension CaptureItem : Identifiable {
    
}

extension CaptureItem {
    
    @objc(addAnnotationsObject:)
    @NSManaged public func addToAnnotations(_ value: Annotation)
    
    @objc(removeAnnotationsObject:)
    @NSManaged public func removeFromAnnotations(_ value: Annotation)
    
    @objc(addAnnotations:)
    @NSManaged public func addToAnnotations(_ values: NSSet)
    
    @objc(removeAnnotations:)
    @NSManaged public func removeFromAnnotations(_ values: NSSet)
    
}