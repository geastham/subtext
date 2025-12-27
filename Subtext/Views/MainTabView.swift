//
//  MainTabView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 1: Foundation & Data Layer
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
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
}

#Preview {
    MainTabView()
        .modelContainer(DataStore.shared.modelContainer)
}
