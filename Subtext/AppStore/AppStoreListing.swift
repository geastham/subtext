//
//  AppStoreListing.swift
//  Subtext
//
//  Created by Codegen
//  Phase 5: Testing & Launch
//
//  App Store metadata and listing information
//

import Foundation

/// App Store listing information for Subtext
enum AppStoreListing {

    // MARK: - Basic Information

    static let appName = "Subtext - Conversation Coach"
    static let subtitle = "Private AI coach for better conversations"
    static let bundleId = "app.subtext.ios"
    static let version = "1.0.0"
    static let buildNumber = "1"
    static let minimumOS = "26.0"

    // MARK: - Categories

    static let primaryCategory = "Lifestyle"
    static let secondaryCategory = "Social Networking"

    // MARK: - Age Rating

    static let ageRating = "17+"
    static let ageRatingReasons = [
        "Mature/Suggestive Themes",
        "Relationship-focused content"
    ]

    // MARK: - Description

    static let description = """
    Subtext is your private AI conversation coach for dating and relationships.

    ✨ GET BETTER AT TEXTING
    • Get 3 reply options with clear explanations
    • Understand what they really mean
    • Navigate tricky situations confidently

    🔒 100% PRIVATE
    • All AI processing happens on your iPhone
    • Your conversations never leave your device
    • No cloud storage, no data collection

    💙 BUILT FOR YOUR SAFETY
    • Detects manipulation and red flags
    • Provides support resources when needed
    • Non-judgmental, empowering advice

    🎯 5 CORE INTENTS
    • Reply: Craft the perfect response
    • Interpret: Understand their message
    • Boundary: Set healthy limits
    • Flirt: Be playful and confident
    • Conflict: Navigate disagreements

    Perfect for:
    • Dating app conversations
    • New relationships
    • Tricky situations
    • Learning to communicate better

    Subtext uses Apple's on-device AI (requires iOS 26+). Your privacy is our priority - we literally can't see your conversations.

    ---

    Terms: subtext.app/terms
    Privacy: subtext.app/privacy
    """

    // MARK: - Keywords

    static let keywords = [
        "dating",
        "relationships",
        "texting",
        "conversation",
        "AI coach",
        "dating coach",
        "relationship advice",
        "communication",
        "privacy",
        "on-device",
        "Apple Intelligence"
    ]

    // MARK: - What's New

    static let whatsNew = """
    Welcome to Subtext! This is our first release.

    • Import conversations from iMessage, WhatsApp, and more
    • Get AI-powered coaching with 3 reply options
    • Choose from 5 intents: Reply, Interpret, Boundary, Flirt, Conflict
    • Safety detection with support resources
    • 100% on-device processing - your data never leaves your iPhone
    """

    // MARK: - Support URLs

    static let supportURL = "https://subtext.app/support"
    static let privacyPolicyURL = "https://subtext.app/privacy"
    static let termsOfServiceURL = "https://subtext.app/terms"
    static let marketingURL = "https://subtext.app"

    // MARK: - Screenshots

    enum Screenshot: CaseIterable {
        case heroCoaching
        case safetyDetection
        case privacyEmphasis
        case importConversation
        case intentSelection

        var filename: String {
            switch self {
            case .heroCoaching: return "01-HeroShot"
            case .safetyDetection: return "02-SafetyShot"
            case .privacyEmphasis: return "03-PrivacyShot"
            case .importConversation: return "04-ImportShot"
            case .intentSelection: return "05-IntentShot"
            }
        }

        var caption: String {
            switch self {
            case .heroCoaching:
                return "Get 3 thoughtful reply options in seconds"
            case .safetyDetection:
                return "Built-in safety detection and support"
            case .privacyEmphasis:
                return "100% private. Your data never leaves your iPhone."
            case .importConversation:
                return "Import conversations from any app"
            case .intentSelection:
                return "Choose what you need help with"
            }
        }

        var dimensions: (width: Int, height: Int) {
            // iPhone 15 Pro Max dimensions
            return (1290, 2796)
        }
    }

    // MARK: - App Preview Video

    struct AppPreview {
        static let duration: TimeInterval = 30

        static let scenes = [
            (start: 0, end: 5, description: "Problem: Staring at phone, don't know what to say"),
            (start: 5, end: 10, description: "Solution: Open Subtext, paste conversation"),
            (start: 10, end: 20, description: "Demo: Select intent, get coaching, see replies"),
            (start: 20, end: 25, description: "Privacy: On-device processing badge"),
            (start: 25, end: 30, description: "CTA: Download Subtext")
        ]
    }

    // MARK: - App Icon

    struct AppIcon {
        static let size = 1024
        static let design = "Clean, modern, purple/blue gradient"
        static let symbol = "Chat bubble with sparkle (coaching)"
        static let filename = "AppIcon_1024x1024.png"
    }
}

// MARK: - Privacy Nutrition Label

extension AppStoreListing {

    enum PrivacyLabel {
        /// Data NOT collected (App Store declaration)
        static let dataNotCollected = true

        /// Data used to track you
        static let trackingData: [String] = [] // None

        /// Data linked to you
        static let linkedData: [String] = [] // None

        /// Data not linked to you
        static let unlinkedData: [String] = [] // None

        /// Privacy practices
        static let practices = [
            "Data is encrypted on device",
            "You can request data deletion via app settings",
            "No data is shared with third parties",
            "No data leaves device",
            "All AI processing is on-device using Apple's Foundation Models"
        ]
    }
}

// MARK: - Review Guidelines Compliance

extension AppStoreListing {

    enum ReviewGuidelines {
        /// Key compliance points for App Store Review
        static let compliancePoints = [
            "17+ age rating for relationship content",
            "Clear privacy labeling (no data collection)",
            "No external AI APIs - uses Apple Foundation Models",
            "Support resources for safety concerns",
            "No user-generated content moderation needed",
            "No in-app purchases in v1.0",
            "No ads",
            "Accessibility supported (Dynamic Type, VoiceOver)"
        ]

        /// Potential review notes
        static let reviewNotes = """
        Subtext is a conversation coaching app that helps users improve their dating and relationship communication.

        Key features:
        - Uses Apple's on-device Foundation Models for AI (iOS 26+)
        - No data leaves the device
        - Safety detection for concerning patterns (manipulation, gaslighting)
        - Provides support resources when safety concerns detected

        Test account: Not required - all data is local
        Demo mode: App works with any pasted conversation

        Privacy: Zero data collection. All processing on-device.
        """
    }
}

// MARK: - Localization

extension AppStoreListing {

    enum Localization {
        /// Supported languages for v1.0
        static let supportedLanguages = ["en-US"]

        /// Planned languages for future releases
        static let plannedLanguages = [
            "en-GB", "es", "fr", "de", "it", "pt-BR", "ja", "ko", "zh-Hans"
        ]
    }
}
