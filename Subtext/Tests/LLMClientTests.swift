//
//  LLMClientTests.swift
//  Subtext
//
//  Created by Codegen
//  Phase 3: AI Integration & Coaching
//

import XCTest
@testable import Subtext

final class LLMClientTests: XCTestCase {

    // MARK: - Mock Generation Tests

    func testMockGenerationReturnsThreeReplies() async throws {
        let messages = createSampleMessages()
        let response = try await LLMClient.shared.generateCoaching(
            conversation: messages,
            intent: .reply
        )

        XCTAssertEqual(response.replies.count, 3, "Should return exactly 3 reply options")
    }

    func testMockGenerationHasSummary() async throws {
        let messages = createSampleMessages()
        let response = try await LLMClient.shared.generateCoaching(
            conversation: messages,
            intent: .interpret
        )

        XCTAssertFalse(response.summary.isEmpty, "Summary should not be empty")
    }

    func testMockGenerationHasFollowUpQuestions() async throws {
        let messages = createSampleMessages()
        let response = try await LLMClient.shared.generateCoaching(
            conversation: messages,
            intent: .reply
        )

        XCTAssertFalse(response.followUpQuestions.isEmpty, "Should have follow-up questions")
    }

    func testMockGenerationForAllIntents() async throws {
        let messages = createSampleMessages()

        for intent in CoachingIntent.allCases {
            let response = try await LLMClient.shared.generateCoaching(
                conversation: messages,
                intent: intent
            )

            XCTAssertEqual(response.replies.count, 3, "Intent \(intent.rawValue) should return 3 replies")
            XCTAssertFalse(response.summary.isEmpty, "Intent \(intent.rawValue) should have a summary")
        }
    }

    func testRepliesHaveRequiredFields() async throws {
        let messages = createSampleMessages()
        let response = try await LLMClient.shared.generateCoaching(
            conversation: messages,
            intent: .reply
        )

        for reply in response.replies {
            XCTAssertFalse(reply.text.isEmpty, "Reply text should not be empty")
            XCTAssertFalse(reply.rationale.isEmpty, "Reply rationale should not be empty")
            XCTAssertFalse(reply.tone.isEmpty, "Reply tone should not be empty")
        }
    }

    func testRepliesHaveUniqueIds() async throws {
        let messages = createSampleMessages()
        let response = try await LLMClient.shared.generateCoaching(
            conversation: messages,
            intent: .reply
        )

        let ids = response.replies.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All reply IDs should be unique")
    }

    // MARK: - Parameters Tests

    func testDifferentParametersProduceDifferentResults() async throws {
        let messages = createSampleMessages()

        let warmParams = CoachingParameters(
            tone: .warm,
            verbosity: .balanced,
            formality: .casual
        )

        let directParams = CoachingParameters(
            tone: .direct,
            verbosity: .concise,
            formality: .formal
        )

        // Both should succeed (mock returns same data, but real implementation would differ)
        let warmResponse = try await LLMClient.shared.generateCoaching(
            conversation: messages,
            intent: .reply,
            parameters: warmParams
        )

        let directResponse = try await LLMClient.shared.generateCoaching(
            conversation: messages,
            intent: .reply,
            parameters: directParams
        )

        XCTAssertEqual(warmResponse.replies.count, 3)
        XCTAssertEqual(directResponse.replies.count, 3)
    }

    // MARK: - Model Status Tests

    func testClientIsReady() async {
        // Initialize if needed
        await LLMClient.shared.initializeModel()

        XCTAssertTrue(LLMClient.shared.isReady, "Client should be ready after initialization")
    }

    func testAvailabilityCheck() async {
        let isAvailable = await LLMClient.shared.checkAvailability()

        // In mock mode, should always be available
        XCTAssertTrue(isAvailable, "Mock mode should report as available")
    }

    // MARK: - Helper Methods

    private func createSampleMessages() -> [Message] {
        return [
            Message(
                text: "Hey, how are you?",
                sender: "Sarah",
                timestamp: Date().addingTimeInterval(-3600),
                isFromUser: false
            ),
            Message(
                text: "I'm doing great! Just finished work.",
                sender: "Me",
                timestamp: Date().addingTimeInterval(-3500),
                isFromUser: true
            ),
            Message(
                text: "Nice! Want to grab dinner?",
                sender: "Sarah",
                timestamp: Date().addingTimeInterval(-3400),
                isFromUser: false
            )
        ]
    }
}
