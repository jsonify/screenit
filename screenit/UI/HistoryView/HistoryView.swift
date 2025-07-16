//
//  HistoryView.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedItem: CaptureItem?
    
    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Capture History")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Clear All") {
                        dataManager.deleteAllCaptureItems()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                
                if dataManager.captureItems.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No captures yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Use Cmd+Shift+4 to capture your first screenshot")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(dataManager.captureItems, id: \.id) { item in
                                CaptureItemView(item: item, dataManager: dataManager)
                                    .onTapGesture {
                                        selectedItem = item
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(item: $selectedItem) { item in
            CaptureDetailView(item: item, dataManager: dataManager)
        }
    }
}

struct CaptureItemView: View {
    let item: CaptureItem
    let dataManager: DataManager
    
    @State private var thumbnail: NSImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
            }
            .frame(height: 120)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(item.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(item.width) × \(item.height)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(formatFileSize(item.fileSize))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button(action: { copyToClipboard() }) {
                    Image(systemName: "doc.on.clipboard")
                }
                .buttonStyle(.borderless)
                .help("Copy to clipboard")
                
                Spacer()
                
                Button(action: { deleteItem() }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .help("Delete")
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        if let thumbnailData = item.thumbnailData {
            thumbnail = NSImage(data: thumbnailData)
        } else if let imageData = item.imageData {
            thumbnail = NSImage(data: imageData)
        }
    }
    
    private func copyToClipboard() {
        dataManager.copyToClipboard(item)
    }
    
    private func deleteItem() {
        dataManager.deleteCaptureItem(item)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct CaptureDetailView: View {
    let item: CaptureItem
    let dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            if let imageData = item.imageData,
               let image = NSImage(data: imageData) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 800, maxHeight: 600)
            }
            
            HStack {
                Button("Copy") {
                    dataManager.copyToClipboard(item)
                    dismiss()
                }
                
                Button("Save As...") {
                    saveAs()
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
        }
        .padding()
    }
    
    private func saveAs() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .jpeg]
        savePanel.nameFieldStringValue = "Screenshot \(formatDate(item.timestamp))"
        
        if savePanel.runModal() == .OK,
           let url = savePanel.url {
            _ = dataManager.exportCaptureItem(item, to: url)
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return formatter.string(from: date)
    }
}