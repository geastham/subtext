//
//  CoachingSession.swift
//  Subtext
//
//  Created by Codegen
//  Phase 1: Foundation & Data Layer
//  Updated: Phase 3 - AI Integration & Coaching
//

import SwiftData
import Foundation

// MARK: - Coaching Intent

enum CoachingIntent: String, Codable, CaseIterable {
    case reply = "Reply"
    case interpret = "Interpret"
    case boundary = "Set Boundary"
    case flirt = "Flirt"
    case conflict = "Resolve Conflict"

    var icon: String {
        switch self {
        case .reply: return "message.fill"
        case .interpret: return "eye.fill"
        case .boundary: return "hand.raised.fill"
        case .flirt: return "heart.fill"
        case .conflict: return "arrow.triangle.2.circlepath"
        }
    }

    var description: String {
        switch self {
        case .reply: return "Craft a reply"
        case .interpret: return "Understand their message"
        case .boundary: return "Set a boundary"
        case .flirt: return "Be playful"
        case .conflict: return "Navigate disagreement"
        }
    }
}

// MARK: - Coaching Parameters

struct CoachingParameters: Codable, Equatable {
    var tone: Tone
    var verbosity: Verbosity
    var formality: Formality

    enum Tone: String, Codable, CaseIterable {
        case warm
        case neutral
        case direct
    }

    enum Verbosity: String, Codable, CaseIterable {
        case concise
        case balanced
        case detailed
    }

    enum Formality: String, Codable, CaseIterable {
        case casual
        case moderate
        case formal
    }

    static let `default` = CoachingParameters(
        tone: .warm,
        verbosity: .balanced,
        formality: .casual
    )
}

// MARK: - Coaching Session Model

@Model
final class CoachingSession {
    @Attribute(.unique) var id: UUID
    var intent: CoachingIntent
    var contextMessages: [String]  // Message IDs for context
    var summary: String
    var replies: [CoachingReply]
    var riskFlags: [RiskFlag]
    var followUpQuestions: [String]
    var parameters: CoachingParameters
    var createdAt: Date
    var conversationThread: ConversationThread?

    init(
        id: UUID = UUID(),
        intent: CoachingIntent,
        contextMessages: [String] = [],
        summary: String = "",
        replies: [CoachingReply] = [],
        riskFlags: [RiskFlag] = [],
        followUpQuestions: [String] = [],
        parameters: CoachingParameters = .default,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.intent = intent
        self.contextMessages = contextMessages
        self.summary = summary
        self.replies = replies
        self.riskFlags = riskFlags
        self.followUpQuestions = followUpQuestions
        self.parameters = parameters
        self.createdAt = createdAt
    }
}

// MARK: - Coaching Response (for LLM output parsing)

struct CoachingResponse: Codable {
    let summary: String
    let replies: [CoachingReply]
    let riskFlags: [RiskFlag]
    let followUpQuestions: [String]

    init(summary: String, replies: [CoachingReply], riskFlags: [RiskFlag] = [], followUpQuestions: [String] = []) {
        self.summary = summary
        self.replies = replies
        self.riskFlags = riskFlags
        self.followUpQuestions = followUpQuestions
    }
}

// MARK: - Coaching Reply

struct CoachingReply: Codable, Identifiable, Equatable {
    var id: UUID
    let text: String
    let rationale: String
    let tone: String  // "casual", "direct", "warm", "playful", "firm"

    init(id: UUID = UUID(), text: String, rationale: String, tone: String) {
        self.id = id
        self.text = text
        self.rationale = rationale
        self.tone = tone
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.text = try container.decode(String.self, forKey: .text)
        self.rationale = try container.decode(String.self, forKey: .rationale)
        self.tone = try container.decode(String.self, forKey: .tone)
    }

    enum CodingKeys: String, CodingKey {
        case text, rationale, tone
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(rationale, forKey: .rationale)
        try container.encode(tone, forKey: .tone)
    }
}

// MARK: - Risk Flag

struct RiskFlag: Codable, Equatable {
    let type: RiskType
    let severity: RiskSeverity
    let description: String
    let evidence: [String]  // Message excerpts

    enum RiskType: String, Codable, CaseIterable {
        case manipulation
        case gaslighting
        case pressuring
        case toxicity
        case redFlag = "red_flag"
    }

    enum RiskSeverity: String, Codable, CaseIterable {
        case low
        case medium
        case high
    }
}
