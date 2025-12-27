//
//  PromptBuilder.swift
//  Subtext
//
//  Created by Codegen
//  Phase 3: AI Integration & Coaching
//

import Foundation

// MARK: - Prompt Builder

struct PromptBuilder {

    // MARK: - Main Prompt Builder

    static func buildCoachingPrompt(
        conversation: [Message],
        intent: CoachingIntent,
        parameters: CoachingParameters
    ) -> String {
        let systemPrompt = buildSystemPrompt()
        let intentPrompt = buildIntentPrompt(intent: intent)
        let conversationContext = buildConversationContext(messages: conversation)
        let parametersPrompt = buildParametersPrompt(parameters: parameters)
        let outputSchema = buildOutputSchema()

        return """
        \(systemPrompt)

        \(intentPrompt)

        \(conversationContext)

        \(parametersPrompt)

        \(outputSchema)
        """
    }

    // MARK: - System Prompt

    private static func buildSystemPrompt() -> String {
        """
        You are Subtext, a supportive and empathetic conversation coach for dating and relationships.

        Your role:
        - Help users communicate more effectively in romantic conversations
        - Provide 3 distinct reply options with clear rationales
        - Be warm, non-judgmental, and empowering
        - Detect and flag concerning patterns (manipulation, toxicity, red flags)
        - Respect user agency - suggest, don't prescribe

        Core principles:
        - Privacy: All processing is on-device
        - Safety: Flag unhealthy patterns
        - Nuance: Understand context and subtext
        - Empowerment: Help users find their voice

        Tone: Supportive friend who gives honest advice
        """
    }

    // MARK: - Intent-Specific Prompts

    private static func buildIntentPrompt(intent: CoachingIntent) -> String {
        switch intent {
        case .reply:
            return """
            INTENT: Help craft a reply

            The user wants help responding to the most recent message.

            Analyze:
            - What is the other person trying to communicate?
            - What might they be feeling?
            - What are the key emotional beats?

            Provide 3 reply options:
            1. Option A: [One approach with specific tone]
            2. Option B: [Different approach with different tone]
            3. Option C: [Third distinct approach]

            For each reply, explain WHY it might work.
            """

        case .interpret:
            return """
            INTENT: Interpret their message

            The user is confused about what the other person meant.

            Analyze:
            - What are they literally saying?
            - What might they actually mean? (subtext)
            - What emotions are they expressing?
            - What might they want from the user?

            Then suggest 3 ways to respond based on your interpretation.
            """

        case .boundary:
            return """
            INTENT: Set a boundary

            The user needs to establish or reinforce a personal boundary.

            Analyze:
            - What boundary needs to be set?
            - Is this situation concerning? (flag if yes)
            - How can they assert this boundary kindly but firmly?

            Provide 3 boundary-setting approaches:
            1. Direct and clear
            2. Warm but firm
            3. Gentle redirect

            Emphasize that boundaries are healthy and necessary.
            """

        case .flirt:
            return """
            INTENT: Flirt playfully

            The user wants to be flirty and show romantic interest.

            Analyze:
            - Is the vibe mutual? (check for reciprocation)
            - What's their flirting style so far?
            - What level of boldness fits the situation?

            Provide 3 flirty reply options:
            1. Playful and light
            2. Confident and direct
            3. Warm and genuine

            Make sure suggestions feel authentic, not forced.
            """

        case .conflict:
            return """
            INTENT: Navigate conflict

            The user is in a disagreement or tense situation.

            Analyze:
            - What is the core issue?
            - Are both parties communicating healthily? (flag if not)
            - What does the user actually want? (resolution, understanding, space?)

            Provide 3 conflict-resolution approaches:
            1. Validate their feelings first
            2. Find common ground
            3. Suggest a constructive path forward

            Prioritize de-escalation and mutual understanding.
            """
        }
    }

    // MARK: - Conversation Context

    private static func buildConversationContext(messages: [Message]) -> String {
        // Take last 20 messages for context
        let recentMessages = Array(messages.suffix(20))

        let formatted = recentMessages.map { msg in
            let speaker = msg.isFromUser ? "Me" : msg.sender
            return "[\(speaker)]: \(msg.text)"
        }.joined(separator: "\n")

        return """
        CONVERSATION CONTEXT:

        \(formatted)

        (Focus on the most recent messages for your coaching)
        """
    }

    // MARK: - Parameters Prompt

    private static func buildParametersPrompt(parameters: CoachingParameters) -> String {
        """
        USER PREFERENCES:
        - Tone: \(parameters.tone.rawValue)
        - Verbosity: \(parameters.verbosity.rawValue)
        - Formality: \(parameters.formality.rawValue)

        Adjust your suggestions to match these preferences.
        """
    }

    // MARK: - Output Schema

    private static func buildOutputSchema() -> String {
        """
        OUTPUT FORMAT (JSON):

        {
          "summary": "Brief analysis of the situation (2-3 sentences)",
          "replies": [
            {
              "text": "The actual reply text the user could send",
              "rationale": "Why this reply works and what it accomplishes",
              "tone": "casual" | "warm" | "direct" | "playful" | "firm"
            },
            {
              "text": "Second reply option",
              "rationale": "Why this approach is different and when to use it",
              "tone": "warm"
            },
            {
              "text": "Third reply option",
              "rationale": "A third perspective on how to respond",
              "tone": "direct"
            }
          ],
          "riskFlags": [
            {
              "type": "manipulation" | "gaslighting" | "pressuring" | "toxicity" | "red_flag",
              "severity": "low" | "medium" | "high",
              "description": "Explanation of the concern",
              "evidence": ["Specific message excerpts that show this pattern"]
            }
          ],
          "followUpQuestions": [
            "Question 1 to help user think deeper",
            "Question 2 to clarify their intent"
          ]
        }

        IMPORTANT:
        - Always provide exactly 3 reply options
        - Each reply should have a distinct tone and approach
        - Only include riskFlags if there are genuine concerns
        - followUpQuestions should help the user reflect on their goals
        - Respond ONLY with valid JSON matching this schema
        """
    }

    // MARK: - Simple Prompts (for quick operations)

    /// Build a safety analysis prompt
    static func buildSafetyPrompt(conversation: [Message]) -> String {
        let context = conversation.suffix(20).map { msg in
            "[\(msg.isFromUser ? "Me" : msg.sender)]: \(msg.text)"
        }.joined(separator: "\n")

        return """
        Analyze this conversation for unhealthy patterns:

        \(context)

        Look for:
        - Manipulation tactics (guilt-tripping, emotional blackmail)
        - Gaslighting (denying reality, making them question themselves)
        - Boundary violations (ignoring "no", pressuring)
        - Controlling behavior (isolation, monitoring, jealousy)
        - Disrespect or toxicity
        - Threats or violence (explicit or implied)

        For each pattern found, provide:
        - Type of concern
        - Severity (low/medium/high)
        - Specific evidence (quote the messages)
        - Brief explanation

        Be conservative - only flag clear patterns, not misunderstandings.

        Output JSON:
        {
          "flags": [
            {
              "type": "manipulation" | "gaslighting" | "pressuring" | "toxicity" | "red_flag" | "violence",
              "severity": "low" | "medium" | "high",
              "description": "Brief explanation of the concern",
              "evidence": ["quote 1", "quote 2"]
            }
          ]
        }

        If no concerns are found, return: {"flags": []}

        IMPORTANT: Respond ONLY with valid JSON matching this schema.
        """
    }

    /// Build a simple interpretation prompt
    static func buildInterpretationPrompt(message: String) -> String {
        """
        Analyze this message and explain what the person might really mean:

        "\(message)"

        Consider:
        1. The literal meaning
        2. Possible subtext or hidden feelings
        3. What they might want from the recipient

        Be concise but insightful.
        """
    }

    /// Build a simple reply suggestion prompt
    static func buildQuickReplyPrompt(lastMessage: String, tone: CoachingParameters.Tone) -> String {
        """
        Suggest a \(tone.rawValue) reply to this message:

        "\(lastMessage)"

        Keep it natural and conversational.
        """
    }
}

// MARK: - Prompt Templates

extension PromptBuilder {

    /// Pre-built templates for common scenarios
    enum Template {
        case firstDate
        case meetingUp
        case apologizing
        case expressingInterest
        case endingConversation

        var prompt: String {
            switch self {
            case .firstDate:
                return """
                Context: The user is planning or discussing a first date.
                Focus on: Building connection, showing genuine interest, managing expectations.
                """
            case .meetingUp:
                return """
                Context: The user is coordinating plans to meet in person.
                Focus on: Clear communication, confirming details, expressing enthusiasm appropriately.
                """
            case .apologizing:
                return """
                Context: The user needs to apologize for something.
                Focus on: Taking responsibility, being genuine, making amends without over-apologizing.
                """
            case .expressingInterest:
                return """
                Context: The user wants to show romantic interest.
                Focus on: Being authentic, reading the room, appropriate vulnerability.
                """
            case .endingConversation:
                return """
                Context: The user wants to end or pause the conversation gracefully.
                Focus on: Being kind but clear, leaving the door open (or not), respecting both parties.
                """
            }
        }
    }
}
