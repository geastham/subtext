//
//  Message.swift
//  Subtext
//
//  Created by Codegen
//  Phase 1: Foundation & Data Layer
//

import SwiftData
import Foundation

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var text: String
    var sender: String  // "me" or participant name
    var timestamp: Date
    var isFromUser: Bool
    var conversationThread: ConversationThread?
    
    init(
        id: UUID = UUID(),
        text: String,
        sender: String,
        timestamp: Date = Date(),
        isFromUser: Bool = false
    ) {
        self.id = id
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
        self.isFromUser = isFromUser
    }
}
