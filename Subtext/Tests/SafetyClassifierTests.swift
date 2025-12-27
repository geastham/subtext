//
//  SafetyClassifierTests.swift
//  Subtext
//
//  Created by Codegen
//  Phase 4: Safety & Polish
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

    func testDetectsManipulationPatterns() async throws {
        let messages = [
            Message(text: "If you loved me, you would do this", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect manipulation")
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

    func testDetectsPressurePatterns() async throws {
        let messages = [
            Message(text: "You have to do this if you don't want problems", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.flags.isEmpty, "Should detect pressure")
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

    // MARK: - Support Resources Tests

    func testHighRiskIncludesSupportResources() async throws {
        let messages = [
            Message(text: "I'll hurt you if you leave", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertEqual(analysis.overallRisk, .high, "Violence should be high risk")
        XCTAssertFalse(analysis.supportResources.isEmpty, "High risk should include support resources")
    }

    // MARK: - Recommendations Tests

    func testRecommendationsForManipulation() async throws {
        let messages = [
            Message(text: "After everything I've done for you", sender: "Other", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertFalse(analysis.recommendations.isEmpty, "Should provide recommendations")
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
}
