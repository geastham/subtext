# Phase 1: Foundation & Data Layer

**Duration:** Weeks 1-2  
**Status:** 🚀 Ready to Start

## Goals

Build the foundational architecture for Subtext, including:
- Project structure and setup
- Core data models with SwiftData
- Secure local storage with encryption
- Basic app navigation and settings
- Privacy controls and data deletion

## Key Deliverables

- ✅ Xcode project configured for iOS 26+
- ✅ SwiftData schema implemented
- ✅ Core navigation structure (TabView, NavigationStack)
- ✅ Settings screen with privacy controls
- ✅ Secure storage with encryption
- ✅ Delete all data functionality

## Technical Architecture

### 1. Project Setup

**Xcode Configuration:**
```swift
// Target: iOS 26.0+
// Swift: 6.0+
// Frameworks: SwiftUI, SwiftData, Foundation Models
```

**Project Structure:**
```
Subtext/
├── SubtextApp.swift              # App entry point
├── Models/
│   ├── ConversationThread.swift
│   ├── Message.swift
│   ├── CoachingSession.swift
│   └── Intent.swift
├── Services/
│   ├── DataStore.swift           # SwiftData wrapper
│   └── SecurityService.swift     # Encryption
├── Views/
│   ├── MainTabView.swift
│   ├── ConversationList.swift
│   ├── Settings.swift
│   └── Components/
│       └── EmptyState.swift
├── ViewModels/
│   ├── ConversationListViewModel.swift
│   └── SettingsViewModel.swift
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

### 2. Data Models

#### ConversationThread Model

```swift
import SwiftData
import Foundation

@Model
final class ConversationThread {
    @Attribute(.unique) var id: UUID
    var title: String
    var participants: [String]  // ["Me", "Sarah", etc.]
    var createdAt: Date
    var updatedAt: Date
    var messageCount: Int
    
    @Relationship(deleteRule: .cascade) var messages: [Message]
    @Relationship(deleteRule: .cascade) var coachingSessions: [CoachingSession]
    
    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        participants: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messageCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.participants = participants
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messageCount = messageCount
    }
}
```

#### Message Model

```swift
import SwiftData
import Foundation

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var text: String
    var sender: String  // "me" or participant name
    var timestamp: Date
    var isFromUser: Bool
    var conversationThread: ConversationThread?
    
    init(
        id: UUID = UUID(),
        text: String,
        sender: String,
        timestamp: Date = Date(),
        isFromUser: Bool = false
    ) {
        self.id = id
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
        self.isFromUser = isFromUser
    }
}
```

#### CoachingSession Model

```swift
import SwiftData
import Foundation

enum CoachingIntent: String, Codable, CaseIterable {
    case reply = "Reply"
    case interpret = "Interpret"
    case boundary = "Set Boundary"
    case flirt = "Flirt"
    case conflict = "Resolve Conflict"
}

@Model
final class CoachingSession {
    @Attribute(.unique) var id: UUID
    var intent: CoachingIntent
    var contextMessages: [String]  // Message IDs for context
    var replies: [CoachingReply]
    var riskFlags: [RiskFlag]
    var createdAt: Date
    var conversationThread: ConversationThread?
    
    init(
        id: UUID = UUID(),
        intent: CoachingIntent,
        contextMessages: [String] = [],
        replies: [CoachingReply] = [],
        riskFlags: [RiskFlag] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.intent = intent
        self.contextMessages = contextMessages
        self.replies = replies
        self.riskFlags = riskFlags
        self.createdAt = createdAt
    }
}

struct CoachingReply: Codable {
    let text: String
    let rationale: String
    let tone: String  // "casual", "direct", "warm"
}

struct RiskFlag: Codable {
    let type: RiskType
    let severity: RiskSeverity
    let description: String
    let evidence: [String]  // Message excerpts
    
    enum RiskType: String, Codable {
        case manipulation
        case gaslighting
        case pressuring
        case toxicity
        case redFlag
    }
    
    enum RiskSeverity: String, Codable {
        case low
        case medium
        case high
    }
}
```

### 3. Data Store Service

```swift
import SwiftData
import SwiftUI

@Observable
final class DataStore {
    var modelContainer: ModelContainer
    var modelContext: ModelContext
    
    static let shared = DataStore()
    
    private init() {
        let schema = Schema([
            ConversationThread.self,
            Message.self,
            CoachingSession.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    func save() throws {
        try modelContext.save()
    }
    
    func deleteAll() throws {
        // Delete all conversations (cascade will handle messages & sessions)
        try modelContext.delete(model: ConversationThread.self)
        try save()
    }
}
```

### 4. Security Service

```swift
import CryptoKit
import Foundation

actor SecurityService {
    static let shared = SecurityService()
    
    private init() {}
    
    // Encrypt sensitive text (conversation content)
    func encrypt(_ text: String) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let data = Data(text.utf8)
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined ?? Data()
    }
    
    // Decrypt sensitive text
    func decrypt(_ data: Data) throws -> String {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8) ?? ""
    }
    
    // Store encryption key in Keychain
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "SubtextEncryptionKey",
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
        
        if status == errSecSuccess {
            guard let keyData = item as? Data else {
                throw SecurityError.invalidKeyData
            }
            return SymmetricKey(data: keyData)
        } else {
            // Create new key
            let key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }
            
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "SubtextEncryptionKey",
                kSecValueData as String: keyData
            ]
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw SecurityError.keychainError
            }
            
            return key
        }
    }
    
    enum SecurityError: Error {
        case invalidKeyData
        case keychainError
    }
}
```

### 5. Main App Entry Point

```swift
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
```

### 6. Navigation Structure

```swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ConversationListView()
            }
            .tabItem {
                Label("Conversations", systemImage: "message.fill")
            }
            .tag(0)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(1)
        }
    }
}
```

### 7. Settings View

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAlert = false
    @State private var showDeleteSuccess = false
    
    var body: some View {
        List {
            Section("Privacy") {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("On-Device Only")
                            .font(.headline)
                        Text("Your conversations never leave your iPhone")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label("Privacy Policy", systemImage: "doc.text")
                }
            }
            
            Section("Data Management") {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete All Data", systemImage: "trash.fill")
                        .foregroundColor(.red)
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0 (MVP)")
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://subtext.app")!) {
                    Label("Website", systemImage: "globe")
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
        do {
            try DataStore.shared.deleteAll()
            showDeleteSuccess = true
        } catch {
            print("Error deleting data: \(error)")
        }
    }
}
```

### 8. Conversation List (Placeholder)

```swift
import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Query(sort: \ConversationThread.updatedAt, order: .reverse)
    private var conversations: [ConversationThread]
    
    var body: some View {
        Group {
            if conversations.isEmpty {
                EmptyStateView()
            } else {
                List(conversations) { conversation in
                    NavigationLink(value: conversation) {
                        ConversationRowView(conversation: conversation)
                    }
                }
            }
        }
        .navigationTitle("Conversations")
        .navigationDestination(for: ConversationThread.self) { conversation in
            Text("Conversation Detail - Coming in Phase 2")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Add conversation - Phase 2
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Conversations Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap + to import your first conversation")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ConversationRowView: View {
    let conversation: ConversationThread
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
            
            Text("\(conversation.messageCount) messages")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(conversation.updatedAt, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
```

## Implementation Tasks

### Week 1: Setup & Models

#### Day 1-2: Project Setup
- [ ] Create new Xcode project (iOS 26+, SwiftUI)
- [ ] Configure project settings (bundle ID, team, capabilities)
- [ ] Add Foundation Models framework (when available)
- [ ] Set up folder structure
- [ ] Create .gitignore and initialize git repo

#### Day 3-4: Data Models
- [ ] Implement `ConversationThread` model
- [ ] Implement `Message` model
- [ ] Implement `CoachingSession` model
- [ ] Create supporting structs (`CoachingReply`, `RiskFlag`)
- [ ] Test model persistence with sample data

#### Day 5: Data Store
- [ ] Implement `DataStore` singleton
- [ ] Set up SwiftData schema and container
- [ ] Create CRUD helper methods
- [ ] Implement delete all functionality
- [ ] Write unit tests for data operations

### Week 2: Security & Navigation

#### Day 1-2: Security Service
- [ ] Implement `SecurityService` actor
- [ ] Add AES-GCM encryption methods
- [ ] Implement Keychain storage for encryption key
- [ ] Test encryption/decryption round-trip
- [ ] Write security unit tests

#### Day 3-4: Navigation & Settings
- [ ] Create `MainTabView` with TabView
- [ ] Build `ConversationListView` (empty state)
- [ ] Implement `SettingsView` with all sections
- [ ] Add privacy policy view (placeholder)
- [ ] Test delete all data flow

#### Day 5: Polish & Documentation
- [ ] Add app icons (placeholder)
- [ ] Configure launch screen
- [ ] Add localization support (English only for MVP)
- [ ] Write README for Phase 1
- [ ] Code review and refactoring

## Validation Criteria

### Functional Requirements
- ✅ App launches without crashing
- ✅ Can create and persist `ConversationThread` objects
- ✅ Can navigate between Conversations and Settings tabs
- ✅ Settings screen displays all sections
- ✅ Delete all data clears SwiftData store
- ✅ Encryption key is stored securely in Keychain

### Performance Requirements
- ✅ App launch time < 2 seconds
- ✅ SwiftData operations complete in < 100ms
- ✅ No memory leaks or crashes

### Security Requirements
- ✅ Encryption key never exposed in logs
- ✅ Data is encrypted at rest (verified via debugger)
- ✅ Keychain access works on device and simulator

## Testing Strategy

### Unit Tests
```swift
// DataStoreTests.swift
func testCreateConversation() throws {
    let conversation = ConversationThread(title: "Test")
    // Test persistence
}

func testDeleteAll() throws {
    // Create test data
    // Delete all
    // Verify empty
}

// SecurityServiceTests.swift
func testEncryptDecryptRoundTrip() async throws {
    let original = "Sensitive message"
    let encrypted = try await SecurityService.shared.encrypt(original)
    let decrypted = try await SecurityService.shared.decrypt(encrypted)
    XCTAssertEqual(original, decrypted)
}
```

### Manual Testing Checklist
- [ ] Launch app on simulator (iOS 26+)
- [ ] Launch app on physical device (iPhone 15+)
- [ ] Navigate between tabs
- [ ] Trigger delete all data
- [ ] Verify data is cleared
- [ ] Force quit and relaunch
- [ ] Check for crashes in Console.app

## Risks & Mitigations

### Risk: SwiftData Instability
**Likelihood:** Low  
**Impact:** High  
**Mitigation:**
- Test extensively on beta OS versions
- Have Core Data fallback ready
- Join Apple Developer Forums for issues

### Risk: Foundation Models Not Available
**Likelihood:** Low  
**Impact:** High  
**Mitigation:**
- Phase 1 doesn't require Foundation Models
- Proceed with architecture
- Have Core ML backup plan

### Risk: Performance Issues
**Likelihood:** Low  
**Impact:** Medium  
**Mitigation:**
- Profile early with Instruments
- Optimize SwiftData queries
- Test on older devices (iPhone 15)

## Handoff to Phase 2

### Deliverables
- ✅ Working Xcode project
- ✅ All data models implemented and tested
- ✅ Secure storage operational
- ✅ Basic navigation functional
- ✅ Settings screen complete

### Ready for Phase 2 When:
1. All functional requirements validated
2. Unit tests passing (>80% coverage)
3. Manual testing checklist complete
4. No critical bugs
5. Code reviewed and documented

### Next Phase Preview
**Phase 2** will build on this foundation to add:
- Conversation import UI
- Text parsing for multiple formats
- Speaker labeling
- Message display views

---

**Estimated Effort:** 80 hours (1 full-time engineer, 2 weeks)  
**Dependencies:** iOS 26 SDK, Xcode 15+  
**Blockers:** None (foundation work)

