//
//  SafetyClassifier.swift
//  Subtext
//
//  Created by Codegen
//  Phase 4: Safety & Polish
//

import Foundation

// MARK: - Hard Rules Patterns

struct HardRules {
    static let violencePatterns = [
        "i'll hurt you",
        "i'll kill",
        "you better",
        "or else",
        "i'll make you",
        "you'll regret",
        "watch your back",
        "you're dead",
        "i will destroy"
    ]

    static let manipulationPatterns = [
        "if you loved me",
        "you owe me",
        "after everything i've done",
        "nobody else will",
        "you're lucky to have me",
        "you made me do this",
        "i do everything for you",
        "you need me"
    ]

    static let gaslightingPatterns = [
        "you're overreacting",
        "that never happened",
        "you're crazy",
        "you're imagining things",
        "you're too sensitive",
        "i never said that",
        "you're making things up",
        "stop being so dramatic",
        "you always twist things"
    ]

    static let pressurePatterns = [
        "you have to",
        "you need to",
        "prove it",
        "if you don't",
        "everyone else does",
        "don't you trust me",
        "you owe me this",
        "just this once"
    ]
}

// MARK: - Safety Classifier Actor

actor SafetyClassifier {
    static let shared = SafetyClassifier()

    private init() {}

    // MARK: - Comprehensive Safety Analysis

    /// Analyze a conversation for safety concerns
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

    // MARK: - Hard Rules Check

    private func checkHardRules(_ conversation: [Message]) async -> [RiskFlag] {
        var flags: [RiskFlag] = []

        for message in conversation where !message.isFromUser {
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
        let response = try await LLMClient.shared.generateSafetyAnalysis(
            conversation: conversation
        )

        return response.flags
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

        // Deduplicate recommendations
        return Array(Set(recommendations))
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
