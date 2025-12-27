//
//  MainTabView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 1: Foundation & Data Layer
//  Updated: Phase 4 - Safety & Polish
//

import SwiftUI

struct MainTabView: View {
    let networkMonitor = NetworkMonitor.shared

    var body: some View {
        VStack(spacing: 0) {
            // Offline banner at top
            if !networkMonitor.isConnected {
                OfflineBannerView()
                    .padding(.vertical, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            TabView {
                NavigationStack {
                    ConversationListView()
                }
                .tabItem {
                    Label("Conversations", systemImage: "message.fill")
                }

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }
}

#Preview {
    MainTabView()
        .modelContainer(DataStore.shared.modelContainer)
}
