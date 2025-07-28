import SwiftUI
import CoreData
import OSLog

/// SwiftUI view displaying a grid of capture history items with management capabilities
struct HistoryGridView: View {
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Core Data Fetch
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CaptureItem.timestamp, ascending: false)],
        animation: .default
    )
    private var captureItems: FetchedResults<CaptureItem>
    
    // MARK: - State
    
    @State private var selectedItems = Set<CaptureItem>()
    @State private var showingDeleteConfirmation = false
    @State private var isRefreshing = false
    
    // MARK: - Grid Configuration
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]
    
    private let logger = Logger(subsystem: "com.screenit.app", category: "HistoryGridView")
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                if captureItems.isEmpty {
                    emptyStateView
                } else {
                    gridContent
                }
            }
            .navigationTitle("Capture History")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if !selectedItems.isEmpty {
                        Button("Delete Selected", action: deleteSelectedItems)
                            .foregroundColor(.red)
                    }
                    
                    Button("Refresh", action: refreshHistory)
                        .disabled(isRefreshing)
                }
            }
            .refreshable {
                await refreshHistoryAsync()
            }
        }
        .confirmationDialog(
            "Delete \(selectedItems.count) item\(selectedItems.count == 1 ? "" : "s")?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                performDeletion()
            }
            Button("Cancel", role: .cancel) {
                selectedItems.removeAll()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Screenshots Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Screenshots you capture will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var gridContent: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(captureItems, id: \.id) { captureItem in
                CaptureItemView(captureItem: captureItem)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleItemTap(captureItem)
                    }
                    .contextMenu {
                        contextMenuContent(for: captureItem)
                    }
                    .overlay(
                        // Selection indicator
                        selectedItems.contains(captureItem) ?
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 3)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor.opacity(0.1))
                            )
                        : nil
                    )
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func contextMenuContent(for captureItem: CaptureItem) -> some View {
        Button("Copy to Clipboard") {
            copyToClipboard(captureItem)
        }
        
        Button("Export...") {
            exportCaptureItem(captureItem)
        }
        
        Divider()
        
        Button("Delete", role: .destructive) {
            deleteCaptureItem(captureItem)
        }
    }
    
    // MARK: - Actions
    
    private func handleItemTap(_ captureItem: CaptureItem) {
        if selectedItems.contains(captureItem) {
            selectedItems.remove(captureItem)
        } else {
            selectedItems.insert(captureItem)
        }
    }
    
    private func copyToClipboard(_ captureItem: CaptureItem) {
        guard let image = captureItem.image else {
            logger.error("Failed to load image for clipboard copy")
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        
        logger.info("Copied capture item to clipboard: \(captureItem.id?.uuidString ?? "unknown")")
    }
    
    private func exportCaptureItem(_ captureItem: CaptureItem) {
        guard let image = captureItem.image else {
            logger.error("Failed to load image for export")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "Screenshot \(captureItem.formattedTimestamp).png"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                if let imageData = image.pngData {
                    try imageData.write(to: url)
                    logger.info("Exported capture item to: \(url.path)")
                }
            } catch {
                logger.error("Failed to export capture item: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteCaptureItem(_ captureItem: CaptureItem) {
        withAnimation {
            viewContext.delete(captureItem)
            
            do {
                try viewContext.save()
                logger.info("Deleted capture item: \(captureItem.id?.uuidString ?? "unknown")")
            } catch {
                logger.error("Failed to delete capture item: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteSelectedItems() {
        guard !selectedItems.isEmpty else { return }
        showingDeleteConfirmation = true
    }
    
    private func performDeletion() {
        withAnimation {
            for item in selectedItems {
                viewContext.delete(item)
            }
            
            do {
                try viewContext.save()
                logger.info("Deleted \(selectedItems.count) capture items")
                selectedItems.removeAll()
            } catch {
                logger.error("Failed to delete selected items: \(error.localizedDescription)")
            }
        }
    }
    
    private func refreshHistory() {
        isRefreshing = true
        
        // Refresh the Core Data context
        viewContext.refreshAllObjects()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isRefreshing = false
        }
        
        logger.debug("Refreshed capture history")
    }
    
    private func refreshHistoryAsync() async {
        await MainActor.run {
            refreshHistory()
        }
        
        // Wait for the refresh animation
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}

// MARK: - Preview

#Preview("With Content") {
    let context = PersistenceManager.shared.viewContext
    
    // Create sample data for preview
    for i in 1...8 {
        let item = CaptureItem.createPreviewItem()
        item.timestamp = Date().addingTimeInterval(-Double(i * 3600)) // Hourly intervals
    }
    
    return HistoryGridView()
        .environment(\.managedObjectContext, context)
        .frame(width: 800, height: 600)
}

#Preview("Empty State") {
    let context = PersistenceManager.shared.viewContext
    
    return HistoryGridView()
        .environment(\.managedObjectContext, context)
        .frame(width: 800, height: 600)
}

// MARK: - NSImage Extension

private extension NSImage {
    var pngData: Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmap.representation(using: .png, properties: [:])
    }
}