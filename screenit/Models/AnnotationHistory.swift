import Foundation
import SwiftUI

// MARK: - Annotation History Manager

@MainActor
class AnnotationHistory: ObservableObject {
    @Published private(set) var annotations: [Annotation] = []
    
    // MARK: - Public Properties
    
    var annotationCount: Int {
        annotations.count
    }
    
    // MARK: - Direct Manipulation Methods (for UndoRedoSystem)
    
    func addAnnotation(_ annotation: Annotation) {
        annotations.append(annotation)
    }
    
    func removeAnnotation(_ annotationId: UUID) {
        annotations.removeAll { $0.id == annotationId }
    }
    
    func modifyAnnotation(_ annotationId: UUID, newAnnotation: Annotation) {
        if let index = annotations.firstIndex(where: { $0.id == annotationId }) {
            annotations[index] = newAnnotation
        }
    }
    
    func clearAllAnnotations() {
        annotations.removeAll()
    }
    
    // MARK: - Query Methods
    
    func getAnnotation(by id: UUID) -> Annotation? {
        return annotations.first { $0.id == id }
    }
    
    func getAnnotations(of type: AnnotationType) -> [Annotation] {
        return annotations.filter { $0.type == type }
    }
    
    func getAnnotations(in rect: CGRect) -> [Annotation] {
        return annotations.filter { annotation in
            annotation.geometry.bounds.intersects(rect)
        }
    }
    
    func getAnnotationsAtPoint(_ point: CGPoint) -> [Annotation] {
        return annotations.filter { annotation in
            annotation.geometry.bounds.contains(point)
        }
    }
    
    // MARK: - State Management
    
    func reset() {
        annotations.removeAll()
    }
    
    func setAnnotations(_ newAnnotations: [Annotation]) {
        // This method bypasses the undo/redo system for loading saved state
        annotations = newAnnotations
    }
    
}