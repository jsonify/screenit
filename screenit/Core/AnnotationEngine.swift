import Foundation
import SwiftUI
import Combine

// MARK: - Annotation Engine

@MainActor
class AnnotationEngine: ObservableObject {
    // MARK: - Published Properties
    
    @Published var toolState: AnnotationToolState
    @Published var history: AnnotationHistory
    @Published var undoRedoManager: UndoRedoManager
    @Published private(set) var selectedTool: AnnotationTool?
    @Published private(set) var isAnnotating: Bool = false
    
    // MARK: - Private Properties
    
    private var registeredTools: [AnnotationType: AnnotationTool] = [:]
    private var currentSession: AnnotationSession?
    
    // MARK: - Computed Properties
    
    var annotations: [Annotation] {
        history.annotations
    }
    
    var canUndo: Bool {
        undoRedoManager.canUndo
    }
    
    var canRedo: Bool {
        undoRedoManager.canRedo
    }
    
    // MARK: - Initialization
    
    init() {
        self.toolState = AnnotationToolState()
        self.history = AnnotationHistory()
        self.undoRedoManager = UndoRedoManager()
        
        // Register all available tools
        registerDefaultTools()
        
        // Set up tool state observation
        setupToolStateObservation()
    }
    
    // MARK: - Tool Registration
    
    func registerTool(_ tool: AnnotationTool) {
        registeredTools[tool.type] = tool
    }
    
    func getTool(for type: AnnotationType) -> AnnotationTool? {
        return registeredTools[type]
    }
    
    private func registerDefaultTools() {
        let tools = AnnotationToolFactory.createAllTools()
        registeredTools = tools
    }
    
    // MARK: - Tool Selection
    
    func selectTool(_ type: AnnotationType) {
        // Deactivate current tool
        selectedTool?.deactivate()
        
        // Select new tool
        selectedTool = registeredTools[type]
        selectedTool?.activate()
        
        // Update tool state
        toolState.selectTool(type)
        
        // Configure tool with current state
        selectedTool?.configure(with: toolState)
    }
    
    func deselectTool() {
        selectedTool?.deactivate()
        selectedTool = nil
    }
    
    // MARK: - Canvas Event Handling
    
    func handleCanvasEvent(_ event: CanvasEvent) {
        guard let tool = selectedTool else { return }
        
        switch event {
        case .drawStart(let point):
            tool.handleDrawStart(point, state: toolState)
            
        case .drawUpdate(let point):
            tool.handleDrawUpdate(point, state: toolState)
            
        case .drawEnd(let point):
            if let annotation = tool.handleDrawEnd(point, state: toolState) {
                addAnnotation(annotation)
            }
        }
    }
    
    // MARK: - Annotation Management
    
    func addAnnotation(_ annotation: Annotation) {
        let command = AddAnnotationCommand(annotation: annotation, engine: self)
        undoRedoManager.execute(command)
    }
    
    func removeAnnotation(_ annotationId: UUID) {
        guard let annotation = history.annotations.first(where: { $0.id == annotationId }) else { return }
        let command = RemoveAnnotationCommand(annotation: annotation, engine: self)
        undoRedoManager.execute(command)
    }
    
    func updateAnnotation(_ annotationId: UUID, with newAnnotation: Annotation) {
        guard let oldAnnotation = history.annotations.first(where: { $0.id == annotationId }) else { return }
        let command = ModifyAnnotationCommand(
            annotationId: annotationId,
            oldAnnotation: oldAnnotation, 
            newAnnotation: newAnnotation,
            engine: self
        )
        undoRedoManager.execute(command)
    }
    
    func clearAnnotations() {
        let command = ClearAllAnnotationsCommand(previousAnnotations: history.annotations, engine: self)
        undoRedoManager.execute(command)
    }
    
    // Direct manipulation methods for undo/redo system
    internal func directAddAnnotation(_ annotation: Annotation) {
        history.addAnnotation(annotation)
    }
    
    internal func directRemoveAnnotation(_ annotationId: UUID) {
        history.removeAnnotation(annotationId)
    }
    
    internal func directClearAnnotations() {
        history.clearAllAnnotations()
    }
    
    // MARK: - Undo/Redo
    
    func undo() -> Bool {
        undoRedoManager.undo()
        return true
    }
    
    func redo() -> Bool {
        undoRedoManager.redo()
        return true
    }
    
    // MARK: - Session Management
    
    func startAnnotationSession(for imageSize: CGSize) {
        currentSession = AnnotationSession(imageSize: imageSize)
        isAnnotating = true
    }
    
    func endAnnotationSession() -> [Annotation] {
        let annotations = self.annotations
        currentSession = nil
        isAnnotating = false
        return annotations
    }
    
    func cancelAnnotationSession() {
        reset()
        currentSession = nil
        isAnnotating = false
    }
    
    // MARK: - Hit Testing
    
    func getAnnotationsAtPoint(_ point: CGPoint) -> [Annotation] {
        return history.getAnnotationsAtPoint(point)
    }
    
    func getAnnotations(in rect: CGRect) -> [Annotation] {
        return history.getAnnotations(in: rect)
    }
    
    // MARK: - State Management
    
    func reset() {
        deselectTool()
        history.reset()
        toolState.reset()
    }
    
    func setAnnotations(_ annotations: [Annotation]) {
        history.setAnnotations(annotations)
    }
    
    // MARK: - Configuration
    
    private func setupToolStateObservation() {
        // Update selected tool when tool state changes
        _ = toolState.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.selectedTool?.configure(with: self?.toolState ?? AnnotationToolState())
            }
        }
    }
    
    // MARK: - Keyboard Shortcuts
    
    func handleKeyboardShortcut(_ key: String) -> Bool {
        switch key.lowercased() {
        case "a":
            selectTool(.arrow)
            return true
        case "t":
            selectTool(.text)
            return true
        case "r":
            selectTool(.rectangle)
            return true
        case "h":
            selectTool(.highlight)
            return true
        case "b":
            selectTool(.blur)
            return true
        case "z":
            if NSEvent.modifierFlags.contains(.command) {
                if NSEvent.modifierFlags.contains(.shift) {
                    return redo()
                } else {
                    return undo()
                }
            }
        case "escape":
            deselectTool()
            return true
        default:
            return false
        }
        return false
    }
}

// MARK: - Annotation Session

struct AnnotationSession {
    let id: UUID = UUID()
    let imageSize: CGSize
    let startTime: Date = Date()
    
    init(imageSize: CGSize) {
        self.imageSize = imageSize
    }
}