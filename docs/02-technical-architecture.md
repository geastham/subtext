# Technical Architecture & Implementation Strategy

## System Overview

Subtext is a **client-only**, **privacy-first** iOS application that performs all AI inference on-device. The architecture is designed to maximize privacy, minimize latency, and provide a seamless user experience across all supported iOS devices.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    iOS Application                       │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │              SwiftUI Interface Layer                │ │
│  │  • Conversation Import  • Coaching UI               │ │
│  │  • Reply Generation    • Settings                   │ │
│  └────────────────────────────────────────────────────┘ │
│                         │                                │
│  ┌────────────────────────────────────────────────────┐ │
│  │           Business Logic & Orchestration            │ │
│  │  • Intent Classification  • Safety Layer            │ │
│  │  • Context Management    • Personalization          │ │
│  └────────────────────────────────────────────────────┘ │
│                         │                                │
│  ┌────────────────────────────────────────────────────┐ │
│  │              On-Device AI Layer                     │ │
│  │  ┌──────────────────┐  ┌──────────────────────┐   │ │
│  │  │ Foundation Models│  │   Core ML Model      │   │ │
│  │  │  (iOS 26+)      │  │  (Fallback)          │   │ │
│  │  └──────────────────┘  └──────────────────────┘   │ │
│  └────────────────────────────────────────────────────┘ │
│                         │                                │
│  ┌────────────────────────────────────────────────────┐ │
│  │          Local Data Layer (Encrypted)               │ │
│  │  • Core Data / SwiftData  • Keychain                │ │
│  │  • File Storage (encrypted) • User Preferences      │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Platform Requirements

### Minimum OS Version Strategy

**Recommended: iOS 26+ as primary target**
- Provides access to Foundation Models framework
- Enables best-in-class on-device AI with minimal app size
- Strong privacy marketing alignment with Apple Intelligence

**Fallback: iOS 17+ support**
- Use Core ML for on-device inference
- Requires shipping model weights (~1-3GB app size impact)
- Broader device compatibility

**Trade-off Analysis:**

| Aspect | iOS 26+ Only | iOS 17+ (with fallback) |
|--------|-------------|-------------------------|
| Market Coverage | ~60% of active iPhones (est. 2026) | ~90% of active iPhones |
| App Size | ~50-100MB | ~1.5-3GB (includes model) |
| Performance | Optimal (Apple silicon optimized) | Variable by device |
| Development | Simpler (one path) | Complex (two paths) |
| Marketing | "Built for Apple Intelligence" | "Works on your iPhone" |

**Recommendation for MVP**: Start with iOS 26+ only, validate product-market fit, then add iOS 17+ support in V1.5 if needed.

## On-Device AI Architecture

### Dual-Path Strategy

#### Path A: Foundation Models Framework (Primary)

**Capabilities:**
- Access to Apple's ~3B parameter on-device LLM
- Native structured output support (JSON schemas)
- Tool calling for integrating data sources
- Stateful sessions for context management
- Streaming for responsive experiences

**Implementation:**
```swift
import FoundationModels

// Initialize session with context
let session = await LanguageModelSession()

// Define structured output schema
struct ReplyOptions: Codable {
    let summary: String
    let situationSignals: [String]
    let riskFlags: [RiskFlag]
    let replyOptions: [Reply]
}

// Generate structured coaching
let result = try await session.generate(
    prompt: constructPrompt(conversation: thread),
    responseFormat: .json(ReplyOptions.self)
)
```

**Performance Characteristics:**
- First token latency: ~1-2s on iPhone 15 Pro
- Throughput: ~20-30 tokens/sec on modern devices
- Memory: ~500MB-1GB during inference
- Battery impact: Low (Apple silicon optimized)

#### Path B: Core ML Model (Fallback)

**Model Selection:**
- **Primary candidate**: Llama 3.1-8B-Instruct (quantized to 4-bit)
- **Alternative**: Phi-3-mini (3.8B parameters)
- **Considerations**: Size vs. quality trade-off

**Optimization Techniques:**
1. **Quantization**: 4-bit quantization-aware training
2. **KV-cache optimization**: Shared across multiple generations
3. **Batching**: Process multiple intents efficiently
4. **Pruning**: Remove unnecessary layers for conversation coaching

**Implementation:**
```swift
import CoreML

class CoreMLLLMClient {
    private let model: MLModel
    
    func generate(
        prompt: String,
        maxTokens: Int = 512
    ) async throws -> String {
        // Tokenize input
        let tokens = tokenize(prompt)
        
        // Run inference with streaming
        var output = ""
        for token in try await model.predict(tokens) {
            output += detokenize(token)
            // Stream to UI
            await MainActor.run {
                updateUI(with: output)
            }
        }
        return output
    }
}
```

**Performance Characteristics** (iPhone 14 Pro):
- First token latency: ~3-5s
- Throughput: ~15-20 tokens/sec
- Memory: ~2-3GB during inference
- App size increase: ~1.5-2GB (quantized model)

### Model Comparison

| Model | Size | Latency | Quality | Device Support |
|-------|------|---------|---------|----------------|
| Foundation Models | 0MB (system) | Best | Excellent | iOS 26+ |
| Llama 3.1-8B (4-bit) | ~4GB | Good | Excellent | iOS 17+ (recent) |
| Phi-3-mini (4-bit) | ~2GB | Good | Very Good | iOS 17+ (broader) |

## Data Architecture

### Local Data Model

```swift
// Core Data / SwiftData Entities

@Model
class ConversationThread {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var participants: Participants
    var messages: [Message]
    var userNotes: String?
    var isArchived: Bool
    
    // Derived
    var messageCount: Int { messages.count }
    var lastMessageAt: Date? { messages.last?.timestamp }
}

@Model
class Message {
    var id: UUID
    var timestamp: Date?
    var speaker: Speaker // me, them, unknown
    var text: String
    var metadata: MessageMetadata?
    
    var thread: ConversationThread?
}

enum Speaker: String, Codable {
    case me
    case them
    case unknown
}

struct Participants: Codable {
    var meLabel: String
    var themLabel: String
}

@Model
class CoachingSession {
    var id: UUID
    var threadId: UUID
    var createdAt: Date
    var intent: Intent
    var constraints: Constraints
    var outputs: CoachingOutputs
    var userFeedback: Feedback?
    
    var thread: ConversationThread?
}

enum Intent: String, CaseIterable, Codable {
    case reply = "Reply"
    case interpret = "Interpret"
    case boundary = "Set Boundary"
    case flirt = "Flirt"
    case conflict = "Repair Conflict"
    case closure = "Closure"
}

struct Constraints: Codable {
    var directness: Float // 0.0 - 1.0
    var warmth: Float
    var flirtiness: Float
    var length: MessageLength
}

enum MessageLength: String, Codable {
    case brief, moderate, detailed
}

struct CoachingOutputs: Codable {
    var summary: String
    var situationSignals: [String]
    var riskFlags: [RiskFlag]
    var replyOptions: [Reply]
    var followUpQuestions: [String]
}

struct RiskFlag: Codable {
    var type: RiskType
    var evidence: [String]
    var severity: Severity
    var recommendation: String
}

enum RiskType: String, Codable {
    case coercion, loveBombing, guiltTripping
    case gaslighting, manipulation, aggression
    case rushingIntimacy, isolationTactics
}

enum Severity: String, Codable {
    case low, medium, high
}

struct Reply: Codable {
    var id: UUID
    var label: String // "Warm + clear"
    var text: String
    var rationale: [String]
    var tone: ToneProfile
}

struct ToneProfile: Codable {
    var warmth: Float
    var directness: Float
    var flirtiness: Float
    var formality: Float
}

struct Feedback: Codable {
    var rating: Rating // thumbs up/down
    var editDistance: Int?
    var wasUsed: Bool
    var notes: String?
}

enum Rating: String, Codable {
    case up, down
}
```

### Storage Security

**Encryption at Rest:**
```swift
// Core Data with encryption
let container = NSPersistentContainer(name: "Subtext")

// Enable Data Protection
let storeDescription = container.persistentStoreDescriptions.first!
storeDescription.setOption(
    FileProtectionType.complete as NSObject,
    forKey: NSPersistentStoreFileProtectionKey
)

// Additional encryption for sensitive fields
class EncryptedString: NSSecureUnattransformable {
    // Uses Keychain-managed encryption keys
}
```

**Keychain Integration:**
```swift
// Store encryption keys
let keychain = KeychainManager.shared
try keychain.store(encryptionKey, for: "conversation_encryption")
```

**Secure Deletion:**
```swift
func deleteAllData() async throws {
    // 1. Delete Core Data entities
    try await dataStore.deleteAll()
    
    // 2. Remove encryption keys
    try keychain.removeAll()
    
    // 3. Clear file caches
    try fileManager.removeItem(at: cacheDirectory)
    
    // 4. Clear model caches
    try modelCache.purge()
}
```

## Business Logic Layer

### Conversation Parser

**Responsibilities:**
- Parse pasted text into structured messages
- Detect speaker patterns
- Extract timestamps (if available)
- Handle various formats (iMessage, WhatsApp, manual)

**Implementation:**
```swift
class ConversationParser {
    func parse(_ text: String) -> ParsedConversation {
        // Detect format
        let format = detectFormat(text)
        
        // Apply format-specific parser
        let messages = switch format {
        case .iMessage: parseIMessage(text)
        case .whatsApp: parseWhatsApp(text)
        case .manual: parseManual(text)
        }
        
        // Infer speakers
        let labeled = inferSpeakers(messages)
        
        return ParsedConversation(
            messages: labeled,
            confidence: calculateConfidence(labeled)
        )
    }
}
```

### Intent Classifier

**Responsibilities:**
- Classify user's goal (reply, interpret, boundary, etc.)
- Suggest relevant constraints
- Pre-validate safety considerations

**Implementation:**
```swift
class IntentClassifier {
    func classify(
        conversation: ConversationThread,
        userGoal: String?
    ) async -> Intent {
        if let goal = userGoal {
            return Intent(rawValue: goal) ?? .reply
        }
        
        // Use on-device model to infer intent
        let prompt = """
        Analyze this conversation and determine the user's likely goal.
        Conversation: \(conversation.recentMessages(5))
        """
        
        let result = try? await llm.generate(
            prompt: prompt,
            responseFormat: .json(IntentClassification.self)
        )
        
        return result?.intent ?? .reply
    }
}
```

### Safety Layer

**Two-tier approach:**

**1. Hard Rules (Fast, Local)**
```swift
class SafetyRules {
    static let prohibitedPatterns = [
        "self-harm",
        "explicit sexual content",
        "stalking instructions",
        "violence"
    ]
    
    func check(_ text: String) -> SafetyCheckResult {
        for pattern in Self.prohibitedPatterns {
            if text.contains(pattern) {
                return .blocked(reason: pattern)
            }
        }
        return .safe
    }
}
```

**2. AI Classifier (Contextual)**
```swift
class SafetyClassifier {
    func analyze(
        conversation: ConversationThread
    ) async -> [RiskFlag] {
        let prompt = """
        Analyze this conversation for signs of:
        - Coercion or manipulation
        - Love bombing
        - Gaslighting
        - Guilt-tripping
        - Rushing intimacy
        
        Conversation: \(conversation.messages)
        """
        
        let result = try? await llm.generate(
            prompt: prompt,
            responseFormat: .json(SafetyAnalysis.self)
        )
        
        return result?.riskFlags ?? []
    }
}
```

**Safety Policy:**
- If coercion/abuse detected: Prioritize boundary-setting and safety resources
- Never generate manipulative or coercive responses
- Provide supportive, non-judgmental guidance
- Include disclaimer: "Not professional advice"

### Prompt Engineering

**System Prompt Template:**
```swift
let systemPrompt = """
You are Subtext, a supportive conversation coach helping users communicate authentically in dating contexts.

Core principles:
- Be supportive, never judgmental
- Prioritize healthy communication and boundaries
- Respect user autonomy (they choose whether to use suggestions)
- Flag concerning patterns (manipulation, coercion)
- Encourage genuine self-expression

Response format: Always use the provided JSON schema.
"""
```

**User Prompt Template:**
```swift
func constructPrompt(
    conversation: ConversationThread,
    intent: Intent,
    constraints: Constraints
) -> String {
    """
    Conversation context:
    \(conversation.formattedForPrompt())
    
    User's goal: \(intent.rawValue)
    
    Constraints:
    - Directness: \(constraints.directness)
    - Warmth: \(constraints.warmth)
    - Flirtiness: \(constraints.flirtiness)
    - Length: \(constraints.length)
    
    Provide:
    1. Brief summary of the situation
    2. Situation signals (mixed messages, warm, cold, etc.)
    3. Any risk flags
    4. 3 reply options with rationales
    5. Follow-up questions for clarification
    
    Response format: JSON matching ReplyOptions schema
    """
}
```

## Performance Optimization

### Strategy 1: Intelligent Context Windowing

```swift
extension ConversationThread {
    func recentMessages(_ count: Int = 20) -> [Message] {
        // Get last N messages, plus any critical earlier context
        let recent = messages.suffix(count)
        
        // Include important earlier messages (e.g., first message, key moments)
        let important = messages.prefix(3)
        
        return Array(important + recent).uniqued()
    }
}
```

### Strategy 2: Caching

```swift
class ModelCache {
    // Cache embeddings for long conversations
    private var embeddingsCache: [UUID: Embeddings] = [:]
    
    // Cache common intents
    private var intentCache: [String: Intent] = [:]
    
    func cacheEmbeddings(for threadId: UUID, embeddings: Embeddings) {
        embeddingsCache[threadId] = embeddings
    }
}
```

### Strategy 3: Progressive Enhancement

```swift
// Start with fast, basic analysis
let quickReply = generateQuickReply(conversation)
updateUI(with: quickReply)

// Then enhance with deeper analysis
let deepAnalysis = await generateDeepAnalysis(conversation)
updateUI(with: deepAnalysis)
```

### Strategy 4: Energy Management

```swift
class EnergyManager {
    func shouldThrottleGeneration() -> Bool {
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryState = UIDevice.current.batteryState
        
        // Throttle if battery < 20% and not charging
        return batteryLevel < 0.2 && batteryState != .charging
    }
    
    func optimizeForBattery() {
        // Reduce generation length
        // Use fewer reply options
        // Batch multiple requests
    }
}
```

## API Design

### Core Services

```swift
// Main coaching service
protocol CoachingService {
    func analyzeConversation(
        _ thread: ConversationThread,
        intent: Intent,
        constraints: Constraints
    ) async throws -> CoachingOutputs
    
    func regenerate(
        sessionId: UUID,
        newConstraints: Constraints
    ) async throws -> CoachingOutputs
}

// LLM abstraction
protocol LLMClient {
    func generate<T: Codable>(
        prompt: String,
        responseFormat: ResponseFormat<T>
    ) async throws -> T
    
    func stream<T: Codable>(
        prompt: String,
        responseFormat: ResponseFormat<T>
    ) -> AsyncStream<PartialResult<T>>
}

// Storage abstraction
protocol ConversationStore {
    func save(_ thread: ConversationThread) async throws
    func fetch(id: UUID) async throws -> ConversationThread
    func fetchAll() async throws -> [ConversationThread]
    func delete(id: UUID) async throws
    func search(query: String) async throws -> [ConversationThread]
}
```

## Testing Strategy

### Unit Tests
- Parser logic (various formats)
- Safety rules (prohibited patterns)
- Data model validations
- Constraint calculations

### Integration Tests
- End-to-end coaching flow
- Model inference (with mock data)
- Storage operations
- Privacy guarantees (no network calls)

### Performance Tests
- Model inference latency
- Memory usage during generation
- Battery impact (XCTest metrics)
- App size validation

### Safety Tests
- Red flag detection accuracy
- False positive rate
- Policy compliance (prohibited outputs)

### User Testing
- Conversation import usability
- Reply quality (A/B tests)
- Intent selection clarity
- Constraint UI effectiveness

## Deployment & Distribution

### App Store Optimization

**Privacy Nutrition Label:**
- Data Types Collected: **None**
- Data Linked to You: **None**
- Data Used to Track You: **None**

**App Store Description Highlights:**
- "100% on-device processing"
- "Your conversations never leave your iPhone"
- "No data collection, ever"
- "Works offline"

### Beta Distribution

**TestFlight:**
- Internal testing: 2 weeks
- External beta: 100-500 users
- Feedback collection via in-app surveys
- Crash analytics (privacy-preserving)

### Phased Rollout

1. **Week 1-2**: Internal team + close friends (25 users)
2. **Week 3-4**: Expanded beta (100 users)
3. **Week 5-8**: Public beta (500 users)
4. **Week 9+**: App Store release (100% rollout)

## Monitoring & Analytics

### Privacy-Preserving Telemetry

**Allowed metrics** (opt-in, aggregated):
- Feature usage counts (e.g., "generated 5 replies this week")
- Performance metrics (latency, memory, crashes)
- Errors (anonymized, no conversation data)

**Prohibited:**
- Conversation text (ever)
- User identifiers
- Behavioral tracking
- Third-party analytics SDKs

**Implementation:**
```swift
class PrivacyFirstAnalytics {
    func trackEvent(_ event: AnalyticsEvent) {
        guard userOptedIn else { return }
        
        // Only track aggregated, non-identifiable data
        let sanitized = event.sanitized() // strips all PII
        localStore.record(sanitized)
        
        // Batch and send weekly (if online)
        if shouldSync() {
            syncAggregatedMetrics()
        }
    }
}
```

## Future Architecture Considerations

### V2: Optional Cloud Escalation

If users want "bigger brain mode":

**Apple Private Cloud Compute Integration:**
- Only for complex requests user explicitly opts into
- Data encrypted end-to-end
- Not accessible to Apple or Subtext
- Fallback to on-device if unavailable

**Implementation would require:**
- Explicit user consent per request
- E2E encryption before sending
- Audit trail of what was sent
- Clear UI indication ("Using cloud for this request")

### V3: Keyboard Extension

**Architecture:**
- Share core LLM client between main app and extension
- Extension has limited memory/CPU budget
- Fallback to "quick suggestions" mode
- Full analysis available via "Open in Subtext" button

---

## Technology Stack Summary

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **UI** | SwiftUI | Modern, declarative, Apple-native |
| **Data** | SwiftData or Core Data | Local persistence, encryption support |
| **AI** | Foundation Models + Core ML | On-device, privacy-first |
| **Security** | Keychain, FileProtection | Apple-standard encryption |
| **Testing** | XCTest, XCUITest | Native tooling |
| **Analytics** | Custom, privacy-first | No third-party SDKs |
| **Distribution** | TestFlight → App Store | Standard Apple flow |

---

*This architecture is designed to evolve as Apple's frameworks improve and user needs become clearer. The focus on privacy and on-device processing is non-negotiable.*

