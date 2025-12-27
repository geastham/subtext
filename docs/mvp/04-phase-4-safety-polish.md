# Phase 4: Safety & Polish

**Duration:** Week 7  
**Status:** ⏳ Pending Phase 3 Completion

## Goals

Enhance safety detection, refine the user experience, and polish the app for beta launch:
- Implement comprehensive safety classification
- Add hard safety rules for prohibited content
- Refine UI/UX based on testing feedback
- Improve error handling and edge cases
- Optimize performance
- Handle offline scenarios gracefully
- Final bug fixes

## Key Deliverables

- ✅ Enhanced safety detection system
- ✅ Hard safety rules implemented
- ✅ Support resources for high-risk situations
- ✅ Polished UI with smooth animations
- ✅ Comprehensive error handling
- ✅ Offline mode UX
- ✅ Performance optimizations
- ✅ Critical bug fixes

## Technical Architecture

### 1. Enhanced Safety Classifier

```swift
import Foundation

actor SafetyClassifier {
    static let shared = SafetyClassifier()
    
    private init() {}
    
    // Comprehensive safety analysis
    func analyzeSafety(conversation: [Message]) async throws -> SafetyAnalysis {
        // Step 1: Check hard rules (instant red flags)
        let hardRules = await checkHardRules(conversation)
        
        // Step 2: AI-based pattern detection
        let patterns = try await detectPatterns(conversation)
        
        // Step 3: Aggregate and prioritize
        let flags = aggregateFlags(hardRules: hardRules, patterns: patterns)
        
        // Step 4: Generate recommendations
        let recommendations = generateRecommendations(flags: flags)
        
        // Step 5: Determine if resources should be shown
        let needsResources = flags.contains { $0.severity == .high }
        
        return SafetyAnalysis(
            flags: flags,
            overallRisk: calculateOverallRisk(flags: flags),
            recommendations: recommendations,
            supportResources: needsResources ? getSupportResources() : []
        )
    }
    
    // MARK: - Hard Rules
    
    private func checkHardRules(_ conversation: [Message]) async -> [RiskFlag] {
        var flags: [RiskFlag] = []
        
        for message in conversation {
            let text = message.text.lowercased()
            
            // Explicit threats or violence
            if containsPattern(text, patterns: HardRules.violencePatterns) {
                flags.append(RiskFlag(
                    type: .violence,
                    severity: .high,
                    description: "This message contains threatening or violent language",
                    evidence: [message.text]
                ))
            }
            
            // Explicit manipulation tactics
            if containsPattern(text, patterns: HardRules.manipulationPatterns) {
                flags.append(RiskFlag(
                    type: .manipulation,
                    severity: .high,
                    description: "This message shows signs of manipulation",
                    evidence: [message.text]
                ))
            }
            
            // Gaslighting indicators
            if containsPattern(text, patterns: HardRules.gaslightingPatterns) {
                flags.append(RiskFlag(
                    type: .gaslighting,
                    severity: .medium,
                    description: "This message may be gaslighting",
                    evidence: [message.text]
                ))
            }
            
            // Extreme pressure or coercion
            if containsPattern(text, patterns: HardRules.pressurePatterns) {
                flags.append(RiskFlag(
                    type: .pressuring,
                    severity: .medium,
                    description: "This message applies pressure or coercion",
                    evidence: [message.text]
                ))
            }
        }
        
        return flags
    }
    
    // MARK: - AI Pattern Detection
    
    private func detectPatterns(_ conversation: [Message]) async throws -> [RiskFlag] {
        // Use LLM to detect subtle patterns
        let prompt = buildSafetyPrompt(conversation: conversation)
        
        let response = try await LLMClient.shared.generateSafetyAnalysis(
            prompt: prompt
        )
        
        return response.flags
    }
    
    private func buildSafetyPrompt(conversation: [Message]) -> String {
        let context = conversation.suffix(20).map { msg in
            "[\(msg.isFromUser ? "Me" : msg.sender)]: \(msg.text)"
        }.joined(separator: "\n")
        
        return """
        Analyze this conversation for unhealthy patterns:
        
        \(context)
        
        Look for:
        - Manipulation tactics (guilt-tripping, emotional blackmail)
        - Gaslighting (denying reality, making them question themselves)
        - Boundary violations (ignoring "no", pressuring)
        - Controlling behavior (isolation, monitoring, jealousy)
        - Disrespect or toxicity
        
        For each pattern found, provide:
        - Type of concern
        - Severity (low/medium/high)
        - Specific evidence (quote the messages)
        - Brief explanation
        
        Be conservative - only flag clear patterns, not misunderstandings.
        
        Output JSON:
        {
          "flags": [
            {
              "type": "manipulation",
              "severity": "medium",
              "description": "...",
              "evidence": ["quote 1", "quote 2"]
            }
          ]
        }
        """
    }
    
    // MARK: - Aggregation & Recommendations
    
    private func aggregateFlags(hardRules: [RiskFlag], patterns: [RiskFlag]) -> [RiskFlag] {
        // Combine and deduplicate flags
        var allFlags = hardRules + patterns
        
        // Sort by severity (high first)
        allFlags.sort { flag1, flag2 in
            severityValue(flag1.severity) > severityValue(flag2.severity)
        }
        
        // Deduplicate similar flags
        var uniqueFlags: [RiskFlag] = []
        for flag in allFlags {
            if !uniqueFlags.contains(where: { $0.type == flag.type }) {
                uniqueFlags.append(flag)
            }
        }
        
        return uniqueFlags
    }
    
    private func calculateOverallRisk(flags: [RiskFlag]) -> RiskLevel {
        if flags.isEmpty { return .none }
        
        let highCount = flags.filter { $0.severity == .high }.count
        let mediumCount = flags.filter { $0.severity == .medium }.count
        
        if highCount > 0 {
            return .high
        } else if mediumCount >= 2 {
            return .high
        } else if mediumCount == 1 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func generateRecommendations(flags: [RiskFlag]) -> [String] {
        var recommendations: [String] = []
        
        for flag in flags {
            switch flag.type {
            case .manipulation:
                recommendations.append("Consider setting clear boundaries about what you're comfortable with")
            case .gaslighting:
                recommendations.append("Trust your perception of events - your feelings are valid")
            case .pressuring:
                recommendations.append("You have the right to say no and take your time")
            case .toxicity:
                recommendations.append("Consider if this conversation pattern is healthy for you")
            case .redFlag:
                recommendations.append("Pay attention to your gut feeling about this situation")
            case .violence:
                recommendations.append("This situation may be unsafe - please reach out for support")
            }
        }
        
        return Array(Set(recommendations))  // Deduplicate
    }
    
    private func getSupportResources() -> [SupportResource] {
        return [
            SupportResource(
                title: "National Domestic Violence Hotline",
                description: "24/7 support for anyone experiencing abuse",
                phone: "1-800-799-7233",
                website: "https://www.thehotline.org"
            ),
            SupportResource(
                title: "Love Is Respect",
                description: "Support for young people in relationships",
                phone: "1-866-331-9474",
                website: "https://www.loveisrespect.org"
            ),
            SupportResource(
                title: "Crisis Text Line",
                description: "Text HOME to 741741 for free 24/7 support",
                phone: "Text HOME to 741741",
                website: "https://www.crisistextline.org"
            )
        ]
    }
    
    // MARK: - Helpers
    
    private func containsPattern(_ text: String, patterns: [String]) -> Bool {
        for pattern in patterns {
            if text.contains(pattern.lowercased()) {
                return true
            }
        }
        return false
    }
    
    private func severityValue(_ severity: RiskFlag.RiskSeverity) -> Int {
        switch severity {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

// MARK: - Hard Rules Patterns

struct HardRules {
    static let violencePatterns = [
        "i'll hurt you",
        "i'll kill",
        "you better",
        "or else",
        "i'll make you",
        "you'll regret"
    ]
    
    static let manipulationPatterns = [
        "if you loved me",
        "you owe me",
        "after everything i've done",
        "nobody else will",
        "you're lucky to have me"
    ]
    
    static let gaslightingPatterns = [
        "you're overreacting",
        "that never happened",
        "you're crazy",
        "you're imagining things",
        "you're too sensitive",
        "i never said that"
    ]
    
    static let pressurePatterns = [
        "you have to",
        "you need to",
        "prove it",
        "if you don't",
        "everyone else does"
    ]
}

// MARK: - Safety Models

struct SafetyAnalysis {
    let flags: [RiskFlag]
    let overallRisk: RiskLevel
    let recommendations: [String]
    let supportResources: [SupportResource]
}

enum RiskLevel {
    case none, low, medium, high
}

struct SupportResource: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let phone: String
    let website: String
}

extension RiskFlag {
    enum RiskType: String, Codable {
        case manipulation
        case gaslighting
        case pressuring
        case toxicity
        case redFlag = "red_flag"
        case violence
    }
}
```

### 2. Enhanced Coaching with Safety

Update `CoachingViewModel` to integrate safety:

```swift
import SwiftUI
import SwiftData

@Observable
final class CoachingViewModel {
    var isLoading = false
    var error: Error?
    var coaching: CoachingResponse?
    var safety: SafetyAnalysis?
    
    private let conversation: ConversationThread
    private let modelContext: ModelContext
    
    init(conversation: ConversationThread, modelContext: ModelContext) {
        self.conversation = conversation
        self.modelContext = modelContext
    }
    
    @MainActor
    func generateCoaching(intent: CoachingIntent, parameters: CoachingParameters) async {
        isLoading = true
        error = nil
        
        do {
            // Fetch messages
            let messages = try await fetchMessages()
            
            // Run safety analysis in parallel with coaching
            async let safetyTask = SafetyClassifier.shared.analyzeSafety(conversation: messages)
            async let coachingTask = LLMClient.shared.generateCoaching(
                conversation: messages,
                intent: intent,
                parameters: parameters
            )
            
            // Wait for both
            let (safetyResult, coachingResult) = try await (safetyTask, coachingTask)
            
            // Merge safety flags into coaching if needed
            var finalCoaching = coachingResult
            if !safetyResult.flags.isEmpty {
                finalCoaching.riskFlags.append(contentsOf: safetyResult.flags)
            }
            
            // Save coaching session
            let session = CoachingSession(
                intent: intent,
                contextMessages: messages.map { $0.id.uuidString },
                replies: finalCoaching.replies.map { reply in
                    CoachingReply(text: reply.text, rationale: reply.rationale, tone: reply.tone)
                },
                riskFlags: finalCoaching.riskFlags
            )
            session.conversationThread = conversation
            modelContext.insert(session)
            try modelContext.save()
            
            self.coaching = finalCoaching
            self.safety = safetyResult
            isLoading = false
            
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    private func fetchMessages() async throws -> [Message] {
        // Fetch messages from SwiftData
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.conversationThread?.id == conversation.id },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return try modelContext.fetch(descriptor)
    }
}
```

### 3. Safety Resources View

```swift
import SwiftUI

struct SafetyResourcesView: View {
    let analysis: SafetyAnalysis
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if analysis.overallRisk == .high {
                        urgentBanner
                    }
                    
                    if !analysis.recommendations.isEmpty {
                        recommendationsSection
                    }
                    
                    if !analysis.supportResources.isEmpty {
                        resourcesSection
                    }
                    
                    educationSection
                }
                .padding()
            }
            .navigationTitle("Safety Resources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 50))
                .foregroundColor(riskColor)
            
            Text("We noticed some concerning patterns")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Your safety and well-being matter. Here are some resources that might help.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var urgentBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("High Risk Detected")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            Text("If you feel unsafe, please reach out to one of the resources below. You deserve support.")
                .font(.subheadline)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
            
            ForEach(analysis.recommendations, id: \.self) { recommendation in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(recommendation)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support Resources")
                .font(.headline)
            
            ForEach(analysis.supportResources) { resource in
                ResourceCard(resource: resource)
            }
        }
    }
    
    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learn More")
                .font(.headline)
            
            Link(destination: URL(string: "https://www.loveisrespect.org/everyone-deserves-a-healthy-relationship/relationship-spectrum/")!) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Understanding Healthy vs. Unhealthy Relationships")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Love Is Respect")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var riskColor: Color {
        switch analysis.overallRisk {
        case .none, .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct ResourceCard: View {
    let resource: SupportResource
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resource.title)
                .font(.headline)
            
            Text(resource.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                if let url = URL(string: "tel:\(resource.phone.filter { $0.isNumber })") {
                    Link(destination: url) {
                        Label("Call", systemImage: "phone.fill")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                if let url = URL(string: resource.website) {
                    Link(destination: url) {
                        Label("Website", systemImage: "safari")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

### 4. UI Polish Enhancements

Add smooth loading states and animations:

```swift
// Enhanced loading view
struct CoachingLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.purple.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.purple, lineWidth: 4)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 8) {
                Text("Analyzing conversation...")
                    .font(.headline)
                
                Text("This may take a few seconds")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Enhanced error view
struct ErrorView: View {
    let error: Error
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onRetry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .fontWeight(.medium)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}
```

### 5. Offline Mode Handling

```swift
import Network

@Observable
final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private(set) var isConnected = true
    private(set) var connectionType: NWInterface.InterfaceType?
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}

// Offline banner view
struct OfflineBannerView: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("Offline - Some features unavailable")
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.2))
        .foregroundColor(.orange)
        .cornerRadius(8)
    }
}
```

## Implementation Tasks

### Day 1: Safety Enhancement
- [ ] Implement `SafetyClassifier` with hard rules
- [ ] Add AI pattern detection
- [ ] Create aggregation logic
- [ ] Build recommendation system
- [ ] Add support resources

### Day 2: Safety UI
- [ ] Build `SafetyResourcesView`
- [ ] Create `ResourceCard` component
- [ ] Add urgent alert banner
- [ ] Integrate with coaching flow
- [ ] Test with sample unsafe conversations

### Day 3: UI Polish
- [ ] Enhanced loading states
- [ ] Smooth animations throughout
- [ ] Improved error handling
- [ ] Better empty states
- [ ] Accessibility improvements (VoiceOver, Dynamic Type)

### Day 4: Performance & Offline
- [ ] Profile app with Instruments
- [ ] Optimize database queries
- [ ] Add network monitoring
- [ ] Implement offline mode UX
- [ ] Reduce memory footprint

### Day 5: Bug Fixes & Testing
- [ ] Fix all critical bugs
- [ ] Address edge cases
- [ ] Full regression testing
- [ ] Performance testing on devices
- [ ] Final polish

## Validation Criteria

### Safety Requirements
- ✅ Hard rules detect explicit threats/manipulation
- ✅ AI patterns catch subtle concerns
- ✅ >85% precision on safety detection
- ✅ False positive rate <15%
- ✅ Support resources shown for high-risk
- ✅ Recommendations are actionable

### UX Requirements
- ✅ Loading states feel responsive
- ✅ Animations are smooth (60fps)
- ✅ Error messages are helpful
- ✅ Offline mode is graceful
- ✅ Accessibility score >90% (Xcode)

### Performance Requirements
- ✅ App launch <2s
- ✅ Coaching generation <10s
- ✅ Memory usage <400MB
- ✅ No frame drops during animations
- ✅ Battery drain acceptable (<5%/hour active use)

## Testing Checklist

- [ ] Test safety detection with 20+ toxic examples
- [ ] Verify support resources display correctly
- [ ] Test offline mode (airplane mode)
- [ ] Run Xcode Accessibility Inspector
- [ ] Test with VoiceOver enabled
- [ ] Test with Dynamic Type (all sizes)
- [ ] Profile with Instruments (CPU, Memory, Energy)
- [ ] Test on iPhone 15 and iPhone 15 Pro
- [ ] Full regression test suite
- [ ] User acceptance testing (5 beta users)

## Handoff to Phase 5

### Deliverables
- ✅ Safety system operational
- ✅ UI polished and accessible
- ✅ Performance optimized
- ✅ Offline mode handled
- ✅ Critical bugs fixed

### Ready for Phase 5 When:
1. Safety detection working accurately
2. No critical bugs remaining
3. Performance targets met
4. Accessibility standards met
5. User testing feedback incorporated

---

**Estimated Effort:** 40 hours (1 full-time engineer, 1 week)  
**Dependencies:** Phase 3 complete  
**Blockers:** None

