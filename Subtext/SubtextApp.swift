//
//  SubtextApp.swift
//  Subtext
//
//  Created by Codegen
//  Phase 1: Foundation & Data Layer
//

import SwiftUI
import SwiftData

@main
struct SubtextApp: App {
    let dataStore = DataStore.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(dataStore.modelContainer)
        }
    }
}

