#!/bin/bash

# Create CoachingSession.swift
cat > Subtext/Models/CoachingSession.swift << 'EOF'
//
//  CoachingSession.swift
//  Subtext
//
//  Created by Codegen
//  Phase 1: Foundation & Data Layer
//

import SwiftData
import Foundation

enum CoachingIntent: String, Codable, CaseIterable {
    case reply = "Reply"
    case interpret = "Interpret"
    case boundary = "Set Boundary"
    case flirt = "Flirt"
    case conflict = "Resolve Conflict"
}

@Model
final class CoachingSession {
    @Attribute(.unique) var id: UUID
    var intent: CoachingIntent
    var contextMessages: [String]  // Message IDs for context
    var replies: [CoachingReply]
    var riskFlags: [RiskFlag]
    var createdAt: Date
    var conversationThread: ConversationThread?
    
    init(
        id: UUID = UUID(),
        intent: CoachingIntent,
        contextMessages: [String] = [],
        replies: [CoachingReply] = [],
        riskFlags: [RiskFlag] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.intent = intent
        self.contextMessages = contextMessages
        self.replies = replies
        self.riskFlags = riskFlags
        self.createdAt = createdAt
    }
}

struct CoachingReply: Codable {
    let text: String
    let rationale: String
    let tone: String  // "casual", "direct", "warm"
}

struct RiskFlag: Codable {
    let type: RiskType
    let severity: RiskSeverity
    let description: String
    let evidence: [String]  // Message excerpts
    
    enum RiskType: String, Codable {
        case manipulation
        case gaslighting
        case pressuring
        case toxicity
        case redFlag
    }
    
    enum RiskSeverity: String, Codable {
        case low
        case medium
        case high
    }
}
EOF

echo "Created CoachingSession.swift"

