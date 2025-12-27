# Phase 2: Conversation Management

**Duration:** Weeks 3-4  
**Status:** ⏳ Pending Phase 1 Completion

## Goals

Build the conversation import, parsing, and display functionality:
- Import conversations via paste or manual entry
- Parse multiple text formats (iMessage, WhatsApp, plain text)
- Label speakers accurately ("Who's who?")
- Display conversations with proper threading
- Edit and trim conversations

## Key Deliverables

- ✅ Conversation import UI with paste functionality
- ✅ Multi-format text parser (iMessage, WhatsApp, manual)
- ✅ Speaker labeling flow
- ✅ Conversation detail view with message bubbles
- ✅ Edit/trim conversation functionality
- ✅ Conversation metadata (title, participants)

## Technical Architecture

### 1. Conversation Parser Service

```swift
import Foundation

enum ConversationFormat: String {
    case iMessage
    case whatsApp
    case telegram
    case manual
    case unknown
}

struct ParsedConversation {
    let format: ConversationFormat
    let messages: [ParsedMessage]
    let participants: Set<String>
    let detectedAt: Date
}

struct ParsedMessage {
    let text: String
    let sender: String?  // Nil if unknown
    let timestamp: Date?
    let isFromUser: Bool
}

actor ConversationParser {
    static let shared = ConversationParser()
    
    // Detect format from raw text
    func detectFormat(_ text: String) -> ConversationFormat {
        // iMessage: "[Date, Time] Contact Name: Message"
        if text.contains(regex: #"\[\d{1,2}/\d{1,2}/\d{2,4}, \d{1,2}:\d{2}:\d{2}\]"#) {
            return .iMessage
        }
        
        // WhatsApp: "MM/DD/YY, HH:MM - Contact Name: Message"
        if text.contains(regex: #"\d{1,2}/\d{1,2}/\d{2,4}, \d{1,2}:\d{2}\s*-\s*.*:"#) {
            return .whatsApp
        }
        
        // Telegram: "[HH:MM, DD.MM.YYYY] Contact Name:"
        if text.contains(regex: #"\[\d{2}:\d{2}, \d{2}\.\d{2}\.\d{4}\]"#) {
            return .telegram
        }
        
        // Check for generic patterns
        if text.contains(":") && text.split(separator: "\n").count > 1 {
            return .manual
        }
        
        return .unknown
    }
    
    // Parse conversation based on detected format
    func parse(_ text: String) throws -> ParsedConversation {
        let format = detectFormat(text)
        
        let messages: [ParsedMessage]
        
        switch format {
        case .iMessage:
            messages = try parseIMessage(text)
        case .whatsApp:
            messages = try parseWhatsApp(text)
        case .telegram:
            messages = try parseTelegram(text)
        case .manual:
            messages = try parseManual(text)
        case .unknown:
            throw ParserError.unknownFormat
        }
        
        let participants = Set(messages.compactMap { $0.sender })
        
        return ParsedConversation(
            format: format,
            messages: messages,
            participants: participants,
            detectedAt: Date()
        )
    }
    
    // MARK: - Format-Specific Parsers
    
    private func parseIMessage(_ text: String) throws -> [ParsedMessage] {
        // Regex: [Date, Time] Contact Name: Message
        let pattern = #"\[([^\]]+)\] ([^:]+): (.*)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        return matches.compactMap { match in
            guard match.numberOfRanges == 4 else { return nil }
            
            let dateStr = nsText.substring(with: match.range(at: 1))
            let sender = nsText.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
            let message = nsText.substring(with: match.range(at: 3))
            
            let timestamp = parseDate(dateStr, format: "MM/dd/yy, HH:mm:ss")
            
            return ParsedMessage(
                text: message,
                sender: sender,
                timestamp: timestamp,
                isFromUser: false  // Will be determined in labeling phase
            )
        }
    }
    
    private func parseWhatsApp(_ text: String) throws -> [ParsedMessage] {
        // Regex: MM/DD/YY, HH:MM - Contact Name: Message
        let pattern = #"(\d{1,2}/\d{1,2}/\d{2,4}, \d{1,2}:\d{2})\s*-\s*([^:]+):\s*(.*)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        return matches.compactMap { match in
            guard match.numberOfRanges == 4 else { return nil }
            
            let dateStr = nsText.substring(with: match.range(at: 1))
            let sender = nsText.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
            let message = nsText.substring(with: match.range(at: 3))
            
            let timestamp = parseDate(dateStr, format: "MM/dd/yy, HH:mm")
            
            return ParsedMessage(
                text: message,
                sender: sender,
                timestamp: timestamp,
                isFromUser: false
            )
        }
    }
    
    private func parseTelegram(_ text: String) throws -> [ParsedMessage] {
        // Regex: [HH:MM, DD.MM.YYYY] Contact Name: Message
        let pattern = #"\[(\d{2}:\d{2}, \d{2}\.\d{2}\.\d{4})\] ([^:]+):\s*(.*)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        return matches.compactMap { match in
            guard match.numberOfRanges == 4 else { return nil }
            
            let dateStr = nsText.substring(with: match.range(at: 1))
            let sender = nsText.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
            let message = nsText.substring(with: match.range(at: 3))
            
            let timestamp = parseDate(dateStr, format: "HH:mm, dd.MM.yyyy")
            
            return ParsedMessage(
                text: message,
                sender: sender,
                timestamp: timestamp,
                isFromUser: false
            )
        }
    }
    
    private func parseManual(_ text: String) throws -> [ParsedMessage] {
        // Simple format: "Name: Message" per line
        let lines = text.components(separatedBy: .newlines)
        
        return lines.enumerated().compactMap { index, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            
            // Try to split on first colon
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let sender = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let message = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                
                return ParsedMessage(
                    text: message,
                    sender: sender.isEmpty ? "Unknown" : sender,
                    timestamp: nil,
                    isFromUser: false
                )
            } else {
                // No colon, treat whole line as message from previous sender
                return ParsedMessage(
                    text: trimmed,
                    sender: nil,
                    timestamp: nil,
                    isFromUser: false
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    private func parseDate(_ dateString: String, format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: dateString)
    }
    
    enum ParserError: Error {
        case unknownFormat
        case invalidFormat
        case emptyText
    }
}

extension String {
    func contains(regex pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(self.startIndex..., in: self)
        return regex.firstMatch(in: self, range: range) != nil
    }
}
```

### 2. Import Flow Views

#### Conversation Import View

```swift
import SwiftUI

struct ConversationImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var pastedText = ""
    @State private var parsedConversation: ParsedConversation?
    @State private var isParsing = false
    @State private var parseError: Error?
    @State private var showingSpeakerLabeling = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if parsedConversation == nil {
                    pasteView
                } else {
                    parseSuccessView
                }
            }
            .padding()
            .navigationTitle("Import Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingSpeakerLabeling) {
                if let parsed = parsedConversation {
                    SpeakerLabelingView(
                        parsedConversation: parsed,
                        onComplete: { labeled in
                            saveConversation(labeled)
                        }
                    )
                }
            }
        }
    }
    
    private var pasteView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Paste Your Conversation")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Copy messages from iMessage, WhatsApp, or any text app")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TextEditor(text: $pastedText)
                .frame(height: 200)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            if let error = parseError {
                Text("Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button {
                parseConversation()
            } label: {
                if isParsing {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text("Parse Conversation")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(pastedText.trimmingCharacters(in: .whitespaces).isEmpty || isParsing)
            
            Spacer()
        }
    }
    
    private var parseSuccessView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Conversation Parsed!")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let parsed = parsedConversation {
                VStack(spacing: 12) {
                    InfoRow(label: "Format", value: parsed.format.rawValue)
                    InfoRow(label: "Messages", value: "\(parsed.messages.count)")
                    InfoRow(label: "Participants", value: "\(parsed.participants.count)")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Button("Label Speakers") {
                showingSpeakerLabeling = true
            }
            .buttonStyle(.borderedProminent)
            
            Button("Start Over") {
                parsedConversation = nil
                pastedText = ""
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
    }
    
    private func parseConversation() {
        isParsing = true
        parseError = nil
        
        Task {
            do {
                let parsed = try await ConversationParser.shared.parse(pastedText)
                await MainActor.run {
                    parsedConversation = parsed
                    isParsing = false
                }
            } catch {
                await MainActor.run {
                    parseError = error
                    isParsing = false
                }
            }
        }
    }
    
    private func saveConversation(_ labeled: LabeledConversation) {
        // Create ConversationThread
        let thread = ConversationThread(
            title: labeled.title,
            participants: labeled.participants,
            messageCount: labeled.messages.count
        )
        
        modelContext.insert(thread)
        
        // Create Messages
        for msg in labeled.messages {
            let message = Message(
                text: msg.text,
                sender: msg.sender,
                timestamp: msg.timestamp ?? Date(),
                isFromUser: msg.isFromUser
            )
            message.conversationThread = thread
            modelContext.insert(message)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
```

#### Speaker Labeling View

```swift
import SwiftUI

struct LabeledMessage {
    let text: String
    let sender: String
    let timestamp: Date?
    let isFromUser: Bool
}

struct LabeledConversation {
    let title: String
    let participants: [String]
    let messages: [LabeledMessage]
}

struct SpeakerLabelingView: View {
    @Environment(\.dismiss) private var dismiss
    
    let parsedConversation: ParsedConversation
    let onComplete: (LabeledConversation) -> Void
    
    @State private var speakerMapping: [String: String] = [:]
    @State private var conversationTitle = ""
    @State private var userSpeakerName = ""
    
    private var allSpeakers: [String] {
        Array(parsedConversation.participants).sorted()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Conversation Title") {
                    TextField("e.g., Chat with Sarah", text: $conversationTitle)
                }
                
                Section("Who are you in this conversation?") {
                    Picker("Your name", selection: $userSpeakerName) {
                        Text("Select...").tag("")
                        ForEach(allSpeakers, id: \.self) { speaker in
                            Text(speaker).tag(speaker)
                        }
                    }
                }
                
                Section("Other Participants") {
                    ForEach(allSpeakers.filter { $0 != userSpeakerName }, id: \.self) { speaker in
                        HStack {
                            Text(speaker)
                            Spacer()
                            TextField("Display name", text: binding(for: speaker))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                Section {
                    Button("Save Conversation") {
                        saveLabels()
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Label Speakers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                // Pre-fill with detected names
                conversationTitle = "Conversation on \(Date().formatted(date: .abbreviated, time: .omitted))"
                for speaker in allSpeakers {
                    speakerMapping[speaker] = speaker
                }
            }
        }
    }
    
    private var isValid: Bool {
        !conversationTitle.isEmpty && !userSpeakerName.isEmpty
    }
    
    private func binding(for speaker: String) -> Binding<String> {
        Binding(
            get: { speakerMapping[speaker] ?? speaker },
            set: { speakerMapping[speaker] = $0 }
        )
    }
    
    private func saveLabels() {
        let labeledMessages = parsedConversation.messages.map { msg in
            let originalSender = msg.sender ?? "Unknown"
            let displayName = speakerMapping[originalSender] ?? originalSender
            let isUser = originalSender == userSpeakerName
            
            return LabeledMessage(
                text: msg.text,
                sender: isUser ? "Me" : displayName,
                timestamp: msg.timestamp,
                isFromUser: isUser
            )
        }
        
        let participants = Array(Set(speakerMapping.values)).filter { $0 != userSpeakerName }
        
        let labeled = LabeledConversation(
            title: conversationTitle,
            participants: ["Me"] + participants,
            messages: labeledMessages
        )
        
        onComplete(labeled)
        dismiss()
    }
}
```

### 3. Conversation Detail View

```swift
import SwiftUI
import SwiftData

struct ConversationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let conversation: ConversationThread
    
    @Query private var messages: [Message]
    @State private var showingCoaching = false
    
    init(conversation: ConversationThread) {
        self.conversation = conversation
        
        // Query messages for this conversation
        let threadID = conversation.id
        _messages = Query(
            filter: #Predicate<Message> { message in
                message.conversationThread?.id == threadID
            },
            sort: \Message.timestamp
        )
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(messages) { message in
                    MessageBubbleView(message: message)
                }
            }
            .padding()
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCoaching = true
                } label: {
                    Label("Get Coaching", systemImage: "sparkles")
                }
            }
        }
        .sheet(isPresented: $showingCoaching) {
            Text("Coaching View - Coming in Phase 3")
        }
    }
}

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.sender)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
}
```

## Implementation Tasks

### Week 3: Parser & Import

#### Day 1-2: Conversation Parser
- [ ] Implement `ConversationParser` actor
- [ ] Add format detection logic
- [ ] Implement iMessage parser
- [ ] Implement WhatsApp parser
- [ ] Implement Telegram parser
- [ ] Implement manual/plain text parser
- [ ] Write parser unit tests (>90% coverage)

#### Day 3: Import UI
- [ ] Create `ConversationImportView`
- [ ] Build paste input interface
- [ ] Add format detection feedback
- [ ] Implement parse success view
- [ ] Add error handling and user feedback

#### Day 4-5: Speaker Labeling
- [ ] Create `SpeakerLabelingView`
- [ ] Implement participant mapping UI
- [ ] Add "Who are you?" selection
- [ ] Create display name editing
- [ ] Test labeling with various conversations

### Week 4: Display & Polish

#### Day 1-2: Conversation Detail
- [ ] Build `ConversationDetailView`
- [ ] Implement `MessageBubbleView` component
- [ ] Add proper message threading
- [ ] Implement scrolling and performance optimization
- [ ] Add timestamp formatting

#### Day 3: Conversation List Updates
- [ ] Update `ConversationListView` with real data
- [ ] Add swipe-to-delete functionality
- [ ] Implement search/filter (basic)
- [ ] Add conversation sorting options
- [ ] Show last message preview

#### Day 4: Edit & Trim
- [ ] Add edit conversation functionality
- [ ] Implement message deletion
- [ ] Add trim conversation (remove messages)
- [ ] Update conversation title
- [ ] Edit participant names

#### Day 5: Testing & Polish
- [ ] End-to-end testing of import flow
- [ ] Test with various real conversations
- [ ] Performance testing (large conversations)
- [ ] UI polish and refinements
- [ ] Fix bugs and edge cases

## Validation Criteria

### Functional Requirements
- ✅ Can paste conversations from clipboard
- ✅ Parser correctly identifies format (>95% accuracy)
- ✅ iMessage format parsed correctly
- ✅ WhatsApp format parsed correctly
- ✅ Manual format handled gracefully
- ✅ Speaker labeling flow is intuitive
- ✅ Messages display with correct attribution
- ✅ Timestamps are accurate (when available)
- ✅ Can edit conversation metadata
- ✅ Can delete individual messages

### User Experience Requirements
- ✅ Import flow < 5 taps from start to saved conversation
- ✅ Parser provides clear feedback on detected format
- ✅ Error messages are helpful and actionable
- ✅ Message display is readable and iOS-native
- ✅ Scrolling performance is smooth (60fps)

### Data Integrity Requirements
- ✅ No message data loss during parsing
- ✅ Timestamps preserved (when available)
- ✅ Speaker attribution is consistent
- ✅ Edited conversations save correctly
- ✅ Deleted messages are removed from storage

## Testing Strategy

### Unit Tests
```swift
// ConversationParserTests.swift
func testDetectIMessageFormat() async throws {
    let sample = "[12/25/24, 10:30:45] Sarah: Hey there!"
    let format = await ConversationParser.shared.detectFormat(sample)
    XCTAssertEqual(format, .iMessage)
}

func testParseWhatsAppConversation() async throws {
    let sample = """
    12/25/24, 10:30 - Sarah: Hey!
    12/25/24, 10:31 - John: Hi Sarah!
    """
    let parsed = try await ConversationParser.shared.parse(sample)
    XCTAssertEqual(parsed.messages.count, 2)
    XCTAssertEqual(parsed.participants.count, 2)
}

func testParseEmptyText() async {
    do {
        _ = try await ConversationParser.shared.parse("")
        XCTFail("Should throw error")
    } catch {
        XCTAssertTrue(error is ConversationParser.ParserError)
    }
}
```

### Integration Tests
- [ ] Test complete import flow (paste → parse → label → save)
- [ ] Test conversation display with various message counts
- [ ] Test edit and delete operations
- [ ] Test data persistence across app restarts

### Manual Testing Checklist
- [ ] Import real iMessage conversation
- [ ] Import real WhatsApp conversation
- [ ] Import manually typed conversation
- [ ] Test with 100+ message conversation
- [ ] Test with emoji and special characters
- [ ] Test with very long messages (>1000 chars)
- [ ] Test speaker labeling with 3+ participants
- [ ] Verify message bubbles display correctly
- [ ] Test scroll performance
- [ ] Test on iPhone SE (small screen)

## Risks & Mitigations

### Risk: Parser Can't Handle All Format Variations
**Likelihood:** Medium  
**Impact:** Medium  
**Mitigation:**
- Focus on most common formats first
- Allow manual correction in UI
- Collect user feedback on parsing failures
- Iterate parser based on real-world data

### Risk: Large Conversations Cause Performance Issues
**Likelihood:** Low  
**Impact:** Medium  
**Mitigation:**
- Use LazyVStack for message display
- Paginate very large conversations
- Profile with Instruments early
- Set reasonable limits (e.g., 1000 messages)

### Risk: Users Struggle with Speaker Labeling
**Likelihood:** Low  
**Impact:** Low  
**Mitigation:**
- Provide clear onboarding
- Auto-detect "Me" when possible
- Allow editing after save
- Add helpful tips in UI

## Handoff to Phase 3

### Deliverables
- ✅ Working conversation import flow
- ✅ Multi-format parser operational
- ✅ Speaker labeling functional
- ✅ Conversation detail view complete
- ✅ Edit/trim functionality working

### Ready for Phase 3 When:
1. Can import and display conversations
2. Parser handles 3+ formats accurately
3. UI is polished and intuitive
4. Performance is acceptable (<3s for 100 messages)
5. All tests passing (>85% coverage)
6. No critical bugs

### Next Phase Preview
**Phase 3** will integrate AI coaching:
- Foundation Models integration
- Intent selection UI
- Prompt engineering
- Coaching results display
- Reply generation with rationales

---

**Estimated Effort:** 80 hours (1 full-time engineer, 2 weeks)  
**Dependencies:** Phase 1 complete, sample conversations for testing  
**Blockers:** None

