//
//  PreferencesManager.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import Foundation
import SwiftUI

class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let globalHotkeysEnabled = "globalHotkeysEnabled"
        static let annotationColor = "annotationColor"
        static let annotationThickness = "annotationThickness"
        static let annotationFontSize = "annotationFontSize"
        static let selectedAnnotationTool = "selectedAnnotationTool"
    }
    
    // MARK: - Published Properties
    @Published var globalHotkeysEnabled: Bool {
        didSet {
            defaults.set(globalHotkeysEnabled, forKey: Keys.globalHotkeysEnabled)
        }
    }
    
    @Published var annotationColor: String {
        didSet {
            defaults.set(annotationColor, forKey: Keys.annotationColor)
        }
    }
    
    @Published var annotationThickness: Int {
        didSet {
            defaults.set(annotationThickness, forKey: Keys.annotationThickness)
        }
    }
    
    @Published var annotationFontSize: Int {
        didSet {
            defaults.set(annotationFontSize, forKey: Keys.annotationFontSize)
        }
    }
    
    @Published var selectedAnnotationTool: String {
        didSet {
            defaults.set(selectedAnnotationTool, forKey: Keys.selectedAnnotationTool)
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Load saved preferences or set defaults
        self.globalHotkeysEnabled = defaults.object(forKey: Keys.globalHotkeysEnabled) as? Bool ?? false
        self.annotationColor = defaults.string(forKey: Keys.annotationColor) ?? "#FF0000" // Red
        self.annotationThickness = defaults.object(forKey: Keys.annotationThickness) as? Int ?? 3
        self.annotationFontSize = defaults.object(forKey: Keys.annotationFontSize) as? Int ?? 16
        self.selectedAnnotationTool = defaults.string(forKey: Keys.selectedAnnotationTool) ?? "arrow"
    }
    
    // MARK: - Convenience Methods
    func resetToDefaults() {
        globalHotkeysEnabled = false
        annotationColor = "#FF0000"
        annotationThickness = 3
        annotationFontSize = 16
        selectedAnnotationTool = "arrow"
    }
    
    func getAnnotationToolType() -> AnnotationType {
        switch selectedAnnotationTool {
        case "arrow": return .arrow
        case "text": return .text
        case "rectangle": return .rectangle
        case "highlight": return .highlight
        case "blur": return .blur
        default: return .arrow
        }
    }
    
    func setAnnotationToolType(_ type: AnnotationType) {
        switch type {
        case .arrow: selectedAnnotationTool = "arrow"
        case .text: selectedAnnotationTool = "text"
        case .rectangle: selectedAnnotationTool = "rectangle"
        case .highlight: selectedAnnotationTool = "highlight"
        case .blur: selectedAnnotationTool = "blur"
        }
    }
    
    func getAnnotationColorAsColor() -> Color {
        return Color(hex: annotationColor)
    }
}