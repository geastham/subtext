//
//  IntegrationTests.swift
//  Subtext
//
//  Created by Codegen
//  Phase 5: Testing & Launch
//

import XCTest
import SwiftData
@testable import Subtext

/// Integration tests for end-to-end flows
final class IntegrationTests: XCTestCase {

    // MARK: - Test Environment

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            ConversationThread.self,
            Message.self,
            CoachingSession.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )

        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - Complete Import Flow Tests

    func testCompleteImportFlowIMessage() async throws {
        // Step 1: Parse conversation
        let sample = """
        [12/25/24, 10:30:45] Sarah: Hey there!
        [12/25/24, 10:31:00] John: Hi Sarah!
        [12/25/24, 10:31:30] Sarah: Want to grab coffee?
        """

        let parsed = try await ConversationParser.shared.parse(sample)

        // Verify parsing
        XCTAssertEqual(parsed.format, .iMessage)
        XCTAssertEqual(parsed.messages.count, 3)
        XCTAssertEqual(parsed.participants.count, 2)

        // Step 2: Save to data store
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(
            title: "Chat with Sarah",
            participants: Array(parsed.participants)
        )
        context.insert(conversation)

        for msg in parsed.messages {
            let message = Message(
                text: msg.text,
                sender: msg.sender ?? "Unknown",
                timestamp: msg.timestamp ?? Date(),
                isFromUser: msg.sender == "John" // Assume John is the user
            )
            message.conversationThread = conversation
            context.insert(message)
        }

        conversation.messageCount = parsed.messages.count
        try context.save()

        // Step 3: Verify saved correctly
        let descriptor = FetchDescriptor<ConversationThread>()
        let conversations = try context.fetch(descriptor)

        XCTAssertEqual(conversations.count, 1)
        XCTAssertEqual(conversations.first?.messages.count, 3)
        XCTAssertEqual(conversations.first?.participants.count, 2)
        XCTAssertTrue(conversations.first?.participants.contains("Sarah") ?? false)
    }

    func testCompleteImportFlowWhatsApp() async throws {
        // Step 1: Parse WhatsApp conversation
        let sample = """
        12/25/24, 10:30 - Sarah: Hey!
        12/25/24, 10:31 - John: Hi there!
        12/25/24, 10:32 - Sarah: How's it going?
        12/25/24, 10:33 - John: Great, thanks!
        """

        let parsed = try await ConversationParser.shared.parse(sample)

        // Verify parsing
        XCTAssertEqual(parsed.format, .whatsApp)
        XCTAssertEqual(parsed.messages.count, 4)

        // Step 2: Save to data store
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(
            title: "WhatsApp Chat",
            participants: Array(parsed.participants)
        )
        context.insert(conversation)

        for msg in parsed.messages {
            let message = Message(
                text: msg.text,
                sender: msg.sender ?? "Unknown",
                isFromUser: msg.sender == "John"
            )
            message.conversationThread = conversation
            context.insert(message)
        }

        try context.save()

        // Step 3: Verify
        XCTAssertEqual(conversation.messages.count, 4)
    }

    func testCompleteImportFlowManual() async throws {
        // Step 1: Parse manual format
        let sample = """
        Sarah: Hey!
        Me: Hi there!
        Sarah: Want to hang out?
        """

        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertEqual(parsed.format, .manual)
        XCTAssertEqual(parsed.messages.count, 3)

        // Step 2: Save
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(title: "Manual Import")
        context.insert(conversation)

        for msg in parsed.messages {
            let message = Message(
                text: msg.text,
                sender: msg.sender ?? "Unknown",
                isFromUser: msg.sender == "Me"
            )
            message.conversationThread = conversation
            context.insert(message)
        }

        try context.save()

        // Step 3: Verify user messages are correctly marked
        let userMessages = conversation.messages.filter { $0.isFromUser }
        XCTAssertEqual(userMessages.count, 1)
        XCTAssertEqual(userMessages.first?.text, "Hi there!")
    }

    // MARK: - Complete Coaching Flow Tests

    func testCompleteCoachingFlowReply() async throws {
        // Step 1: Create conversation with messages
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(title: "Dating Chat")
        context.insert(conversation)

        let messages = [
            Message(text: "Hey, how are you?", sender: "Sarah", isFromUser: false),
            Message(text: "I'm doing great!", sender: "Me", isFromUser: true),
            Message(text: "Want to grab dinner?", sender: "Sarah", isFromUser: false)
        ]

        for msg in messages {
            msg.conversationThread = conversation
            context.insert(msg)
        }

        try context.save()

        // Step 2: Generate coaching
        let coaching = try await LLMClient.shared.generateCoaching(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        // Step 3: Verify response structure
        XCTAssertFalse(coaching.summary.isEmpty, "Summary should not be empty")
        XCTAssertEqual(coaching.replies.count, 3, "Should have 3 reply options")

        for reply in coaching.replies {
            XCTAssertFalse(reply.text.isEmpty, "Reply text should not be empty")
            XCTAssertFalse(reply.rationale.isEmpty, "Reply rationale should not be empty")
            XCTAssertFalse(reply.tone.isEmpty, "Reply tone should not be empty")
        }

        // Step 4: Save coaching session
        let session = CoachingSession(
            intent: .reply,
            contextMessages: messages.map { $0.id.uuidString },
            summary: coaching.summary,
            replies: coaching.replies,
            riskFlags: coaching.riskFlags,
            followUpQuestions: coaching.followUpQuestions
        )
        session.conversationThread = conversation
        context.insert(session)

        try context.save()

        // Step 5: Verify session saved
        XCTAssertEqual(conversation.coachingSessions.count, 1)
        XCTAssertEqual(conversation.coachingSessions.first?.replies.count, 3)
    }

    func testCompleteCoachingFlowAllIntents() async throws {
        let messages = [
            Message(text: "Hey!", sender: "Sarah", isFromUser: false),
            Message(text: "Hi there", sender: "Me", isFromUser: true)
        ]

        for intent in CoachingIntent.allCases {
            let coaching = try await LLMClient.shared.generateCoaching(
                conversation: messages,
                intent: intent,
                parameters: .default
            )

            XCTAssertFalse(coaching.summary.isEmpty, "\(intent) should have summary")
            XCTAssertEqual(coaching.replies.count, 3, "\(intent) should have 3 replies")
        }
    }

    // MARK: - Safety Integration Tests

    func testSafetyAnalysisIntegration() async throws {
        // Create concerning conversation
        let messages = [
            Message(text: "If you loved me, you would do this", sender: "Other", isFromUser: false),
            Message(text: "I don't know...", sender: "Me", isFromUser: true),
            Message(text: "You owe me after everything I've done for you", sender: "Other", isFromUser: false)
        ]

        // Run safety analysis
        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        // Verify flags detected
        XCTAssertFalse(analysis.flags.isEmpty, "Should detect safety concerns")
        XCTAssertTrue(analysis.flags.contains { $0.type == .manipulation }, "Should detect manipulation")
        XCTAssertEqual(analysis.overallRisk, .high, "Should be high risk")
        XCTAssertFalse(analysis.supportResources.isEmpty, "Should include support resources")
    }

    func testSafetyAnalysisHealthyConversation() async throws {
        let messages = [
            Message(text: "Hey, how was your day?", sender: "Sarah", isFromUser: false),
            Message(text: "Really good! How about yours?", sender: "Me", isFromUser: true),
            Message(text: "Great! Want to catch up this weekend?", sender: "Sarah", isFromUser: false)
        ]

        let analysis = try await SafetyClassifier.shared.analyzeSafety(conversation: messages)

        XCTAssertTrue(analysis.flags.isEmpty, "Healthy conversation should have no flags")
        XCTAssertEqual(analysis.overallRisk, .none, "Should have no risk")
    }

    // MARK: - Prompt Builder Integration Tests

    func testPromptBuilderIntegration() {
        let messages = [
            Message(text: "Hey", sender: "Sarah", isFromUser: false),
            Message(text: "Hi!", sender: "Me", isFromUser: true),
            Message(text: "Want to get coffee?", sender: "Sarah", isFromUser: false)
        ]

        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )

        // Verify prompt contains all required sections
        XCTAssertTrue(prompt.contains("INTENT"), "Should contain intent section")
        XCTAssertTrue(prompt.contains("CONVERSATION CONTEXT"), "Should contain conversation")
        XCTAssertTrue(prompt.contains("OUTPUT FORMAT"), "Should contain output schema")
        XCTAssertTrue(prompt.contains("Sarah"), "Should contain participant names")
        XCTAssertTrue(prompt.contains("coffee"), "Should contain message content")
    }

    // MARK: - Full User Journey Tests

    func testFullUserJourneyFromImportToCoaching() async throws {
        // Simulate complete user journey

        // 1. User pastes conversation
        let rawText = """
        [12/25/24, 10:30:45] Alex: Hey! 😊
        [12/25/24, 10:31:00] Me: Hey Alex! How's it going?
        [12/25/24, 10:31:30] Alex: Pretty good! I was thinking about you
        [12/25/24, 10:32:00] Alex: Want to grab dinner sometime?
        """

        // 2. Parse conversation
        let parsed = try await ConversationParser.shared.parse(rawText)
        XCTAssertEqual(parsed.messages.count, 4)

        // 3. Save to data store
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(
            title: "Chat with Alex",
            participants: Array(parsed.participants)
        )
        context.insert(conversation)

        var savedMessages: [Message] = []
        for msg in parsed.messages {
            let message = Message(
                text: msg.text,
                sender: msg.sender ?? "Unknown",
                timestamp: msg.timestamp ?? Date(),
                isFromUser: msg.sender == "Me"
            )
            message.conversationThread = conversation
            context.insert(message)
            savedMessages.append(message)
        }

        try context.save()

        // 4. User requests coaching (Reply intent)
        let coaching = try await LLMClient.shared.generateCoaching(
            conversation: savedMessages,
            intent: .reply,
            parameters: CoachingParameters(tone: .warm, verbosity: .balanced, formality: .casual)
        )

        XCTAssertEqual(coaching.replies.count, 3)

        // 5. Save coaching session
        let session = CoachingSession(
            intent: .reply,
            summary: coaching.summary,
            replies: coaching.replies
        )
        session.conversationThread = conversation
        context.insert(session)

        try context.save()

        // 6. Verify complete state
        XCTAssertEqual(conversation.messages.count, 4)
        XCTAssertEqual(conversation.coachingSessions.count, 1)
        XCTAssertEqual(conversation.coachingSessions.first?.replies.count, 3)
    }

    func testFullUserJourneyWithSafetyFlags() async throws {
        // User imports concerning conversation

        // 1. Parse
        let rawText = """
        [12/25/24, 10:30:45] Partner: You're overreacting again
        [12/25/24, 10:31:00] Me: I don't think I am
        [12/25/24, 10:31:30] Partner: If you loved me you wouldn't question me
        """

        let parsed = try await ConversationParser.shared.parse(rawText)

        // 2. Save
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(title: "Concerning Chat")
        context.insert(conversation)

        var savedMessages: [Message] = []
        for msg in parsed.messages {
            let message = Message(
                text: msg.text,
                sender: msg.sender ?? "Unknown",
                isFromUser: msg.sender == "Me"
            )
            message.conversationThread = conversation
            context.insert(message)
            savedMessages.append(message)
        }

        try context.save()

        // 3. Safety analysis
        let safetyAnalysis = try await SafetyClassifier.shared.analyzeSafety(
            conversation: savedMessages
        )

        // 4. Verify safety flags
        XCTAssertFalse(safetyAnalysis.flags.isEmpty)
        XCTAssertEqual(safetyAnalysis.overallRisk, .high)
        XCTAssertTrue(safetyAnalysis.flags.contains { $0.type == .gaslighting || $0.type == .manipulation })

        // 5. Get coaching with boundary intent
        let coaching = try await LLMClient.shared.generateCoaching(
            conversation: savedMessages,
            intent: .boundary,
            parameters: .default
        )

        XCTAssertEqual(coaching.replies.count, 3)

        // 6. Verify support resources are available for high-risk
        XCTAssertFalse(safetyAnalysis.supportResources.isEmpty)
    }

    // MARK: - Error Handling Integration Tests

    func testEmptyConversationHandling() async {
        do {
            _ = try await ConversationParser.shared.parse("")
            XCTFail("Should throw error for empty text")
        } catch {
            XCTAssertTrue(error is ConversationParser.ParserError)
        }
    }

    func testMalformedConversationHandling() async throws {
        // Even malformed text should parse (as manual format)
        let malformed = "This is just random text without any structure whatsoever"

        // Parser should handle gracefully
        do {
            let parsed = try await ConversationParser.shared.parse(malformed)
            // Either parses as unknown/manual or throws
            XCTAssertTrue(parsed.format == .unknown || parsed.format == .manual)
        } catch {
            // Error is also acceptable
            XCTAssertTrue(error is ConversationParser.ParserError)
        }
    }

    // MARK: - Performance Tests

    func testLargeConversationPerformance() async throws {
        // Generate a large conversation
        var rawText = ""
        for i in 1...100 {
            let sender = i % 2 == 0 ? "Me" : "Sarah"
            rawText += "\(sender): Message number \(i) with some content here.\n"
        }

        // Measure parse time
        let startTime = Date()
        let parsed = try await ConversationParser.shared.parse(rawText)
        let parseTime = Date().timeIntervalSince(startTime)

        XCTAssertEqual(parsed.messages.count, 100)
        XCTAssertLessThan(parseTime, 1.0, "Parsing 100 messages should take less than 1 second")
    }

    func testCoachingGenerationPerformance() async throws {
        let messages = [
            Message(text: "Hey!", sender: "Sarah", isFromUser: false),
            Message(text: "Hi there!", sender: "Me", isFromUser: true)
        ]

        // In mock mode, should be fast
        let startTime = Date()
        let _ = try await LLMClient.shared.generateCoaching(
            conversation: messages,
            intent: .reply,
            parameters: .default
        )
        let generationTime = Date().timeIntervalSince(startTime)

        // Mock has 1.5s delay, so should be around that
        XCTAssertLessThan(generationTime, 5.0, "Coaching generation should complete within 5 seconds")
    }
}
