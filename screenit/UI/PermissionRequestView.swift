//
//  PermissionRequestView.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import SwiftUI
import AppKit

struct PermissionRequestView: View {
    let permissionError: CapturePermissionError?
    let onRetry: () async -> Void
    let onOpenSystemSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.shield")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)
                
                Text("Screen Recording Permission Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                if let error = permissionError {
                    Text(error.errorDescription ?? "Unknown error")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            VStack(spacing: 16) {
                Text("To capture screenshots, screenit needs permission to record your screen.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("1.")
                            .fontWeight(.semibold)
                        Text("Click \"Open System Settings\" below")
                    }
                    
                    HStack {
                        Text("2.")
                            .fontWeight(.semibold)
                        Text("Navigate to Privacy & Security → Screen Recording")
                    }
                    
                    HStack {
                        Text("3.")
                            .fontWeight(.semibold)
                        Text("Enable the toggle next to \"screenit\"")
                    }
                    
                    HStack {
                        Text("4.")
                            .fontWeight(.semibold)
                        Text("Click \"Try Again\" below")
                    }
                }
                .font(.callout)
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                Button("Open System Settings") {
                    onOpenSystemSettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Try Again") {
                    Task {
                        await onRetry()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            if permissionError?.recoverySuggestion != nil {
                Text(permissionError!.recoverySuggestion!)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(32)
        .frame(maxWidth: 500)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

struct PermissionStatusIndicator: View {
    let isGranted: Bool
    let error: CapturePermissionError?
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isGranted ? .green : .orange)
            
            Text(isGranted ? "Screen recording enabled" : "Screen recording required")
                .font(.caption)
                .foregroundColor(isGranted ? .green : .orange)
        }
    }
}

#Preview {
    PermissionRequestView(
        permissionError: .permissionDenied,
        onRetry: {},
        onOpenSystemSettings: {}
    )
}