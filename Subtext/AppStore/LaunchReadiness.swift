//
//  LaunchReadiness.swift
//  Subtext
//
//  Created by Codegen
//  Phase 5: Testing & Launch
//
//  Launch readiness checklist and criteria
//

import Foundation

/// Launch readiness configuration and checklists
enum LaunchReadiness {

    // MARK: - Technical Checklist

    enum Technical: String, CaseIterable {
        case unitTestsPassing = "All unit tests passing"
        case integrationTestsPassing = "All integration tests passing"
        case uiTestsPassing = "All UI tests passing"
        case noCriticalBugs = "No critical bugs identified"
        case performanceMetsMet = "Performance targets met"
        case crashRateAcceptable = "Crash rate < 0.1%"
        case memoryUsageAcceptable = "Memory usage acceptable"
        case batteryImpactAcceptable = "Battery impact < 5%/hour"

        var category: String { "Technical" }
    }

    // MARK: - App Store Checklist

    enum AppStore: String, CaseIterable {
        case listingComplete = "App Store listing complete"
        case screenshotsUploaded = "Screenshots uploaded"
        case previewVideoUploaded = "App preview video uploaded"
        case privacyLabelAccurate = "Privacy label accurate"
        case appIconFinal = "App icon finalized"
        case metadataLocalized = "Metadata localized (English)"

        var category: String { "App Store" }
    }

    // MARK: - TestFlight Checklist

    enum TestFlight: String, CaseIterable {
        case buildUploaded = "Build uploaded and processed"
        case testersInvited = "25 testers invited"
        case feedbackFormLive = "Feedback form live"
        case communicationChannel = "Discord/Slack channel created"
        case monitoringSchedule = "Daily monitoring schedule set"

        var category: String { "TestFlight" }
    }

    // MARK: - Business Checklist

    enum Business: String, CaseIterable {
        case landingPageLive = "Landing page live (subtext.app)"
        case privacyPolicyPublished = "Privacy policy published"
        case termsPublished = "Terms of service published"
        case supportEmailSetup = "Support email set up"
        case pressKitReady = "Press kit ready"

        var category: String { "Business" }
    }

    // MARK: - Beta Success Criteria

    enum BetaSuccessCriteria {
        /// Target satisfaction rating
        static let satisfactionRating = 4.0 // out of 5.0

        /// Target Day 7 retention
        static let d7Retention = 0.50 // 50%

        /// Target activation (first coaching)
        static let activationRate = 0.70 // 70%

        /// Maximum critical bugs
        static let maxCriticalBugs = 5
    }

    // MARK: - Performance Targets

    enum PerformanceTargets {
        /// Maximum acceptable crash rate
        static let crashRate = 0.001 // 0.1%

        /// Maximum memory usage (MB)
        static let maxMemoryMB = 200

        /// Maximum battery impact per hour
        static let maxBatteryPercent = 5

        /// Maximum cold start time (seconds)
        static let maxColdStartSeconds = 3.0

        /// Maximum coaching generation time (seconds)
        static let maxCoachingGenerationSeconds = 10.0
    }

    // MARK: - Launch Day Checklist

    static let launchDayChecklist = [
        "Submit for App Store review (10 days before launch)",
        "Coordinate launch with iOS 26 release",
        "Prepare Product Hunt post",
        "Line up press coverage",
        "Social media posts scheduled",
        "Support inbox monitored",
        "Analytics dashboard ready",
        "Emergency hotfix process documented",
        "Celebrate! 🎉"
    ]

    // MARK: - Risk Mitigation

    enum Risk: String, CaseIterable {
        case criticalBug = "Critical Bug Found in Beta"
        case lowRetention = "Low Beta Retention"
        case appStoreRejection = "App Store Rejection"

        var likelihood: String {
            switch self {
            case .criticalBug: return "Medium"
            case .lowRetention: return "Low"
            case .appStoreRejection: return "Low"
            }
        }

        var impact: String {
            switch self {
            case .criticalBug: return "High"
            case .lowRetention: return "Medium"
            case .appStoreRejection: return "High"
            }
        }

        var mitigation: [String] {
            switch self {
            case .criticalBug:
                return [
                    "Daily crash monitoring",
                    "Fast-track hotfix process",
                    "Clear communication with testers",
                    "Delay public launch if necessary"
                ]
            case .lowRetention:
                return [
                    "Deep-dive interviews with churned users",
                    "Rapid iteration on feedback",
                    "A/B test onboarding improvements",
                    "Pivot messaging if value prop unclear"
                ]
            case .appStoreRejection:
                return [
                    "Follow all App Store guidelines strictly",
                    "Clear privacy labeling",
                    "Mature content warning (17+)",
                    "Detailed rejection response plan"
                ]
            }
        }
    }

    // MARK: - Ready for Launch Criteria

    static let readyForLaunchCriteria = [
        "Beta testing complete (2 weeks)",
        "Critical bugs fixed",
        "4.0+ / 5.0 satisfaction rating",
        "50%+ D7 retention",
        "App Store listing approved",
        "Landing page live",
        "Press materials ready"
    ]
}

// MARK: - Checklist Item Protocol

protocol ChecklistItem {
    var rawValue: String { get }
    var category: String { get }
}

extension LaunchReadiness.Technical: ChecklistItem {}
extension LaunchReadiness.AppStore: ChecklistItem {}
extension LaunchReadiness.TestFlight: ChecklistItem {}
extension LaunchReadiness.Business: ChecklistItem {}

// MARK: - Checklist Manager

@MainActor
class LaunchChecklistManager: ObservableObject {
    static let shared = LaunchChecklistManager()

    @Published var completedItems: Set<String> = []

    private let storageKey = "subtext_launch_checklist"

    private init() {
        load()
    }

    func isCompleted(_ item: String) -> Bool {
        completedItems.contains(item)
    }

    func toggle(_ item: String) {
        if completedItems.contains(item) {
            completedItems.remove(item)
        } else {
            completedItems.insert(item)
        }
        save()
    }

    func markCompleted(_ item: String) {
        completedItems.insert(item)
        save()
    }

    var technicalProgress: Double {
        let total = LaunchReadiness.Technical.allCases.count
        let completed = LaunchReadiness.Technical.allCases.filter { isCompleted($0.rawValue) }.count
        return Double(completed) / Double(total)
    }

    var appStoreProgress: Double {
        let total = LaunchReadiness.AppStore.allCases.count
        let completed = LaunchReadiness.AppStore.allCases.filter { isCompleted($0.rawValue) }.count
        return Double(completed) / Double(total)
    }

    var testFlightProgress: Double {
        let total = LaunchReadiness.TestFlight.allCases.count
        let completed = LaunchReadiness.TestFlight.allCases.filter { isCompleted($0.rawValue) }.count
        return Double(completed) / Double(total)
    }

    var businessProgress: Double {
        let total = LaunchReadiness.Business.allCases.count
        let completed = LaunchReadiness.Business.allCases.filter { isCompleted($0.rawValue) }.count
        return Double(completed) / Double(total)
    }

    var overallProgress: Double {
        let allItems = LaunchReadiness.Technical.allCases.map { $0.rawValue } +
                       LaunchReadiness.AppStore.allCases.map { $0.rawValue } +
                       LaunchReadiness.TestFlight.allCases.map { $0.rawValue } +
                       LaunchReadiness.Business.allCases.map { $0.rawValue }
        let completed = allItems.filter { isCompleted($0) }.count
        return Double(completed) / Double(allItems.count)
    }

    var isReadyForLaunch: Bool {
        overallProgress >= 1.0
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let items = try? JSONDecoder().decode(Set<String>.self, from: data) {
            completedItems = items
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(completedItems) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
