//
//  ConversationThread.swift
//  Subtext
//
//  Created by Codegen
//  Phase 1: Foundation & Data Layer
//

import SwiftData
import Foundation

@Model
final class ConversationThread {
    @Attribute(.unique) var id: UUID
    var title: String
    var participants: [String]  // ["Me", "Sarah", etc.]
    var createdAt: Date
    var updatedAt: Date
    var messageCount: Int
    
    @Relationship(deleteRule: .cascade) var messages: [Message]
    @Relationship(deleteRule: .cascade) var coachingSessions: [CoachingSession]
    
    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        participants: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messageCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.participants = participants
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messageCount = messageCount
    }
}

