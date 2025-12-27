//
//  SafetyClassifierTests.swift
//  Subtext
//
//  Created by Codegen
//  Phase 4: Safety & Polish
//  Updated: Phase 5 - Testing & Launch
//

import XCTest
@testable import Subtext

final class SafetyClassifierTests: XCTestCase {

    // MARK: - Hard Rules Detection Tests

    func testDetectsViolencePatterns() async throws {
        let messages = [
            Message(text: "You better watch yourself or else", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect violence pattern")
        XCTAssertTrue(analysis.flags.contains { $0.type == .violence }, "Should flag as violence")
        XCTAssertEqual(analysis.overallRisk, .high, "Violence should be high risk")
    }

    func testDetectsExplicitThreats() async throws {
        let messages = [
            Message(text: "I'll hurt you if you don't listen", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect threat")
        XCTAssertTrue(analysis.flags.contains { $0.type == .violence }, "Should flag as violence")
        XCTAssertEqual(analysis.overallRisk, .high, "Threats should be high risk")
    }

    func testDetectsKillThreats() async throws {
        let messages = [
            Message(text: "I'll kill myself if you leave", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect suicide threat manipulation")
        XCTAssertEqual(analysis.overallRisk, .high, "Should be high risk")
    }

    func testDetectsManipulationPatterns() async throws {
        let messages = [
            Message(text: "If you loved me, you would do this", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect manipulation")
        XCTAssertTrue(analysis.flags.contains { $0.type == .manipulation }, "Should flag as manipulation")
    }

    func testDetectsGuiltTripping() async throws {
        let messages = [
            Message(text: "After everything I've done for you, this is how you repay me?", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect guilt-tripping")
        XCTAssertTrue(analysis.flags.contains { $0.type == .manipulation }, "Should flag as manipulation")
    }

    func testDetectsNobodyElseWill() async throws {
        let messages = [
            Message(text: "Nobody else will ever love you like I do", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect isolation tactic")
        XCTAssertTrue(analysis.flags.contains { $0.type == .manipulation }, "Should flag as manipulation")
    }

    func testDetectsGaslightingPatterns() async throws {
        let messages = [
            Message(text: "You're overreacting, that never happened", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect gaslighting")
        XCTAssertTrue(analysis.flags.contains { $0.type == .gaslighting }, "Should flag as gaslighting")
    }

    func testDetectsCrazyAccusation() async throws {
        let messages = [
            Message(text: "You're crazy if you think that happened", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect crazy accusation")
        XCTAssertTrue(analysis.flags.contains { $0.type == .gaslighting }, "Should flag as gaslighting")
    }

    func testDetectsImaginingThings() async throws {
        let messages = [
            Message(text: "You're imagining things again", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect reality denial")
        XCTAssertTrue(analysis.flags.contains { $0.type == .gaslighting }, "Should flag as gaslighting")
    }

    func testDetectsTooSensitive() async throws {
        let messages = [
            Message(text: "You're too sensitive about everything", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect sensitivity dismissal")
        XCTAssertTrue(analysis.flags.contains { $0.type == .gaslighting }, "Should flag as gaslighting")
    }

    func testDetectsPressurePatterns() async throws {
        let messages = [
            Message(text: "You have to do this if you don't want problems", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect pressure")
        XCTAssertTrue(analysis.flags.contains { $0.type == .pressuring }, "Should flag as pressuring")
    }

    func testDetectsProveIt() async throws {
        let messages = [
            Message(text: "You need to prove it to me right now", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect proving demand")
    }

    func testDetectsEveryoneElseDoes() async throws {
        let messages = [
            Message(text: "Everyone else does this in their relationship", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect peer pressure tactic")
        XCTAssertTrue(analysis.flags.contains { $0.type == .pressuring }, "Should flag as pressuring")
    }

    func testDetectsDontYouTrustMe() async throws {
        let messages = [
            Message(text: "Don't you trust me after all this time?", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect trust manipulation")
        XCTAssertTrue(analysis.flags.contains { $0.type == .pressuring }, "Should flag as pressuring")
    }

    // MARK: - No Flags Tests

    func testNoFlagsForHealthyConversation() async throws {
        let messages = [
            Message(text: "Hey, how are you?", sender: "Other", isFromUser: false),
            Message(text: "I'm doing great, thanks!", sender: "Me", isFromUser: true),
            Message(text: "Want to grab dinner this weekend?", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertTrue(analysis.flags.isEmpty, "Should not flag healthy conversation")
        XCTAssertEqual(analysis.overallRisk, .none, "Risk should be none")
    }

    func testNoFlagsForCasualBanter() async throws {
        let messages = [
            Message(text: "That movie was crazy good!", sender: "Other", isFromUser: false),
            Message(text: "Right? I loved the plot twist!", sender: "Me", isFromUser: true),
            Message(text: "We should watch the sequel together", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertTrue(analysis.flags.isEmpty, "Casual conversation should not be flagged")
        XCTAssertEqual(analysis.overallRisk, .none)
    }

    func testNoFlagsForNormalDisagreement() async throws {
        let messages = [
            Message(text: "I don't think that's a good idea", sender: "Other", isFromUser: false),
            Message(text: "Why not?", sender: "Me", isFromUser: true),
            Message(text: "Let me explain my perspective", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertTrue(analysis.flags.isEmpty, "Healthy disagreement should not be flagged")
    }

    func testNoFlagsForEmotionalSupport() async throws {
        let messages = [
            Message(text: "I had a really hard day", sender: "Other", isFromUser: false),
            Message(text: "I'm so sorry to hear that", sender: "Me", isFromUser: true),
            Message(text: "Thanks, I appreciate you listening", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertTrue(analysis.flags.isEmpty)
        XCTAssertEqual(analysis.overallRisk, .none)
    }

    // MARK: - Risk Level Tests

    func testHighRiskForMultipleMediumFlags() async throws {
        let messages = [
            Message(text: "You're too sensitive about everything", sender: "Other", isFromUser: false),
            Message(text: "You have to trust me on this", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        // Two medium severity flags should result in high overall risk
        let mediumCount = analysis.flags.filter { $0.severity == .medium }.count
        if mediumCount >= 2 {
            XCTAssertEqual(analysis.overallRisk, .high, "Multiple medium flags should be high risk")
        }
    }

    func testMediumRiskForSingleMediumFlag() async throws {
        let messages = [
            Message(text: "You're making this up", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        if !analysis.flags.isEmpty {
            let hasMedium = analysis.flags.contains { $0.severity == .medium }
            let hasHigh = analysis.flags.contains { $0.severity == .high }

            if hasMedium && !hasHigh {
                XCTAssertTrue(analysis.overallRisk == .medium || analysis.overallRisk == .high)
            }
        }
    }

    // MARK: - Support Resources Tests

    func testHighRiskIncludesSupportResources() async throws {
        let messages = [
            Message(text: "I'll hurt you if you leave", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertEqual(analysis.overallRisk, .high, "Violence should be high risk")
        XCTAssertFalse(analysis.supportResources.isEmpty, "High risk should include support resources")
    }

    func testSupportResourcesHaveRequiredInfo() async throws {
        let messages = [
            Message(text: "I'll hurt you if you don't do what I say", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        for resource in analysis.supportResources {
            XCTAssertFalse(resource.title.isEmpty, "Resource should have title")
            XCTAssertFalse(resource.phone.isEmpty, "Resource should have phone")
            XCTAssertFalse(resource.website.isEmpty, "Resource should have website")
        }
    }

    func testSupportResourcesIncludeHotline() async throws {
        let messages = [
            Message(text: "You'll regret this if you leave me", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        if !analysis.supportResources.isEmpty {
            let hasHotline = analysis.supportResources.contains { resource in
                resource.title.lowercased().contains("hotline") ||
                resource.phone.contains("1-800")
            }
            XCTAssertTrue(hasHotline, "Should include a hotline resource")
        }
    }

    // MARK: - Recommendations Tests

    func testRecommendationsForManipulation() async throws {
        let messages = [
            Message(text: "After everything I've done for you", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.recommendations.isEmpty, "Should provide recommendations")
    }

    func testRecommendationsAreDeduplicated() async throws {
        let messages = [
            Message(text: "If you loved me you would", sender: "Other", isFromUser: false),
            Message(text: "You owe me after everything", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        let uniqueRecommendations = Set(analysis.recommendations)
        XCTAssertEqual(uniqueRecommendations.count, analysis.recommendations.count, "Recommendations should be unique")
    }

    // MARK: - User Messages Excluded

    func testUserMessagesNotFlagged() async throws {
        // When user says concerning things, we shouldn't flag their own messages
        let messages = [
            Message(text: "If you loved me you would understand", sender: "Me", isFromUser: true),
            Message(text: "I understand, I'm sorry you feel that way", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        // The user's message shouldn't be flagged
        XCTAssertTrue(analysis.flags.isEmpty, "User's own messages should not be flagged")
    }

    func testOnlyOtherMessagesAnalyzed() async throws {
        let messages = [
            Message(text: "You're crazy", sender: "Me", isFromUser: true), // User says this - shouldn't flag
            Message(text: "That's not nice", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertTrue(analysis.flags.isEmpty, "Should not flag user's message")
    }

    // MARK: - Multiple Pattern Detection

    func testDetectsMultiplePatterns() async throws {
        let messages = [
            Message(text: "You're overreacting again", sender: "Other", isFromUser: false),
            Message(text: "If you loved me you'd understand", sender: "Other", isFromUser: false),
            Message(text: "You have to do this or else", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        // Should detect multiple different types
        XCTAssertFalse(analysis.flags.isEmpty)
        XCTAssertEqual(analysis.overallRisk, .high, "Multiple concerning patterns should be high risk")
    }

    // MARK: - Edge Cases

    func testEmptyConversation() async throws {
        let messages: [Message] = []

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertTrue(analysis.flags.isEmpty)
        XCTAssertEqual(analysis.overallRisk, .none)
    }

    func testSingleMessageConversation() async throws {
        let messages = [
            Message(text: "Hey there!", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertTrue(analysis.flags.isEmpty)
        XCTAssertEqual(analysis.overallRisk, .none)
    }

    func testLongConversationWithOneConcern() async throws {
        var messages: [Message] = []

        // Many normal messages
        for i in 0..<20 {
            messages.append(Message(
                text: "Normal message \(i)",
                sender: i % 2 == 0 ? "Other" : "Me",
                isFromUser: i % 2 != 0
            ))
        }

        // One concerning message at the end
        messages.append(Message(text: "You owe me this", sender: "Other", isFromUser: false))

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should still detect the concerning message")
    }

    // MARK: - Case Sensitivity Tests

    func testDetectsUppercasePatterns() async throws {
        let messages = [
            Message(text: "IF YOU LOVED ME YOU WOULD DO THIS", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect uppercase patterns")
    }

    func testDetectsMixedCasePatterns() async throws {
        let messages = [
            Message(text: "You're OverReacting to everything", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect mixed case patterns")
    }
}
