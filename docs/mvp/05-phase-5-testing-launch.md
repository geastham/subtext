# Phase 5: Testing & Launch

**Duration:** Week 8  
**Status:** ⏳ Pending Phase 4 Completion

## Goals

Comprehensive testing, App Store preparation, and beta launch:
- Write comprehensive test suite
- App Store assets and listing
- TestFlight setup and distribution
- Internal testing with 25 users
- Fix showstopper bugs
- Prepare for public launch

## Key Deliverables

- ✅ Unit tests (>70% coverage for critical code)
- ✅ Integration tests (end-to-end flows)
- ✅ UI tests (critical user paths)
- ✅ App Store listing complete
- ✅ TestFlight build uploaded
- ✅ 25 beta testers onboarded
- ✅ Feedback collection system
- ✅ Launch-ready app

## Testing Strategy

### 1. Unit Tests

**Target Coverage:** >70% for business logic, 100% for safety

```swift
// MARK: - Parser Tests

final class ConversationParserTests: XCTestCase {
    func testDetectIMessageFormat() async {
        let sample = "[12/25/24, 10:30:45] Sarah: Hey there!"
        let format = await ConversationParser.shared.detectFormat(sample)
        XCTAssertEqual(format, .iMessage)
    }
    
    func testParseIMessageConversation() async throws {
        let sample = """
        [12/25/24, 10:30:45] Sarah: Hey!
        [12/25/24, 10:31:22] John: Hi Sarah!
        [12/25/24, 10:32:10] Sarah: How are you?
        """
        
        let parsed = try await ConversationParser.shared.parse(sample)
        
        XCTAssertEqual(parsed.format, .iMessage)
        XCTAssertEqual(parsed.messages.count, 3)
        XCTAssertEqual(parsed.participants.count, 2)
        XCTAssertTrue(parsed.participants.contains("Sarah"))
        XCTAssertTrue(parsed.participants.contains("John"))
    }
    
    func testParseWhatsAppConversation() async throws {
        let sample = """
        12/25/24, 10:30 - Sarah: Hey!
        12/25/24, 10:31 - John: Hi!
        """
        
        let parsed = try await ConversationParser.shared.parse(sample)
        XCTAssertEqual(parsed.format, .whatsApp)
        XCTAssertEqual(parsed.messages.count, 2)
    }
    
    func testParseEmptyText() async {
        do {
            _ = try await ConversationParser.shared.parse("")
            XCTFail("Should throw error for empty text")
        } catch ConversationParser.ParserError.emptyText {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testParseWithEmoji() async throws {
        let sample = "[12/25/24, 10:30:45] Sarah: Hey! 😊👋"
        let parsed = try await ConversationParser.shared.parse(sample)
        XCTAssertEqual(parsed.messages.first?.text, "Hey! 😊👋")
    }
}

// MARK: - Safety Tests

final class SafetyClassifierTests: XCTestCase {
    func testDetectViolentLanguage() async throws {
        let messages = [
            Message(text: "I'll hurt you if you don't listen", sender: "Them", isFromUser: false)
        ]
        
        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)
        
        XCTAssertFalse(analysis.flags.isEmpty)
        XCTAssertTrue(analysis.flags.contains { $0.type == .violence })
        XCTAssertEqual(analysis.overallRisk, .high)
    }
    
    func testDetectManipulation() async throws {
        let messages = [
            Message(text: "If you loved me, you would do this", sender: "Them", isFromUser: false)
        ]
        
        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)
        
        XCTAssertTrue(analysis.flags.contains { $0.type == .manipulation })
    }
    
    func testDetectGaslighting() async throws {
        let messages = [
            Message(text: "You're overreacting, that never happened", sender: "Them", isFromUser: false)
        ]
        
        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)
        
        XCTAssertTrue(analysis.flags.contains { $0.type == .gaslighting })
    }
    
    func testHealthyConversationNoFlags() async throws {
        let messages = [
            Message(text: "Hey, how was your day?", sender: "Them", isFromUser: false),
            Message(text: "Pretty good, thanks for asking!", sender: "Me", isFromUser: true)
        ]
        
        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)
        
        XCTAssertTrue(analysis.flags.isEmpty)
        XCTAssertEqual(analysis.overallRisk, .none)
    }
}

// MARK: - Data Model Tests

final class DataStoreTests: XCTestCase {
    var dataStore: DataStore!
    
    override func setUp() {
        super.setUp()
        dataStore = DataStore.shared
    }
    
    func testCreateConversation() throws {
        let conversation = ConversationThread(
            title: "Test Conversation",
            participants: ["Me", "Sarah"],
            messageCount: 0
        )
        
        dataStore.modelContext.insert(conversation)
        try dataStore.save()
        
        // Verify it was saved
        let descriptor = FetchDescriptor<ConversationThread>()
        let conversations = try dataStore.modelContext.fetch(descriptor)
        XCTAssertTrue(conversations.contains { $0.id == conversation.id })
    }
    
    func testCreateMessage() throws {
        let conversation = ConversationThread(title: "Test")
        dataStore.modelContext.insert(conversation)
        
        let message = Message(
            text: "Hello",
            sender: "Me",
            isFromUser: true
        )
        message.conversationThread = conversation
        dataStore.modelContext.insert(message)
        
        try dataStore.save()
        
        // Verify relationship
        XCTAssertEqual(conversation.messages.count, 1)
        XCTAssertEqual(conversation.messages.first?.text, "Hello")
    }
    
    func testDeleteAll() throws {
        // Create test data
        let conversation = ConversationThread(title: "Test")
        dataStore.modelContext.insert(conversation)
        try dataStore.save()
        
        // Delete all
        try dataStore.deleteAll()
        
        // Verify empty
        let descriptor = FetchDescriptor<ConversationThread>()
        let conversations = try dataStore.modelContext.fetch(descriptor)
        XCTAssertTrue(conversations.isEmpty)
    }
}

// MARK: - Prompt Tests

final class PromptBuilderTests: XCTestCase {
    func testPromptContainsIntent() {
        let messages = [
            Message(text: "Hey", sender: "Them", isFromUser: false)
        ]
        
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )
        
        XCTAssertTrue(prompt.contains("INTENT"))
        XCTAssertTrue(prompt.contains("Reply"))
    }
    
    func testPromptContainsConversationContext() {
        let messages = [
            Message(text: "Hey", sender: "Sarah", isFromUser: false),
            Message(text: "Hi", sender: "Me", isFromUser: true)
        ]
        
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )
        
        XCTAssertTrue(prompt.contains("[Sarah]: Hey"))
        XCTAssertTrue(prompt.contains("[Me]: Hi"))
    }
    
    func testPromptContainsOutputSchema() {
        let messages = [Message(text: "Hey", sender: "Them", isFromUser: false)]
        
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )
        
        XCTAssertTrue(prompt.contains("OUTPUT FORMAT"))
        XCTAssertTrue(prompt.contains("JSON"))
    }
}
```

### 2. Integration Tests

```swift
final class IntegrationTests: XCTestCase {
    func testCompleteImportFlow() async throws {
        // 1. Parse conversation
        let sample = "[12/25/24, 10:30:45] Sarah: Hey!"
        let parsed = try await ConversationParser.shared.parse(sample)
        
        // 2. Save to data store
        let dataStore = DataStore.shared
        let conversation = ConversationThread(
            title: "Test",
            participants: Array(parsed.participants),
            messageCount: parsed.messages.count
        )
        dataStore.modelContext.insert(conversation)
        
        for msg in parsed.messages {
            let message = Message(
                text: msg.text,
                sender: msg.sender ?? "Unknown",
                timestamp: msg.timestamp ?? Date(),
                isFromUser: msg.isFromUser
            )
            message.conversationThread = conversation
            dataStore.modelContext.insert(message)
        }
        
        try dataStore.save()
        
        // 3. Verify saved correctly
        let descriptor = FetchDescriptor<ConversationThread>()
        let conversations = try dataStore.modelContext.fetch(descriptor)
        XCTAssertEqual(conversations.count, 1)
        XCTAssertEqual(conversations.first?.messages.count, 1)
    }
    
    func testCompleteCoachingFlow() async throws {
        // 1. Create conversation with messages
        let dataStore = DataStore.shared
        let conversation = ConversationThread(title: "Test")
        dataStore.modelContext.insert(conversation)
        
        let message = Message(text: "How are you?", sender: "Them", isFromUser: false)
        message.conversationThread = conversation
        dataStore.modelContext.insert(message)
        
        try dataStore.save()
        
        // 2. Generate coaching
        let messages = [message]
        let coaching = try await LLMClient.shared.generateCoaching(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )
        
        // 3. Verify response structure
        XCTAssertFalse(coaching.summary.isEmpty)
        XCTAssertEqual(coaching.replies.count, 3)
        XCTAssertFalse(coaching.replies[0].text.isEmpty)
        XCTAssertFalse(coaching.replies[0].rationale.isEmpty)
    }
}
```

### 3. UI Tests

```swift
final class SubtextUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testImportConversation() {
        // Tap import button
        app.buttons["add"].tap()
        
        // Paste conversation
        let textView = app.textViews.firstMatch
        textView.tap()
        textView.typeText("[12/25/24, 10:30:45] Sarah: Hey!")
        
        // Parse
        app.buttons["Parse Conversation"].tap()
        
        // Wait for success
        XCTAssertTrue(app.staticTexts["Conversation Parsed!"].waitForExistence(timeout: 5))
        
        // Label speakers
        app.buttons["Label Speakers"].tap()
        
        // Save
        app.buttons["Save Conversation"].tap()
        
        // Verify in list
        XCTAssertTrue(app.staticTexts["Conversation on"].exists)
    }
    
    func testCoachingFlow() {
        // Create test conversation first (via app.launchArguments for test data)
        app.launchArguments = ["--uitesting", "--testdata"]
        app.launch()
        
        // Open conversation
        app.cells.firstMatch.tap()
        
        // Get coaching
        app.buttons["Get Coaching"].tap()
        
        // Select intent
        app.buttons["Reply"].tap()
        
        // Generate
        app.buttons["Generate Coaching"].tap()
        
        // Wait for results
        XCTAssertTrue(app.staticTexts["Situation Analysis"].waitForExistence(timeout: 15))
        
        // Verify replies
        XCTAssertTrue(app.buttons["Copy Reply"].exists)
        
        // Copy a reply
        app.buttons["Copy Reply"].firstMatch.tap()
        XCTAssertTrue(app.alerts["Copied!"].waitForExistence(timeout: 2))
    }
    
    func testDeleteAllData() {
        // Go to settings
        app.tabBars.buttons["Settings"].tap()
        
        // Delete all data
        app.buttons["Delete All Data"].tap()
        
        // Confirm alert
        app.alerts.buttons["Delete"].tap()
        
        // Verify success
        XCTAssertTrue(app.alerts["Data Deleted"].waitForExistence(timeout: 2))
    }
}
```

## App Store Preparation

### 1. App Store Listing

**App Name:**  
Subtext - Conversation Coach

**Subtitle:**  
Private AI coach for better conversations

**Description:**
```
Subtext is your private AI conversation coach for dating and relationships.

✨ GET BETTER AT TEXTING
• Get 3 reply options with clear explanations
• Understand what they really mean
• Navigate tricky situations confidently

🔒 100% PRIVATE
• All AI processing happens on your iPhone
• Your conversations never leave your device
• No cloud storage, no data collection

💙 BUILT FOR YOUR SAFETY
• Detects manipulation and red flags
• Provides support resources when needed
• Non-judgmental, empowering advice

🎯 5 CORE INTENTS
• Reply: Craft the perfect response
• Interpret: Understand their message
• Boundary: Set healthy limits
• Flirt: Be playful and confident
• Conflict: Navigate disagreements

Perfect for:
• Dating app conversations
• New relationships
• Tricky situations
• Learning to communicate better

Subtext uses Apple's on-device AI (requires iOS 26+). Your privacy is our priority - we literally can't see your conversations.

---

Terms: subtext.app/terms
Privacy: subtext.app/privacy
```

**Keywords:**
```
dating, relationships, texting, conversation, AI coach, dating coach, 
relationship advice, communication, privacy, on-device, Apple Intelligence
```

**Category:**  
Primary: Lifestyle  
Secondary: Social Networking

**Age Rating:**  
17+ (Mature/Suggestive Themes)

### 2. App Store Assets

**App Icon:**
- 1024x1024px icon (required)
- Design: Clean, modern, purple/blue gradient
- Symbol: Chat bubble + sparkle (coaching)

**Screenshots (iPhone 15 Pro Max):**

1. **Hero Shot**: Coaching results view with 3 replies
   - Caption: "Get 3 thoughtful reply options in seconds"

2. **Safety Shot**: Risk flag banner with support resources
   - Caption: "Built-in safety detection and support"

3. **Privacy Shot**: Settings screen highlighting on-device processing
   - Caption: "100% private. Your data never leaves your iPhone."

4. **Import Shot**: Paste conversation screen
   - Caption: "Import conversations from any app"

5. **Intent Shot**: Intent selection grid
   - Caption: "Choose what you need help with"

**App Preview Video (30 seconds):**
- 0-5s: Problem (staring at phone, don't know what to say)
- 5-10s: Solution (open Subtext, paste conversation)
- 10-20s: Demo (select intent, get coaching, see replies)
- 20-25s: Privacy emphasis (on-device badge)
- 25-30s: CTA (Download Subtext)

### 3. Privacy Nutrition Label

**Data Not Collected:**
- No data collected (all on-device)

**Data Used to Track You:**
- None

**Data Linked to You:**
- None

**Data Not Linked to You:**
- None

**Privacy Practices:**
- Data is encrypted on device
- You can request data deletion (via app settings)
- No data is shared with third parties
- No data leaves device

### 4. TestFlight Setup

**Build Configuration:**
```swift
// Version: 1.0.0
// Build: 1
// Minimum iOS: 26.0
```

**TestFlight Information:**
```
What to Test:
- Import conversations from various sources
- Generate coaching for all 5 intents
- Verify response quality and relevance
- Test safety detection with concerning messages
- Check performance on your device
- Report any bugs or crashes

Please provide feedback on:
1. How useful were the coaching suggestions? (1-5)
2. Did the app feel private and secure?
3. Were there any bugs or confusing moments?
4. What features would you like to see added?

Thank you for testing Subtext! Your feedback will help us build a better product.
```

**Beta Tester Criteria:**
- 25 close friends/family members
- Mix of:
  - Active daters (15)
  - Relationship coaches/therapists (3)
  - iOS developers (4)
  - Privacy advocates (3)
- iPhone 15 or newer
- Willing to provide detailed feedback

## Implementation Tasks

### Day 1-2: Unit Tests
- [ ] Write parser tests (15+ test cases)
- [ ] Write safety classifier tests (20+ test cases)
- [ ] Write data model tests (10+ test cases)
- [ ] Write prompt builder tests (5+ test cases)
- [ ] Achieve >70% coverage

### Day 3: Integration & UI Tests
- [ ] Write integration tests (3+ flows)
- [ ] Write UI tests (3+ critical paths)
- [ ] Set up UI testing infrastructure
- [ ] Create test fixtures and mock data

### Day 4: App Store Preparation
- [ ] Design app icon
- [ ] Take screenshots
- [ ] Record app preview video
- [ ] Write App Store description
- [ ] Complete Privacy Nutrition Label
- [ ] Create promotional assets

### Day 5: TestFlight & Beta Launch
- [ ] Build and upload to TestFlight
- [ ] Set up beta testing groups
- [ ] Send invites to 25 testers
- [ ] Create feedback form (Google Form / Typeform)
- [ ] Monitor crash reports
- [ ] Collect and triage feedback

## Beta Testing Plan

### Week 1: Internal Testing (Days 1-3)
- **Testers:** 10 close friends
- **Focus:** Critical bugs, UX issues
- **Feedback:** Daily check-ins via Discord

### Week 2: Expanded Beta (Days 4-7)
- **Testers:** Additional 15 users
- **Focus:** Real-world usage, coaching quality
- **Feedback:** End-of-week survey

### Success Metrics for Beta
- [ ] <5 critical bugs reported
- [ ] 4.0+ / 5.0 average satisfaction
- [ ] 50%+ D7 retention
- [ ] 70%+ complete first coaching session

### Feedback Collection

**In-App Feedback:**
- Thumbs up/down on each reply
- Optional written feedback on coaching quality
- Bug report button (sends diagnostics)

**Survey Questions:**
1. How would you rate the overall experience? (1-5)
2. How useful were the coaching suggestions? (1-5)
3. Did you feel your privacy was protected? (Yes/No)
4. Did you encounter any bugs? (Describe)
5. What features would you most like to see added?
6. Would you recommend Subtext to a friend? (1-10 NPS)

## Launch Readiness Checklist

### Technical
- [ ] All tests passing (unit, integration, UI)
- [ ] No critical bugs
- [ ] Performance targets met
- [ ] Crash rate <0.1%
- [ ] Memory usage acceptable
- [ ] Battery impact <5%/hour

### App Store
- [ ] App Store listing complete
- [ ] Screenshots uploaded
- [ ] App preview video uploaded
- [ ] Privacy label accurate
- [ ] App icon final
- [ ] Metadata localized (English)

### TestFlight
- [ ] Build uploaded and processed
- [ ] 25 testers invited
- [ ] Feedback form live
- [ ] Discord/Slack channel created
- [ ] Daily monitoring schedule set

### Business
- [ ] Landing page live (subtext.app)
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] Support email set up (support@subtext.app)
- [ ] Press kit ready (for public launch)

## Risk Mitigation

### Risk: Critical Bug Found in Beta
**Likelihood:** Medium  
**Impact:** High  
**Mitigation:**
- Daily monitoring of crash reports
- Fast-track hotfix process
- Clear communication with testers
- Delay public launch if necessary

### Risk: Low Beta Retention
**Likelihood:** Low  
**Impact:** Medium  
**Mitigation:**
- Deep-dive interviews with churned users
- Rapid iteration on feedback
- A/B test onboarding improvements
- Pivot messaging if value prop unclear

### Risk: App Store Rejection
**Likelihood:** Low  
**Impact:** High  
**Mitigation:**
- Follow all App Store guidelines strictly
- Clear privacy labeling
- Mature content warning (17+)
- Detailed rejection response plan

## Handoff to Public Launch

### Ready for Public Launch When:
1. ✅ Beta testing complete (2 weeks)
2. ✅ Critical bugs fixed
3. ✅ 4.0+ / 5.0 satisfaction
4. ✅ 50%+ D7 retention
5. ✅ App Store listing approved
6. ✅ Landing page live
7. ✅ Press materials ready

### Launch Day Checklist
- [ ] Submit for App Store review (10 days before launch)
- [ ] Coordinate launch with iOS 26 release
- [ ] Prepare Product Hunt post
- [ ] Line up press coverage
- [ ] Social media posts scheduled
- [ ] Support inbox monitored
- [ ] Celebrate! 🎉

---

**Estimated Effort:** 40 hours (1 full-time engineer, 1 week)  
**Dependencies:** Phase 4 complete, iOS 26 public beta available  
**Blockers:** None

**Next:** [Post-Launch Roadmap](./06-post-launch-roadmap.md)

