//
//  PromptBuilderTests.swift
//  Subtext
//
//  Created by Codegen
//  Phase 3: AI Integration & Coaching
//

import XCTest
@testable import Subtext

final class PromptBuilderTests: XCTestCase {

    // MARK: - Prompt Structure Tests

    func testPromptContainsIntent() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("INTENT"), "Prompt should contain INTENT section")
    }

    func testPromptContainsOutputFormat() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("OUTPUT FORMAT"), "Prompt should contain OUTPUT FORMAT section")
        XCTAssertTrue(prompt.contains("JSON"), "Prompt should specify JSON output")
    }

    func testPromptContainsConversationContext() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("CONVERSATION CONTEXT"), "Prompt should contain conversation context")
        XCTAssertTrue(prompt.contains("Sarah"), "Prompt should contain sender names")
        XCTAssertTrue(prompt.contains("dinner"), "Prompt should contain message content")
    }

    func testPromptContainsUserPreferences() {
        let messages = createSampleMessages()
        let params = CoachingParameters(tone: .warm, verbosity: .balanced, formality: .casual)
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: params
        )

        XCTAssertTrue(prompt.contains("USER PREFERENCES"), "Prompt should contain user preferences")
        XCTAssertTrue(prompt.contains("warm"), "Prompt should contain tone preference")
        XCTAssertTrue(prompt.contains("balanced"), "Prompt should contain verbosity preference")
        XCTAssertTrue(prompt.contains("casual"), "Prompt should contain formality preference")
    }

    // MARK: - Intent-Specific Prompts

    func testReplyIntentPrompt() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("Help craft a reply"), "Reply intent should have correct description")
    }

    func testInterpretIntentPrompt() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .interpret,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("Interpret their message"), "Interpret intent should have correct description")
        XCTAssertTrue(prompt.contains("subtext"), "Interpret intent should mention subtext")
    }

    func testBoundaryIntentPrompt() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .boundary,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("Set a boundary"), "Boundary intent should have correct description")
        XCTAssertTrue(prompt.contains("healthy"), "Boundary intent should emphasize healthy boundaries")
    }

    func testFlirtIntentPrompt() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .flirt,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("Flirt playfully"), "Flirt intent should have correct description")
        XCTAssertTrue(prompt.contains("authentic"), "Flirt intent should emphasize authenticity")
    }

    func testConflictIntentPrompt() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .conflict,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("Navigate conflict"), "Conflict intent should have correct description")
        XCTAssertTrue(prompt.contains("de-escalation"), "Conflict intent should mention de-escalation")
    }

    // MARK: - System Prompt Tests

    func testSystemPromptContainsCorePrinciples() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("Subtext"), "Prompt should identify as Subtext")
        XCTAssertTrue(prompt.contains("Privacy"), "Prompt should mention privacy")
        XCTAssertTrue(prompt.contains("Safety"), "Prompt should mention safety")
        XCTAssertTrue(prompt.contains("Empowerment"), "Prompt should mention empowerment")
    }

    func testSystemPromptContainsRoleDefinition() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("conversation coach"), "Prompt should define role as conversation coach")
        XCTAssertTrue(prompt.contains("3 distinct reply options"), "Prompt should specify 3 reply options")
    }

    // MARK: - Output Schema Tests

    func testOutputSchemaIncludesAllFields() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("\"summary\""), "Schema should include summary field")
        XCTAssertTrue(prompt.contains("\"replies\""), "Schema should include replies field")
        XCTAssertTrue(prompt.contains("\"riskFlags\""), "Schema should include riskFlags field")
        XCTAssertTrue(prompt.contains("\"followUpQuestions\""), "Schema should include followUpQuestions field")
    }

    func testOutputSchemaIncludesReplyFields() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("\"text\""), "Reply schema should include text field")
        XCTAssertTrue(prompt.contains("\"rationale\""), "Reply schema should include rationale field")
        XCTAssertTrue(prompt.contains("\"tone\""), "Reply schema should include tone field")
    }

    func testOutputSchemaIncludesRiskFlagFields() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("\"type\""), "RiskFlag schema should include type field")
        XCTAssertTrue(prompt.contains("\"severity\""), "RiskFlag schema should include severity field")
        XCTAssertTrue(prompt.contains("\"description\""), "RiskFlag schema should include description field")
        XCTAssertTrue(prompt.contains("\"evidence\""), "RiskFlag schema should include evidence field")
    }

    // MARK: - Message Context Tests

    func testContextIncludesRecentMessages() {
        var messages: [Message] = []
        for i in 0..<30 {
            messages.append(Message(
                text: "Message \(i)",
                sender: i % 2 == 0 ? "Me" : "Other",
                timestamp: Date().addingTimeInterval(TimeInterval(-3000 + i * 100)),
                isFromUser: i % 2 == 0
            ))
        }

        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        // Should include recent messages (last 20)
        XCTAssertTrue(prompt.contains("Message 29"), "Should include most recent message")
        XCTAssertTrue(prompt.contains("Message 20"), "Should include message from near the cutoff")

        // Should not include very old messages (before last 20)
        XCTAssertFalse(prompt.contains("Message 0"), "Should not include oldest messages")
    }

    func testContextFormatsMessagesCorrectly() {
        let messages = createSampleMessages()
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        XCTAssertTrue(prompt.contains("[Sarah]:"), "Should format other's messages with their name")
        XCTAssertTrue(prompt.contains("[Me]:"), "Should format user's messages with 'Me'")
    }

    // MARK: - Parameters Tests

    func testDifferentTonesInPrompt() {
        let messages = createSampleMessages()

        for tone in CoachingParameters.Tone.allCases {
            let params = CoachingParameters(tone: tone, verbosity: .balanced, formality: .casual)
            let prompt = PromptBuilder.buildCoachingPrompt(
                conversation: messages,
                intent: .reply,
                parameters: params
            )

            XCTAssertTrue(prompt.contains(tone.rawValue), "Prompt should include \(tone.rawValue) tone")
        }
    }

    func testDifferentVerbosityInPrompt() {
        let messages = createSampleMessages()

        for verbosity in CoachingParameters.Verbosity.allCases {
            let params = CoachingParameters(tone: .warm, verbosity: verbosity, formality: .casual)
            let prompt = PromptBuilder.buildCoachingPrompt(
                conversation: messages,
                intent: .reply,
                parameters: params
            )

            XCTAssertTrue(prompt.contains(verbosity.rawValue), "Prompt should include \(verbosity.rawValue) verbosity")
        }
    }

    // MARK: - Simple Prompt Tests

    func testInterpretationPrompt() {
        let message = "I'm not mad, I'm just disappointed"
        let prompt = PromptBuilder.buildInterpretationPrompt(message: message)

        XCTAssertTrue(prompt.contains(message), "Should include the message to interpret")
        XCTAssertTrue(prompt.contains("subtext"), "Should mention subtext")
        XCTAssertTrue(prompt.contains("literal meaning"), "Should ask about literal meaning")
    }

    func testQuickReplyPrompt() {
        let message = "Want to hang out?"
        let prompt = PromptBuilder.buildQuickReplyPrompt(lastMessage: message, tone: .warm)

        XCTAssertTrue(prompt.contains(message), "Should include the message to reply to")
        XCTAssertTrue(prompt.contains("warm"), "Should include the requested tone")
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
