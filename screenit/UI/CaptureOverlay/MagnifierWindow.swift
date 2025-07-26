import SwiftUI
import AppKit
import CoreGraphics

// MARK: - NSColor Safe Extensions

extension NSColor {
    /// Safely gets red component by converting to RGB colorspace if needed
    var safeRedComponent: CGFloat {
        return toRGBColorSpace().redComponent
    }
    
    /// Safely gets green component by converting to RGB colorspace if needed
    var safeGreenComponent: CGFloat {
        return toRGBColorSpace().greenComponent
    }
    
    /// Safely gets blue component by converting to RGB colorspace if needed
    var safeBlueComponent: CGFloat {
        return toRGBColorSpace().blueComponent
    }
    
    /// Safely gets alpha component by converting to RGB colorspace if needed
    var safeAlphaComponent: CGFloat {
        return toRGBColorSpace().alphaComponent
    }
    
    /// Converts NSColor to RGB colorspace to avoid crashes with Gray colorspace
    private func toRGBColorSpace() -> NSColor {
        // Get the current colorspace
        let colorSpace = self.colorSpace
        
        // Check if it's already in RGB-compatible space
        if colorSpace.colorSpaceModel == .rgb {
            return self
        }
        
        // Convert to RGB colorspace
        guard let rgbColor = self.usingColorSpace(.sRGB) else {
            // Fallback: try generic RGB
            return self.usingColorSpace(.genericRGB) ?? NSColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
        
        return rgbColor
    }
}

/// A floating magnifier window that follows the cursor during area selection
@MainActor
class MagnifierWindow: NSWindow {
    
    // MARK: - Properties
    
    private var magnifierView: MagnifierView
    private var isShowing: Bool = false
    private let magnificationFactor: CGFloat = 8.0
    private let magnifierSize: CGSize = CGSize(width: 150, height: 150)
    
    // MARK: - Initialization
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        
        self.magnifierView = MagnifierView(
            magnification: magnificationFactor,
            size: magnifierSize
        )
        
        super.init(
            contentRect: CGRect(origin: .zero, size: magnifierSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupMagnifierView()
    }
    
    convenience init() {
        self.init(
            contentRect: CGRect(origin: .zero, size: CGSize(width: 150, height: 150)),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
    }
    
    // MARK: - Window Setup
    
    private func setupWindow() {
        // Configure window for magnifier overlay
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)) + 1) // Above capture overlay
        self.ignoresMouseEvents = true // Allow mouse events to pass through
        self.acceptsMouseMovedEvents = false
        self.isMovableByWindowBackground = false
        self.canHide = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hasShadow = true
        
        print("MagnifierWindow configured with size: \(magnifierSize)")
    }
    
    private func setupMagnifierView() {
        let hostingController = NSHostingController(rootView: magnifierView)
        hostingController.view.frame = self.contentView?.bounds ?? self.frame
        
        // Configure hosting view
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Set as content view
        self.contentView = hostingController.view
        
        print("MagnifierView configured and added to window")
    }
    
    // MARK: - Public Interface
    
    /// Shows the magnifier window at the specified cursor position
    func showMagnifier(at cursorPosition: CGPoint) {
        updateMagnifierContent(at: cursorPosition)
        positionWindow(near: cursorPosition)
        
        if !isShowing {
            self.orderFront(nil)
            isShowing = true
        }
    }
    
    /// Hides the magnifier window
    func hideMagnifier() {
        if isShowing {
            self.orderOut(nil)
            isShowing = false
        }
    }
    
    /// Updates magnifier content for the specified cursor position
    func updateMagnifierContent(at cursorPosition: CGPoint) {
        // Capture screen area around cursor for magnification
        guard let screenImage = captureScreenArea(around: cursorPosition) else {
            print("Failed to capture screen area for magnifier")
            return
        }
        
        // Get pixel color at exact cursor position
        let pixelColor = getPixelColor(at: cursorPosition, from: screenImage)
        
        // Update magnifier view
        magnifierView.updateContent(
            cursorPosition: cursorPosition,
            screenImage: screenImage,
            pixelColor: pixelColor
        )
    }
    
    // MARK: - Private Methods
    
    /// Positions the magnifier window near the cursor, avoiding screen edges
    private func positionWindow(near cursorPosition: CGPoint) {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let windowSize = self.frame.size
        let offset: CGFloat = 20 // Distance from cursor
        
        var windowOrigin = CGPoint(
            x: cursorPosition.x + offset,
            y: cursorPosition.y - windowSize.height - offset
        )
        
        // Adjust if window would go off screen
        if windowOrigin.x + windowSize.width > screenFrame.maxX {
            windowOrigin.x = cursorPosition.x - windowSize.width - offset
        }
        
        if windowOrigin.y < screenFrame.minY {
            windowOrigin.y = cursorPosition.y + offset
        }
        
        // Ensure window stays within screen bounds
        windowOrigin.x = max(screenFrame.minX, min(windowOrigin.x, screenFrame.maxX - windowSize.width))
        windowOrigin.y = max(screenFrame.minY, min(windowOrigin.y, screenFrame.maxY - windowSize.height))
        
        self.setFrameOrigin(windowOrigin)
    }
    
    /// Captures a small screen area around the cursor for magnification
    private func captureScreenArea(around cursorPosition: CGPoint) -> CGImage? {
        // Capture area size (area to magnify)
        let captureSize: CGFloat = 20 // 20x20 pixel area around cursor
        let captureRect = CGRect(
            x: cursorPosition.x - captureSize / 2,
            y: cursorPosition.y - captureSize / 2,
            width: captureSize,
            height: captureSize
        )
        
        // Create screenshot of the area using CGWindowListCreateImage
        guard let screenImage = CGWindowListCreateImage(
            captureRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .nominalResolution
        ) else {
            print("Failed to capture screen area: \(captureRect)")
            return nil
        }
        
        return screenImage
    }
    
    /// Gets the RGB color of the pixel at the specified position
    private func getPixelColor(at position: CGPoint, from image: CGImage) -> NSColor {
        // Create a 1x1 pixel image at the cursor position
        let pixelRect = CGRect(x: position.x, y: position.y, width: 1, height: 1)
        
        guard let pixelImage = CGWindowListCreateImage(
            pixelRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .nominalResolution
        ) else {
            return NSColor.black
        }
        
        // Extract color from the 1x1 image
        return extractColorFromImage(pixelImage) ?? NSColor.black
    }
    
    /// Extracts the dominant color from a small image
    private func extractColorFromImage(_ image: CGImage) -> NSColor? {
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else {
            return nil
        }
        
        let bytesPerPixel = 4 // RGBA
        let red = CGFloat(ptr[0]) / 255.0
        let green = CGFloat(ptr[1]) / 255.0
        let blue = CGFloat(ptr[2]) / 255.0
        let alpha = CGFloat(ptr[3]) / 255.0
        
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// MARK: - Magnifier View

/// SwiftUI view that displays the magnified content with RGB information
struct MagnifierView: View {
    
    // MARK: - Properties
    
    private let magnification: CGFloat
    private let size: CGSize
    
    @State private var cursorPosition: CGPoint = .zero
    @State private var screenImage: CGImage?
    @State private var pixelColor: NSColor = .black
    
    // MARK: - Initialization
    
    init(magnification: CGFloat, size: CGSize) {
        self.magnification = magnification
        self.size = size
    }
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Magnified view area
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black)
                
                // Magnified screen content
                if let screenImage = screenImage {
                    Image(nsImage: NSImage(cgImage: screenImage, size: NSSize(width: screenImage.width, height: screenImage.height)))
                        .interpolation(.none) // Pixel-perfect scaling
                        .scaleEffect(magnification)
                        .clipped()
                }
                
                // Center crosshair
                CrosshairOverlay()
                
                // Border
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
            }
            .frame(width: size.width - 20, height: size.width - 50) // Square magnifier area
            
            // Information panel
            VStack(spacing: 2) {
                // Cursor coordinates
                Text("x: \(Int(cursorPosition.x)), y: \(Int(cursorPosition.y))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                // RGB values
                HStack(spacing: 8) {
                    ColorValueView(label: "R", value: Int(pixelColor.safeRedComponent * 255), color: .red)
                    ColorValueView(label: "G", value: Int(pixelColor.safeGreenComponent * 255), color: .green)
                    ColorValueView(label: "B", value: Int(pixelColor.safeBlueComponent * 255), color: .blue)
                }
                
                // Hex color
                Text(hexColor)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.8))
            )
        }
        .frame(width: size.width, height: size.height)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.9))
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Computed Properties
    
    private var hexColor: String {
        let red = Int(pixelColor.safeRedComponent * 255)
        let green = Int(pixelColor.safeGreenComponent * 255)
        let blue = Int(pixelColor.safeBlueComponent * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    // MARK: - Public Methods
    
    func updateContent(cursorPosition: CGPoint, screenImage: CGImage?, pixelColor: NSColor) {
        self.cursorPosition = cursorPosition
        self.screenImage = screenImage
        self.pixelColor = pixelColor
    }
}

// MARK: - Supporting Views

/// Crosshair overlay for the center of the magnifier
struct CrosshairOverlay: View {
    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(Color.red.opacity(0.8))
                .frame(height: 1)
            
            // Vertical line
            Rectangle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 1)
        }
        .allowsHitTesting(false)
    }
}

/// Individual color value display (R, G, or B)
struct ColorValueView: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview {
    MagnifierView(magnification: 8.0, size: CGSize(width: 150, height: 150))
        .frame(width: 150, height: 150)
        .background(Color.gray.opacity(0.3))
}