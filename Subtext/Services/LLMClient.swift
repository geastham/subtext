//
//  LLMClient.swift
//  Subtext
//
//  Created by Codegen
//  Phase 3: AI Integration & Coaching
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - LLM Client Actor

actor LLMClient {
    static let shared = LLMClient()

    enum LLMError: Error, LocalizedError {
        case modelNotLoaded
        case modelNotAvailable
        case generationFailed(String)
        case invalidResponse
        case parsingFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded:
                return "The AI model has not been loaded yet."
            case .modelNotAvailable:
                return "On-device AI is not available on this device."
            case .generationFailed(let message):
                return "Failed to generate response: \(message)"
            case .invalidResponse:
                return "The AI returned an invalid response."
            case .parsingFailed(let message):
                return "Failed to parse AI response: \(message)"
            }
        }
    }

    enum ModelStatus: Equatable {
        case notLoaded
        case loading
        case ready
        case unavailable(String)
    }

    private(set) var status: ModelStatus = .notLoaded

    #if canImport(FoundationModels)
    private var session: LanguageModelSession?
    #endif

    private init() {}

    // MARK: - Model Initialization

    /// Initialize the Foundation Models on-device LLM
    func initializeModel() async {
        guard status == .notLoaded else { return }

        status = .loading

        #if canImport(FoundationModels)
        do {
            // Check availability
            guard await LanguageModelSession.isAvailable else {
                status = .unavailable("On-device language model is not available on this device.")
                return
            }

            // Create a new session
            session = LanguageModelSession()
            status = .ready
            print("[LLMClient] Foundation Models initialized successfully")
        } catch {
            status = .unavailable(error.localizedDescription)
            print("[LLMClient] Failed to initialize: \(error)")
        }
        #else
        // Simulator or unsupported platform - use mock mode
        status = .ready
        print("[LLMClient] Running in mock mode (Foundation Models not available)")
        #endif
    }

    // MARK: - Check Availability

    /// Check if the model is ready for generation
    var isReady: Bool {
        status == .ready
    }

    /// Check if on-device AI is available
    func checkAvailability() async -> Bool {
        #if canImport(FoundationModels)
        return await LanguageModelSession.isAvailable
        #else
        return true // Mock mode always available
        #endif
    }

    // MARK: - Generate Coaching

    /// Generate coaching response for a conversation
    func generateCoaching(
        conversation: [Message],
        intent: CoachingIntent,
        parameters: CoachingParameters = .default
    ) async throws -> CoachingResponse {
        // Ensure model is initialized
        if status == .notLoaded {
            await initializeModel()
        }

        guard status == .ready else {
            if case .unavailable(let reason) = status {
                throw LLMError.modelNotAvailable
            }
            throw LLMError.modelNotLoaded
        }

        // Build the prompt
        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: conversation,
            intent: intent,
            parameters: parameters
        )

        #if canImport(FoundationModels)
        return try await generateWithFoundationModels(prompt: prompt)
        #else
        return try await generateMockResponse(intent: intent)
        #endif
    }

    #if canImport(FoundationModels)
    // MARK: - Foundation Models Generation

    private func generateWithFoundationModels(prompt: String) async throws -> CoachingResponse {
        guard let session = session else {
            throw LLMError.modelNotLoaded
        }

        do {
            // Generate response using Foundation Models
            let response = try await session.respond(to: prompt)
            let responseText = response.content

            // Extract JSON from the response
            return try parseCoachingResponse(from: responseText)
        } catch let error as LLMError {
            throw error
        } catch {
            throw LLMError.generationFailed(error.localizedDescription)
        }
    }
    #endif

    // MARK: - Mock Generation (for development/simulator)

    private func generateMockResponse(intent: CoachingIntent) async throws -> CoachingResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds

        let replies: [CoachingReply]
        let summary: String

        switch intent {
        case .reply:
            summary = "Based on the conversation, they seem genuinely interested in connecting with you. Their message shows warmth and openness."
            replies = [
                CoachingReply(
                    text: "I'd love that! How about Friday evening?",
                    rationale: "Direct and enthusiastic, shows you're equally interested without playing games.",
                    tone: "warm"
                ),
                CoachingReply(
                    text: "Sounds fun! Any particular cuisine you're in the mood for?",
                    rationale: "Keeps the conversation going while showing flexibility and interest in their preferences.",
                    tone: "casual"
                ),
                CoachingReply(
                    text: "Yes! I know a great spot downtown if you're up for an adventure.",
                    rationale: "Confident and takes initiative, suggests you're comfortable leading.",
                    tone: "playful"
                )
            ]

        case .interpret:
            summary = "They're reaching out to reconnect and showing interest in spending time together. The invitation to dinner is a positive sign of wanting to deepen the relationship."
            replies = [
                CoachingReply(
                    text: "Thanks for asking! I've been looking forward to catching up too.",
                    rationale: "Acknowledges their effort and reciprocates the positive energy.",
                    tone: "warm"
                ),
                CoachingReply(
                    text: "Definitely interested! What made you think of dinner?",
                    rationale: "Shows curiosity and invites them to share more about their intentions.",
                    tone: "casual"
                ),
                CoachingReply(
                    text: "I'm glad you asked - I was hoping we'd hang out soon!",
                    rationale: "Honest and direct, shows you were thinking similarly.",
                    tone: "direct"
                )
            ]

        case .boundary:
            summary = "It's important to communicate your needs clearly while remaining kind. Setting boundaries shows self-respect and helps build healthier relationships."
            replies = [
                CoachingReply(
                    text: "I appreciate the invite, but I need some time to myself this week. Can we plan for next week instead?",
                    rationale: "Clear boundary with an alternative, shows you value the relationship while prioritizing your needs.",
                    tone: "firm"
                ),
                CoachingReply(
                    text: "That sounds nice, but I'm feeling a bit overwhelmed lately. Mind if we keep it low-key?",
                    rationale: "Honest about your emotional state while staying open to connection.",
                    tone: "warm"
                ),
                CoachingReply(
                    text: "I'd love to, but I need to check my schedule. Can I get back to you tomorrow?",
                    rationale: "Buys time without immediate commitment, lets you decide on your terms.",
                    tone: "casual"
                )
            ]

        case .flirt:
            summary = "The vibe seems mutual and playful! This is a good opportunity to show your personality and build romantic tension."
            replies = [
                CoachingReply(
                    text: "Only if you promise to make me laugh at least three times ;)",
                    rationale: "Playful challenge that invites them to bring their A-game.",
                    tone: "playful"
                ),
                CoachingReply(
                    text: "Dinner with you? I thought you'd never ask!",
                    rationale: "Flirty and confident, shows you've been hoping for this.",
                    tone: "warm"
                ),
                CoachingReply(
                    text: "I'm in. But fair warning - I have excellent taste, so choose wisely.",
                    rationale: "Confident with a hint of challenge, keeps them on their toes.",
                    tone: "direct"
                )
            ]

        case .conflict:
            summary = "It seems like there might be some tension to navigate. Focus on understanding their perspective first before defending your position."
            replies = [
                CoachingReply(
                    text: "I hear you, and I want to understand better. Can you tell me more about how you're feeling?",
                    rationale: "Opens space for them to share, shows you value their perspective.",
                    tone: "warm"
                ),
                CoachingReply(
                    text: "I think we might be seeing this differently. Can we talk it through?",
                    rationale: "Acknowledges the disagreement while suggesting collaborative resolution.",
                    tone: "direct"
                ),
                CoachingReply(
                    text: "Let's take a step back - I don't want this to come between us.",
                    rationale: "Prioritizes the relationship over being right, de-escalates tension.",
                    tone: "firm"
                )
            ]
        }

        return CoachingResponse(
            summary: summary,
            replies: replies,
            riskFlags: [],
            followUpQuestions: [
                "What outcome would feel best to you in this situation?",
                "How do you want them to feel after reading your message?"
            ]
        )
    }

    // MARK: - Parse Response

    private func parseCoachingResponse(from text: String) throws -> CoachingResponse {
        // Try to extract JSON from the response
        guard let jsonStart = text.firstIndex(of: "{"),
              let jsonEnd = text.lastIndex(of: "}") else {
            throw LLMError.invalidResponse
        }

        let jsonString = String(text[jsonStart...jsonEnd])

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw LLMError.parsingFailed("Could not convert response to data")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(CoachingResponse.self, from: jsonData)
        } catch {
            throw LLMError.parsingFailed(error.localizedDescription)
        }
    }

    // MARK: - Streaming Generation (Optional Enhancement)

    /// Generate coaching with streaming response
    func generateCoachingStream(
        conversation: [Message],
        intent: CoachingIntent,
        parameters: CoachingParameters = .default,
        onToken: @escaping (String) -> Void
    ) async throws -> CoachingResponse {
        // Ensure model is initialized
        if status == .notLoaded {
            await initializeModel()
        }

        guard status == .ready else {
            throw LLMError.modelNotLoaded
        }

        let prompt = PromptBuilder.buildCoachingPrompt(
            conversation: conversation,
            intent: intent,
            parameters: parameters
        )

        #if canImport(FoundationModels)
        return try await streamWithFoundationModels(prompt: prompt, onToken: onToken)
        #else
        // Mock streaming
        let response = try await generateMockResponse(intent: intent)
        onToken(response.summary)
        return response
        #endif
    }

    #if canImport(FoundationModels)
    private func streamWithFoundationModels(
        prompt: String,
        onToken: @escaping (String) -> Void
    ) async throws -> CoachingResponse {
        guard let session = session else {
            throw LLMError.modelNotLoaded
        }

        var accumulated = ""

        do {
            // Stream response
            let stream = session.streamResponse(to: prompt)

            for try await partialResponse in stream {
                let newContent = partialResponse.content
                if newContent.count > accumulated.count {
                    let newToken = String(newContent.dropFirst(accumulated.count))
                    accumulated = newContent
                    onToken(newToken)
                }
            }

            return try parseCoachingResponse(from: accumulated)
        } catch let error as LLMError {
            throw error
        } catch {
            throw LLMError.generationFailed(error.localizedDescription)
        }
    }
    #endif
}
