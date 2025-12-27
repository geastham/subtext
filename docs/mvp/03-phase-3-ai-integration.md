# Phase 3: AI Integration & Coaching

**Duration:** Weeks 5-6  
**Status:** ⏳ Pending Phase 2 Completion

## Goals

Integrate Apple's Foundation Models and build the core AI coaching functionality:
- Set up Foundation Models framework
- Implement prompt engineering system
- Build intent selection UI
- Generate structured coaching outputs (3 replies + rationales)
- Handle streaming responses
- Implement regeneration and refinement

## Key Deliverables

- ✅ Foundation Models integrated and operational
- ✅ LLM client abstraction layer
- ✅ Prompt template system with structured outputs
- ✅ Intent selection UI (5 core intents)
- ✅ Coaching results view with 3 reply options
- ✅ Regenerate functionality
- ✅ Copy-to-clipboard for replies
- ✅ Streaming support (if time permits)

## Technical Architecture

### 1. LLM Client Service

```swift
import Foundation
import FoundationModels  // Apple's on-device LLM framework

actor LLMClient {
    static let shared = LLMClient()
    
    private var model: LLMModel?
    
    private init() {
        Task {
            await initializeModel()
        }
    }
    
    // Initialize Foundation Models
    func initializeModel() async {
        do {
            // Load Apple's on-device model
            self.model = try await LLMModel.load(
                modelIdentifier: .appleLLM,  // Apple's identifier
                configuration: .init(
                    maxTokens: 2048,
                    temperature: 0.7,
                    topP: 0.9
                )
            )
        } catch {
            print("Failed to load model: \(error)")
        }
    }
    
    // Generate coaching with structured output
    func generateCoaching(
        conversation: [Message],
        intent: CoachingIntent,
        parameters: CoachingParameters = .default
    ) async throws -> CoachingResponse {
        guard let model = model else {
            throw LLMError.modelNotLoaded
        }
        
        // Build prompt
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: conversation,
            intent: intent,
            parameters: parameters
        )
        
        // Generate with structured output schema
        let response = try await model.generate(
            prompt: prompt,
            schema: CoachingResponse.schema,  // JSON schema enforcement
            maxTokens: 1500
        )
        
        // Parse JSON response
        let decoder = JSONDecoder()
        let coaching = try decoder.decode(CoachingResponse.self, from: response.data)
        
        return coaching
    }
    
    // Generate with streaming (optional enhancement)
    func generateCoachingStream(
        conversation: [Message],
        intent: CoachingIntent,
        parameters: CoachingParameters = .default,
        onToken: @escaping (String) -> Void
    ) async throws -> CoachingResponse {
        guard let model = model else {
            throw LLMError.modelNotLoaded
        }
        
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: conversation,
            intent: intent,
            parameters: parameters
        )
        
        var accumulated = ""
        
        for try await token in model.generateStream(prompt: prompt) {
            accumulated += token
            onToken(token)
        }
        
        // Parse final JSON
        let decoder = JSONDecoder()
        let coaching = try decoder.decode(CoachingResponse.self, from: accumulated.data(using: .utf8)!)
        
        return coaching
    }
    
    enum LLMError: Error {
        case modelNotLoaded
        case generationFailed
        case invalidResponse
    }
}

struct CoachingParameters {
    let tone: Tone
    let verbosity: Verbosity
    let formality: Formality
    
    enum Tone: String {
        case warm, neutral, direct
    }
    
    enum Verbosity: String {
        case concise, balanced, detailed
    }
    
    enum Formality: String {
        case casual, moderate, formal
    }
    
    static let `default` = CoachingParameters(
        tone: .warm,
        verbosity: .balanced,
        formality: .casual
    )
}
```

### 2. Prompt Builder System

```swift
import Foundation

struct PromptBuilder {
    static func buildCoachingPrompt(
        conversation: [Message],
        intent: CoachingIntent,
        parameters: CoachingParameters
    ) -> String {
        let systemPrompt = buildSystemPrompt()
        let intentPrompt = buildIntentPrompt(intent: intent)
        let conversationContext = buildConversationContext(messages: conversation)
        let parametersPrompt = buildParametersPrompt(parameters: parameters)
        let outputSchema = buildOutputSchema()
        
        return """
        \(systemPrompt)
        
        \(intentPrompt)
        
        \(conversationContext)
        
        \(parametersPrompt)
        
        \(outputSchema)
        """
    }
    
    private static func buildSystemPrompt() -> String {
        """
        You are Subtext, a supportive and empathetic conversation coach for dating and relationships.
        
        Your role:
        - Help users communicate more effectively in romantic conversations
        - Provide 3 distinct reply options with clear rationales
        - Be warm, non-judgmental, and empowering
        - Detect and flag concerning patterns (manipulation, toxicity, red flags)
        - Respect user agency - suggest, don't prescribe
        
        Core principles:
        - Privacy: All processing is on-device
        - Safety: Flag unhealthy patterns
        - Nuance: Understand context and subtext
        - Empowerment: Help users find their voice
        
        Tone: Supportive friend who gives honest advice
        """
    }
    
    private static func buildIntentPrompt(intent: CoachingIntent) -> String {
        switch intent {
        case .reply:
            return """
            INTENT: Help craft a reply
            
            The user wants help responding to the most recent message.
            
            Analyze:
            - What is the other person trying to communicate?
            - What might they be feeling?
            - What are the key emotional beats?
            
            Provide 3 reply options:
            1. Option A: [One approach with specific tone]
            2. Option B: [Different approach with different tone]
            3. Option C: [Third distinct approach]
            
            For each reply, explain WHY it might work.
            """
            
        case .interpret:
            return """
            INTENT: Interpret their message
            
            The user is confused about what the other person meant.
            
            Analyze:
            - What are they literally saying?
            - What might they actually mean? (subtext)
            - What emotions are they expressing?
            - What might they want from the user?
            
            Then suggest 3 ways to respond based on your interpretation.
            """
            
        case .boundary:
            return """
            INTENT: Set a boundary
            
            The user needs to establish or reinforce a personal boundary.
            
            Analyze:
            - What boundary needs to be set?
            - Is this situation concerning? (flag if yes)
            - How can they assert this boundary kindly but firmly?
            
            Provide 3 boundary-setting approaches:
            1. Direct and clear
            2. Warm but firm
            3. Gentle redirect
            
            Emphasize that boundaries are healthy and necessary.
            """
            
        case .flirt:
            return """
            INTENT: Flirt playfully
            
            The user wants to be flirty and show romantic interest.
            
            Analyze:
            - Is the vibe mutual? (check for reciprocation)
            - What's their flirting style so far?
            - What level of boldness fits the situation?
            
            Provide 3 flirty reply options:
            1. Playful and light
            2. Confident and direct
            3. Warm and genuine
            
            Make sure suggestions feel authentic, not forced.
            """
            
        case .conflict:
            return """
            INTENT: Navigate conflict
            
            The user is in a disagreement or tense situation.
            
            Analyze:
            - What is the core issue?
            - Are both parties communicating healthily? (flag if not)
            - What does the user actually want? (resolution, understanding, space?)
            
            Provide 3 conflict-resolution approaches:
            1. Validate their feelings first
            2. Find common ground
            3. Suggest a constructive path forward
            
            Prioritize de-escalation and mutual understanding.
            """
        }
    }
    
    private static func buildConversationContext(messages: [Message]) -> String {
        let formatted = messages.suffix(20).map { msg in  // Last 20 messages for context
            let speaker = msg.isFromUser ? "Me" : msg.sender
            return "[\(speaker)]: \(msg.text)"
        }.joined(separator: "\n")
        
        return """
        CONVERSATION CONTEXT:
        
        \(formatted)
        
        (Focus on the most recent messages for your coaching)
        """
    }
    
    private static func buildParametersPrompt(parameters: CoachingParameters) -> String {
        """
        USER PREFERENCES:
        - Tone: \(parameters.tone.rawValue)
        - Verbosity: \(parameters.verbosity.rawValue)
        - Formality: \(parameters.formality.rawValue)
        
        Adjust your suggestions to match these preferences.
        """
    }
    
    private static func buildOutputSchema() -> String {
        """
        OUTPUT FORMAT (JSON):
        
        {
          "summary": "Brief analysis of the situation (2-3 sentences)",
          "replies": [
            {
              "text": "The actual reply text the user could send",
              "rationale": "Why this reply works and what it accomplishes",
              "tone": "casual" | "warm" | "direct" | "playful" | "firm"
            },
            // ... 2 more replies
          ],
          "riskFlags": [
            {
              "type": "manipulation" | "gaslighting" | "pressuring" | "toxicity" | "red_flag",
              "severity": "low" | "medium" | "high",
              "description": "Explanation of the concern",
              "evidence": ["Specific message excerpts that show this pattern"]
            }
          ],
          "followUpQuestions": [
            "Question 1 to help user think deeper",
            "Question 2 to clarify their intent"
          ]
        }
        
        Respond ONLY with valid JSON matching this schema.
        """
    }
}
```

### 3. Coaching Response Models

```swift
import Foundation

struct CoachingResponse: Codable {
    let summary: String
    let replies: [ReplyOption]
    let riskFlags: [RiskFlag]
    let followUpQuestions: [String]
    
    static let schema: JSONSchema = {
        // Define JSON schema for structured generation
        // This would use Foundation Models' schema definition API
        // Details depend on Apple's actual API
        return .object([
            "summary": .string,
            "replies": .array(.object([
                "text": .string,
                "rationale": .string,
                "tone": .enum(["casual", "warm", "direct", "playful", "firm"])
            ])),
            "riskFlags": .array(.object([
                "type": .enum(["manipulation", "gaslighting", "pressuring", "toxicity", "red_flag"]),
                "severity": .enum(["low", "medium", "high"]),
                "description": .string,
                "evidence": .array(.string)
            ])),
            "followUpQuestions": .array(.string)
        ])
    }()
}

struct ReplyOption: Codable, Identifiable {
    let id: UUID
    let text: String
    let rationale: String
    let tone: String
    
    init(text: String, rationale: String, tone: String) {
        self.id = UUID()
        self.text = text
        self.rationale = rationale
        self.tone = tone
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.text = try container.decode(String.self, forKey: .text)
        self.rationale = try container.decode(String.self, forKey: .rationale)
        self.tone = try container.decode(String.self, forKey: .tone)
    }
    
    enum CodingKeys: String, CodingKey {
        case text, rationale, tone
    }
}
```

### 4. Intent Selection View

```swift
import SwiftUI

struct IntentSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let conversation: ConversationThread
    let onIntentSelected: (CoachingIntent, CoachingParameters) -> Void
    
    @State private var selectedIntent: CoachingIntent?
    @State private var tone: CoachingParameters.Tone = .warm
    @State private var verbosity: CoachingParameters.Verbosity = .balanced
    @State private var formality: CoachingParameters.Formality = .casual
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    intentGrid
                    if selectedIntent != nil {
                        parametersSection
                        generateButton
                    }
                }
                .padding()
            }
            .navigationTitle("Get Coaching")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.purple)
            
            Text("What do you need help with?")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Choose an intent to get personalized coaching")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var intentGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(CoachingIntent.allCases, id: \.self) { intent in
                IntentCard(
                    intent: intent,
                    isSelected: selectedIntent == intent
                ) {
                    withAnimation(.spring()) {
                        selectedIntent = intent
                    }
                }
            }
        }
    }
    
    private var parametersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Adjust Tone")
                .font(.headline)
            
            Picker("Tone", selection: $tone) {
                Text("Warm").tag(CoachingParameters.Tone.warm)
                Text("Neutral").tag(CoachingParameters.Tone.neutral)
                Text("Direct").tag(CoachingParameters.Tone.direct)
            }
            .pickerStyle(.segmented)
            
            Picker("Verbosity", selection: $verbosity) {
                Text("Concise").tag(CoachingParameters.Verbosity.concise)
                Text("Balanced").tag(CoachingParameters.Verbosity.balanced)
                Text("Detailed").tag(CoachingParameters.Verbosity.detailed)
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var generateButton: some View {
        Button {
            guard let intent = selectedIntent else { return }
            let params = CoachingParameters(tone: tone, verbosity: verbosity, formality: formality)
            onIntentSelected(intent, params)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate Coaching")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

struct IntentCard: View {
    let intent: CoachingIntent
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .purple)
                
                Text(intent.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.purple : Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var icon: String {
        switch intent {
        case .reply: return "message.fill"
        case .interpret: return "eye.fill"
        case .boundary: return "hand.raised.fill"
        case .flirt: return "heart.fill"
        case .conflict: return "arrow.triangle.2.circlepath"
        }
    }
    
    private var description: String {
        switch intent {
        case .reply: return "Craft a reply"
        case .interpret: return "Understand their message"
        case .boundary: return "Set a boundary"
        case .flirt: return "Be playful"
        case .conflict: return "Navigate disagreement"
        }
    }
}
```

### 5. Coaching Results View

```swift
import SwiftUI

struct CoachingResultsView: View {
    @Environment(\.dismiss) private var dismiss
    let coaching: CoachingResponse
    let onRegenerate: () -> Void
    
    @State private var selectedReply: ReplyOption?
    @State private var showingCopied = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    summarySection
                    
                    if !coaching.riskFlags.isEmpty {
                        riskFlagsSection
                    }
                    
                    repliesSection
                    
                    if !coaching.followUpQuestions.isEmpty {
                        followUpSection
                    }
                }
                .padding()
            }
            .navigationTitle("Coaching Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onRegenerate()
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }
                }
            }
            .alert("Copied!", isPresented: $showingCopied) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Reply copied to clipboard")
            }
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Situation Analysis", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.purple)
            
            Text(coaching.summary)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var riskFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(coaching.riskFlags, id: \.description) { flag in
                RiskFlagBanner(flag: flag)
            }
        }
    }
    
    private var repliesSection: some View {
        VStack(spacing: 16) {
            Text("Suggested Replies")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(coaching.replies) { reply in
                ReplyCard(
                    reply: reply,
                    isSelected: selectedReply?.id == reply.id,
                    onSelect: { selectedReply = reply },
                    onCopy: {
                        UIPasteboard.general.string = reply.text
                        showingCopied = true
                    }
                )
            }
        }
    }
    
    private var followUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Think About This", systemImage: "questionmark.circle.fill")
                .font(.headline)
                .foregroundColor(.blue)
            
            ForEach(coaching.followUpQuestions, id: \.self) { question in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    Text(question)
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ReplyCard: View {
    let reply: ReplyOption
    let isSelected: Bool
    let onSelect: () -> Void
    let onCopy: () -> Void
    
    @State private var showingRationale = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(reply.tone.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .cornerRadius(6)
                
                Spacer()
                
                Button(action: { showingRationale.toggle() }) {
                    Label("Why?", systemImage: showingRationale ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(reply.text)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            if showingRationale {
                Text(reply.rationale)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            Button(action: onCopy) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Reply")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(isSelected ? Color.purple.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

struct RiskFlagBanner: View {
    let flag: RiskFlag
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(severityColor)
                
                Text(flag.type.rawValue.capitalized)
                    .font(.headline)
                    .foregroundColor(severityColor)
                
                Spacer()
                
                Text(flag.severity.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(severityColor.opacity(0.2))
                    .foregroundColor(severityColor)
                    .cornerRadius(4)
            }
            
            Text(flag.description)
                .font(.subheadline)
            
            if !flag.evidence.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Evidence:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    ForEach(flag.evidence, id: \.self) { evidence in
                        Text("• \(evidence)")
                            .font(.caption)
                            .italic()
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(severityColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor, lineWidth: 2)
        )
    }
    
    private var severityColor: Color {
        switch flag.severity {
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
}
```

## Implementation Tasks

### Week 5: Foundation Models Integration

#### Day 1-2: LLM Client Setup
- [ ] Set up Foundation Models framework
- [ ] Implement `LLMClient` actor
- [ ] Test model loading and initialization
- [ ] Implement basic generation method
- [ ] Add error handling

#### Day 3-4: Prompt Engineering
- [ ] Create `PromptBuilder` system
- [ ] Write system prompt
- [ ] Write intent-specific prompts (all 5)
- [ ] Define JSON output schema
- [ ] Test prompts with sample conversations

#### Day 5: Response Models
- [ ] Implement `CoachingResponse` Codable
- [ ] Create `ReplyOption` struct
- [ ] Test JSON parsing
- [ ] Add validation logic
- [ ] Handle malformed responses

### Week 6: UI & Integration

#### Day 1-2: Intent Selection
- [ ] Build `IntentSelectionView`
- [ ] Create `IntentCard` components
- [ ] Add parameter sliders
- [ ] Implement selection logic
- [ ] Test on various screen sizes

#### Day 3-4: Coaching Results
- [ ] Build `CoachingResultsView`
- [ ] Implement `ReplyCard` component
- [ ] Add `RiskFlagBanner` component
- [ ] Implement copy-to-clipboard
- [ ] Add regenerate functionality

#### Day 5: End-to-End Integration
- [ ] Wire up conversation detail → intent → coaching → results
- [ ] Implement coaching session persistence
- [ ] Add loading states throughout
- [ ] Test complete flow
- [ ] Performance optimization

## Validation Criteria

### Functional Requirements
- ✅ Foundation Models loads successfully
- ✅ Can generate coaching for all 5 intents
- ✅ Responses are consistently well-formed JSON
- ✅ Replies are contextually appropriate
- ✅ Rationales are clear and helpful
- ✅ Risk flags detect concerning patterns
- ✅ Can regenerate with different parameters
- ✅ Copy to clipboard works

### Quality Requirements
- ✅ Replies feel natural and authentic
- ✅ Rationales explain the "why" effectively
- ✅ Tone adjustments are noticeable
- ✅ Risk detection >85% precision
- ✅ False positive rate <15%

### Performance Requirements
- ✅ First token < 3 seconds
- ✅ Full response < 10 seconds
- ✅ UI remains responsive during generation
- ✅ Memory usage < 500MB

## Testing Strategy

### Unit Tests
```swift
// LLMClientTests.swift
func testModelInitialization() async throws {
    let client = LLMClient.shared
    // Test model loads
}

func testGenerateCoaching() async throws {
    let messages = createSampleMessages()
    let response = try await LLMClient.shared.generateCoaching(
        conversation: messages,
        intent: .reply
    )
    XCTAssertEqual(response.replies.count, 3)
    XCTAssertFalse(response.summary.isEmpty)
}

// PromptBuilderTests.swift
func testPromptStructure() {
    let messages = createSampleMessages()
    let prompt = PromptBuilder.buildCoachingPrompt(
        conversation: messages,
        intent: .reply,
        parameters: .default
    )
    XCTAssertTrue(prompt.contains("INTENT"))
    XCTAssertTrue(prompt.contains("OUTPUT FORMAT"))
}
```

### Manual Testing Checklist
- [ ] Test all 5 intents with real conversations
- [ ] Verify response quality (10 samples per intent)
- [ ] Test edge cases (very short/long conversations)
- [ ] Test with emoji and special characters
- [ ] Test regeneration works correctly
- [ ] Verify risk flags on toxic examples
- [ ] Test copy to clipboard
- [ ] Test on multiple devices (iPhone 15, 15 Pro)
- [ ] Monitor memory and battery usage

## Risks & Mitigations

### Risk: Foundation Models Not Available/Delayed
**Likelihood:** Low  
**Impact:** Critical  
**Mitigation:**
- Monitor Apple beta releases closely
- Have Core ML backup (Phi-3-Mini)
- Abstract LLM client for easy swapping

### Risk: Response Quality Insufficient
**Likelihood:** Medium  
**Impact:** High  
**Mitigation:**
- Extensive prompt iteration
- Collect user feedback early
- A/B test different prompts
- Have human review samples

### Risk: Performance Too Slow
**Likelihood:** Low  
**Impact:** Medium  
**Mitigation:**
- Test on target devices early
- Optimize prompt length
- Implement streaming for better UX
- Show progress indicators

## Handoff to Phase 4

### Deliverables
- ✅ Foundation Models integrated
- ✅ All 5 intents working
- ✅ Coaching UI complete
- ✅ Copy/regenerate functional
- ✅ Basic safety detection operational

### Ready for Phase 4 When:
1. Can generate coaching for all intents
2. Response quality is satisfactory (>4.0/5)
3. Performance meets targets (<10s)
4. UI is polished and intuitive
5. All tests passing
6. No critical bugs

### Next Phase Preview
**Phase 4** will focus on safety and polish:
- Enhanced risk detection
- UI/UX refinements
- Error handling improvements
- Performance optimization
- Offline mode handling

---

**Estimated Effort:** 80 hours (1 full-time engineer, 2 weeks)  
**Dependencies:** Phase 2 complete, Foundation Models available  
**Blockers:** Foundation Models beta access required

