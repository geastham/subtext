//
//  SettingsView.swift
//  Subtext - Phase 1
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("requiresAuthentication") private var requiresAuthentication = false
    @AppStorage("enableAnalytics") private var enableAnalytics = false
    
    @State private var showDeleteAlert = false
    @State private var showDeleteSuccess = false
    @State private var isDeleting = false
    
    var body: some View {
        List {
            Section("Privacy") {
                Toggle(isOn: $requiresAuthentication) {
                    VStack(alignment: .leading) {
                        Text("Require Authentication")
                        Text("Use Face ID or passcode to access app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Analytics") {
                Toggle(isOn: $enableAnalytics) {
                    VStack(alignment: .leading) {
                        Text("Usage Analytics")
                        Text("Help improve Subtext with anonymous usage data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Data Management") {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    if isDeleting {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Deleting...")
                        }
                    } else {
                        Label("Delete All Data", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                }
                .disabled(isDeleting)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0 (MVP Phase 1)")
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://github.com/geastham/subtext")!) {
                    Label("GitHub Repository", systemImage: "link")
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Delete All Data?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all your conversations and cannot be undone.")
        }
        .alert("Data Deleted", isPresented: $showDeleteSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All your data has been permanently deleted.")
        }
    }
    
    private func deleteAllData() {
        isDeleting = true
        
        Task {
            do {
                try DataStore.shared.deleteAll()
                try await SecurityService.shared.deleteEncryptionKey()
                
                await MainActor.run {
                    requiresAuthentication = false
                    enableAnalytics = false
                    isDeleting = false
                    showDeleteSuccess = true
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                }
                print("Error deleting data: \(error)")
            }
        }
    }
}
