import SwiftUI
import OSLog

/// SwiftUI view component displaying a single capture item as a thumbnail card
struct CaptureItemView: View {
    
    // MARK: - Properties
    
    let captureItem: CaptureItem
    @State private var thumbnailImage: NSImage?
    @State private var isHovered = false
    
    private let logger = Logger(subsystem: "com.screenit.app", category: "CaptureItemView")
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail Image
            thumbnailContainer
            
            // Metadata Overlay
            metadataOverlay
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            loadThumbnail()
        }
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Subviews
    
    private var thumbnailContainer: some View {
        Group {
            if let thumbnailImage = thumbnailImage {
                Image(nsImage: thumbnailImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 150, maxHeight: 150)
                    .clipped()
            } else {
                // Placeholder while loading
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(NSColor.quaternaryLabelColor))
                    .frame(width: 150, height: 100)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
        }
        .frame(minHeight: 100)
    }
    
    private var metadataOverlay: some View {
        VStack(spacing: 4) {
            // Dimensions
            Text(captureItem.formattedDimensions)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Timestamp
            Text(captureItem.formattedTimestamp)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            
            // File size
            Text(captureItem.formattedFileSize)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
    
    // MARK: - Accessibility
    
    private var accessibilityDescription: String {
        var description = "Screenshot captured at \(captureItem.formattedTimestamp)"
        description += ", dimensions \(captureItem.formattedDimensions)"
        description += ", file size \(captureItem.formattedFileSize)"
        
        if let annotations = captureItem.annotations, annotations.count > 0 {
            description += ", \(annotations.count) annotation\(annotations.count == 1 ? "" : "s")"
        }
        
        return description
    }
    
    // MARK: - Methods
    
    private func loadThumbnail() {
        // Load thumbnail from Core Data
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = captureItem.thumbnailImage
            
            DispatchQueue.main.async {
                self.thumbnailImage = thumbnail
                
                if thumbnail == nil {
                    logger.warning("Failed to load thumbnail for capture item \(captureItem.id?.uuidString ?? "unknown")")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Single Item") {
    let previewItem = CaptureItem.createPreviewItem()
    
    return CaptureItemView(captureItem: previewItem)
        .frame(width: 180, height: 200)
        .padding()
}

#Preview("Multiple Items") {
    let previewItems = (1...6).map { _ in CaptureItem.createPreviewItem() }
    
    return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
        ForEach(previewItems, id: \.id) { item in
            CaptureItemView(captureItem: item)
        }
    }
    .padding()
}

// MARK: - Preview Helpers

extension CaptureItem {
    static func createPreviewItem() -> CaptureItem {
        let context = PersistenceManager.shared.viewContext
        let item = CaptureItem(context: context)
        
        item.id = UUID()
        item.timestamp = Date().addingTimeInterval(-Double.random(in: 0...86400)) // Random time in last day
        item.width = Int32.random(in: 800...2560)
        item.height = Int32.random(in: 600...1440)
        item.fileSize = Int64.random(in: 100000...5000000) // 100KB to 5MB
        
        // Create a simple thumbnail image for preview
        let thumbnailSize = CGSize(width: 150, height: 100)
        let thumbnail = NSImage(size: thumbnailSize)
        thumbnail.lockFocus()
        
        // Draw a gradient background
        let gradient = NSGradient(colors: [
            NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
            NSColor(red: 0.8, green: 0.2, blue: 0.4, alpha: 1.0)
        ])
        gradient?.draw(in: NSRect(origin: .zero, size: thumbnailSize), angle: 45)
        
        thumbnail.unlockFocus()
        
        if let thumbnailData = thumbnail.tiffRepresentation {
            item.thumbnailData = thumbnailData
        }
        
        return item
    }
}