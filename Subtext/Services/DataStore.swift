//
//  DataStore.swift
//  Subtext
//
//  Created by Codegen
//  Phase 1: Foundation & Data Layer
//

import SwiftData
import SwiftUI

@Observable
final class DataStore {
    var modelContainer: ModelContainer
    var modelContext: ModelContext
    
    static let shared = DataStore()
    
    private init() {
        let schema = Schema([
            ConversationThread.self,
            Message.self,
            CoachingSession.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    func save() throws {
        try modelContext.save()
    }
    
    func deleteAll() throws {
        // Delete all conversations (cascade will handle messages & sessions)
        try modelContext.delete(model: ConversationThread.self)
        try save()
    }
    
    // MARK: - Conversation Operations
    
    func createConversation(title: String, participants: [String]) throws -> ConversationThread {
        let conversation = ConversationThread(
            title: title,
            participants: participants
        )
        modelContext.insert(conversation)
        try save()
        return conversation
    }
    
    func deleteConversation(_ conversation: ConversationThread) throws {
        modelContext.delete(conversation)
        try save()
    }
    
    // MARK: - Message Operations
    
    func addMessage(
        to conversation: ConversationThread,
        text: String,
        sender: String,
        isFromUser: Bool
    ) throws -> Message {
        let message = Message(
            text: text,
            sender: sender,
            isFromUser: isFromUser
        )
        message.conversationThread = conversation
        conversation.messages.append(message)
        conversation.messageCount += 1
        conversation.updatedAt = Date()
        
        modelContext.insert(message)
        try save()
        return message
    }
}

