//
//  DataStoreTests.swift
//  Subtext
//
//  Created by Codegen
//  Phase 5: Testing & Launch
//

import XCTest
import SwiftData
@testable import Subtext

final class DataStoreTests: XCTestCase {

    // MARK: - Test Environment Setup

    /// Create an in-memory model container for testing
    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            ConversationThread.self,
            Message.self,
            CoachingSession.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true, // Use in-memory for tests
            allowsSave: true
        )

        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - Conversation CRUD Tests

    func testCreateConversation() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(
            title: "Test Conversation",
            participants: ["Me", "Sarah"]
        )

        context.insert(conversation)
        try context.save()

        // Verify it was saved
        let descriptor = FetchDescriptor<ConversationThread>()
        let conversations = try context.fetch(descriptor)

        XCTAssertEqual(conversations.count, 1)
        XCTAssertEqual(conversations.first?.title, "Test Conversation")
        XCTAssertEqual(conversations.first?.participants, ["Me", "Sarah"])
    }

    func testCreateMultipleConversations() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        for i in 1...5 {
            let conversation = ConversationThread(
                title: "Conversation \(i)",
                participants: ["Me", "Person \(i)"]
            )
            context.insert(conversation)
        }
        try context.save()

        let descriptor = FetchDescriptor<ConversationThread>()
        let conversations = try context.fetch(descriptor)

        XCTAssertEqual(conversations.count, 5)
    }

    func testDeleteConversation() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        // Create conversation
        let conversation = ConversationThread(title: "To Delete")
        context.insert(conversation)
        try context.save()

        // Verify exists
        var descriptor = FetchDescriptor<ConversationThread>()
        var conversations = try context.fetch(descriptor)
        XCTAssertEqual(conversations.count, 1)

        // Delete
        context.delete(conversation)
        try context.save()

        // Verify deleted
        conversations = try context.fetch(descriptor)
        XCTAssertEqual(conversations.count, 0)
    }

    func testConversationUpdatedAt() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(title: "Test")
        let initialDate = conversation.updatedAt
        context.insert(conversation)
        try context.save()

        // Wait a tiny bit and update
        Thread.sleep(forTimeInterval: 0.1)
        conversation.title = "Updated Title"
        conversation.updatedAt = Date()
        try context.save()

        XCTAssertGreaterThan(conversation.updatedAt, initialDate)
    }

    // MARK: - Message CRUD Tests

    func testCreateMessage() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(title: "Test")
        context.insert(conversation)

        let message = Message(
            text: "Hello, World!",
            sender: "Me",
            isFromUser: true
        )
        message.conversationThread = conversation
        context.insert(message)

        try context.save()

        // Verify relationship
        XCTAssertEqual(conversation.messages.count, 1)
        XCTAssertEqual(conversation.messages.first?.text, "Hello, World!")
        XCTAssertEqual(conversation.messages.first?.sender, "Me")
        XCTAssertTrue(conversation.messages.first?.isFromUser ?? false)
    }

    func testCreateMultipleMessages() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(title: "Test")
        context.insert(conversation)

        let messages = [
            Message(text: "Hey!", sender: "Sarah", isFromUser: false),
            Message(text: "Hi!", sender: "Me", isFromUser: true),
            Message(text: "How are you?", sender: "Sarah", isFromUser: false),
            Message(text: "Great, thanks!", sender: "Me", isFromUser: true)
        ]

        for message in messages {
            message.conversationThread = conversation
            context.insert(message)
        }

        try context.save()

        XCTAssertEqual(conversation.messages.count, 4)
    }

    func testMessageBelongsToConversation() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(title: "Test")
        context.insert(conversation)

        let message = Message(text: "Test", sender: "Me", isFromUser: true)
        message.conversationThread = conversation
        context.insert(message)

        try context.save()

        XCTAssertEqual(message.conversationThread?.id, conversation.id)
    }

    // MARK: - Delete All Tests

    func testDeleteAll() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        // Create multiple conversations with messages
        for i in 1...3 {
            let conversation = ConversationThread(title: "Conversation \(i)")
            context.insert(conversation)

            for j in 1...3 {
                let message = Message(text: "Message \(j)", sender: "Test", isFromUser: false)
                message.conversationThread = conversation
                context.insert(message)
            }
        }
        try context.save()

        // Verify data exists
        var convDescriptor = FetchDescriptor<ConversationThread>()
        var conversations = try context.fetch(convDescriptor)
        XCTAssertEqual(conversations.count, 3)

        var msgDescriptor = FetchDescriptor<Message>()
        var messages = try context.fetch(msgDescriptor)
        XCTAssertEqual(messages.count, 9)

        // Delete all conversations
        try context.delete(model: ConversationThread.self)
        try context.save()

        // Verify empty
        conversations = try context.fetch(convDescriptor)
        XCTAssertTrue(conversations.isEmpty)
    }

    // MARK: - Coaching Session Tests

    func testCreateCoachingSession() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(title: "Test")
        context.insert(conversation)

        let session = CoachingSession(
            intent: .reply,
            summary: "Test summary",
            replies: [
                CoachingReply(text: "Reply 1", rationale: "Reason 1", tone: "warm"),
                CoachingReply(text: "Reply 2", rationale: "Reason 2", tone: "direct"),
                CoachingReply(text: "Reply 3", rationale: "Reason 3", tone: "casual")
            ]
        )
        session.conversationThread = conversation
        context.insert(session)

        try context.save()

        XCTAssertEqual(conversation.coachingSessions.count, 1)
        XCTAssertEqual(conversation.coachingSessions.first?.intent, .reply)
        XCTAssertEqual(conversation.coachingSessions.first?.replies.count, 3)
    }

    func testCoachingSessionWithRiskFlags() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(title: "Test")
        context.insert(conversation)

        let session = CoachingSession(
            intent: .boundary,
            summary: "Concerning patterns detected",
            replies: [],
            riskFlags: [
                RiskFlag(
                    type: .manipulation,
                    severity: .high,
                    description: "Manipulative language detected",
                    evidence: ["If you loved me..."]
                )
            ]
        )
        session.conversationThread = conversation
        context.insert(session)

        try context.save()

        XCTAssertEqual(conversation.coachingSessions.first?.riskFlags.count, 1)
        XCTAssertEqual(conversation.coachingSessions.first?.riskFlags.first?.type, .manipulation)
        XCTAssertEqual(conversation.coachingSessions.first?.riskFlags.first?.severity, .high)
    }

    // MARK: - Unique ID Tests

    func testConversationUniqueId() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conv1 = ConversationThread(title: "Conv 1")
        let conv2 = ConversationThread(title: "Conv 2")

        context.insert(conv1)
        context.insert(conv2)
        try context.save()

        XCTAssertNotEqual(conv1.id, conv2.id)
    }

    func testMessageUniqueId() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let msg1 = Message(text: "Hello", sender: "Me", isFromUser: true)
        let msg2 = Message(text: "Hi", sender: "Other", isFromUser: false)

        context.insert(msg1)
        context.insert(msg2)
        try context.save()

        XCTAssertNotEqual(msg1.id, msg2.id)
    }

    // MARK: - Fetch Descriptor Tests

    func testFetchConversationsByDate() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        // Create conversations with different dates
        let oldConv = ConversationThread(title: "Old")
        oldConv.createdAt = Date().addingTimeInterval(-86400 * 7) // 7 days ago
        context.insert(oldConv)

        let newConv = ConversationThread(title: "New")
        newConv.createdAt = Date()
        context.insert(newConv)

        try context.save()

        // Fetch sorted by date (newest first)
        var descriptor = FetchDescriptor<ConversationThread>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let conversations = try context.fetch(descriptor)

        XCTAssertEqual(conversations.count, 2)
        XCTAssertEqual(conversations.first?.title, "New")
        XCTAssertEqual(conversations.last?.title, "Old")
    }

    // MARK: - Edge Case Tests

    func testEmptyConversation() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(title: "")
        context.insert(conversation)
        try context.save()

        let descriptor = FetchDescriptor<ConversationThread>()
        let conversations = try context.fetch(descriptor)

        XCTAssertEqual(conversations.count, 1)
        XCTAssertEqual(conversations.first?.title, "")
        XCTAssertTrue(conversations.first?.messages.isEmpty ?? false)
    }

    func testMessageWithEmptyText() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let message = Message(text: "", sender: "Test", isFromUser: false)
        context.insert(message)
        try context.save()

        let descriptor = FetchDescriptor<Message>()
        let messages = try context.fetch(descriptor)

        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages.first?.text, "")
    }

    func testLargeConversation() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let conversation = ConversationThread(title: "Large")
        context.insert(conversation)

        // Create 100 messages
        for i in 1...100 {
            let message = Message(
                text: "Message \(i) with some content",
                sender: i % 2 == 0 ? "Me" : "Other",
                isFromUser: i % 2 == 0
            )
            message.conversationThread = conversation
            context.insert(message)
        }

        try context.save()

        XCTAssertEqual(conversation.messages.count, 100)
    }
}
