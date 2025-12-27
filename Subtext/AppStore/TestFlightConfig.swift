//
//  TestFlightConfig.swift
//  Subtext
//
//  Created by Codegen
//  Phase 5: Testing & Launch
//
//  TestFlight configuration and beta testing information
//

import Foundation

/// TestFlight beta testing configuration
enum TestFlightConfig {

    // MARK: - Build Information

    static let version = "1.0.0"
    static let buildNumber = "1"
    static let minimumOS = "26.0"

    // MARK: - Beta Testing Groups

    enum BetaGroup {
        case internalTesters    // 10 users - Week 1
        case expandedBeta       // 15 additional users - Week 2

        var name: String {
            switch self {
            case .internalTesters: return "Internal Testers"
            case .expandedBeta: return "Expanded Beta"
            }
        }

        var maxTesters: Int {
            switch self {
            case .internalTesters: return 10
            case .expandedBeta: return 15
            }
        }
    }

    // MARK: - Total Target

    static let totalBetaTesters = 25

    // MARK: - Tester Criteria

    enum TesterMix {
        case activeDaters       // 15 users
        case relationshipCoach  // 3 users
        case iosDevelopers      // 4 users
        case privacyAdvocates   // 3 users

        var count: Int {
            switch self {
            case .activeDaters: return 15
            case .relationshipCoach: return 3
            case .iosDevelopers: return 4
            case .privacyAdvocates: return 3
            }
        }

        var description: String {
            switch self {
            case .activeDaters: return "Active daters who regularly use dating apps"
            case .relationshipCoach: return "Relationship coaches or therapists"
            case .iosDevelopers: return "iOS developers for technical feedback"
            case .privacyAdvocates: return "Privacy advocates for security review"
            }
        }
    }

    // MARK: - Device Requirements

    static let requiredDevices = [
        "iPhone 15",
        "iPhone 15 Plus",
        "iPhone 15 Pro",
        "iPhone 15 Pro Max",
        "iPhone 16",
        "iPhone 16 Plus",
        "iPhone 16 Pro",
        "iPhone 16 Pro Max"
    ]

    // MARK: - What to Test

    static let whatToTest = """
    Welcome to the Subtext beta! Thank you for helping us build a better app.

    WHAT TO TEST:
    1. Import conversations from various sources (iMessage, WhatsApp, copy-paste)
    2. Generate coaching for all 5 intents:
       - Reply: Help crafting responses
       - Interpret: Understanding their message
       - Boundary: Setting healthy limits
       - Flirt: Being playful and confident
       - Conflict: Navigating disagreements

    3. Verify response quality and relevance
    4. Test safety detection with concerning messages
    5. Check performance on your device
    6. Report any bugs or crashes

    PLEASE PROVIDE FEEDBACK ON:
    1. How useful were the coaching suggestions? (1-5)
    2. Did the app feel private and secure?
    3. Were there any bugs or confusing moments?
    4. What features would you like to see added?

    IMPORTANT NOTES:
    - All data stays on your device
    - You can delete all data in Settings at any time
    - This is beta software - please report any issues

    Thank you for testing Subtext! Your feedback will help us build a better product.
    """

    // MARK: - Beta App Description

    static let betaAppDescription = """
    Subtext is an AI-powered conversation coach for dating and relationships.

    Import your conversations, select an intent, and get personalized coaching
    with 3 reply options. All processing happens on-device - your data never
    leaves your iPhone.

    This beta version includes:
    ✓ Full conversation import (iMessage, WhatsApp, Telegram, manual)
    ✓ All 5 coaching intents
    ✓ Safety detection with support resources
    ✓ On-device AI using Apple Foundation Models

    Requires iOS 26+ and iPhone 15 or newer.
    """

    // MARK: - Feedback URL

    static let feedbackFormURL = "https://forms.gle/subtext-beta-feedback"
    static let discordInviteURL = "https://discord.gg/subtext-beta"
    static let supportEmail = "beta@subtext.app"

    // MARK: - Beta Timeline

    enum BetaPhase {
        case week1Internal  // Days 1-3
        case week2Expanded  // Days 4-7

        var description: String {
            switch self {
            case .week1Internal:
                return "Internal Testing - 10 close friends, focus on critical bugs and UX"
            case .week2Expanded:
                return "Expanded Beta - 15 additional users, focus on real-world usage"
            }
        }

        var focusAreas: [String] {
            switch self {
            case .week1Internal:
                return [
                    "Critical bugs",
                    "Crash reports",
                    "Core flow functionality",
                    "UX issues"
                ]
            case .week2Expanded:
                return [
                    "Real-world usage patterns",
                    "Coaching quality",
                    "Edge cases",
                    "Performance on different devices"
                ]
            }
        }
    }
}

// MARK: - Success Metrics

extension TestFlightConfig {

    enum SuccessMetrics {
        /// Target satisfaction rating
        static let satisfactionTarget = 4.0 // out of 5.0

        /// Target Day 7 retention
        static let d7RetentionTarget = 0.50 // 50%

        /// Target activation rate (complete first coaching)
        static let activationTarget = 0.70 // 70%

        /// Maximum critical bugs before delaying launch
        static let maxCriticalBugs = 5
    }
}

// MARK: - Feedback Collection

extension TestFlightConfig {

    /// In-app feedback mechanisms
    enum InAppFeedback {
        case thumbsUpDown      // On each reply
        case writtenFeedback   // Optional on coaching quality
        case bugReport         // Sends diagnostics

        var description: String {
            switch self {
            case .thumbsUpDown:
                return "Quick thumbs up/down on each reply"
            case .writtenFeedback:
                return "Optional text feedback on coaching quality"
            case .bugReport:
                return "Bug report with automatic diagnostics"
            }
        }
    }

    /// Survey questions for end-of-beta feedback
    static let surveyQuestions = [
        (question: "How would you rate the overall experience?", type: "1-5 scale"),
        (question: "How useful were the coaching suggestions?", type: "1-5 scale"),
        (question: "Did you feel your privacy was protected?", type: "Yes/No"),
        (question: "Did you encounter any bugs?", type: "Describe"),
        (question: "What features would you most like to see added?", type: "Open text"),
        (question: "Would you recommend Subtext to a friend?", type: "1-10 NPS")
    ]
}

// MARK: - Crash Monitoring

extension TestFlightConfig {

    /// Crash monitoring configuration
    enum CrashMonitoring {
        /// Maximum acceptable crash rate
        static let maxCrashRate = 0.001 // 0.1%

        /// Check crash reports daily
        static let monitoringFrequency = "Daily"

        /// Fast-track hotfix threshold
        static let hotfixThreshold = "Any crash affecting > 10% of sessions"
    }
}

// MARK: - Build Automation

extension TestFlightConfig {

    /// Build and upload checklist
    static let buildChecklist = [
        "All unit tests passing",
        "All integration tests passing",
        "No critical bugs open",
        "Version and build number updated",
        "Release notes written",
        "App Store screenshots current",
        "Privacy manifest up to date",
        "Archive and upload to TestFlight",
        "Add to appropriate beta group",
        "Send invite notifications"
    ]
}
