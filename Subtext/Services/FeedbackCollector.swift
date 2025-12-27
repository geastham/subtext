//
//  FeedbackCollector.swift
//  Subtext
//
//  Created by Codegen
//  Phase 5: Testing & Launch
//
//  Service for collecting user feedback during beta testing
//

import Foundation
import SwiftUI

// MARK: - Feedback Types

/// Types of feedback that can be collected
enum FeedbackType: String, Codable, CaseIterable {
    case replyRating        // Thumbs up/down on coaching reply
    case coachingQuality    // Overall coaching quality feedback
    case bugReport          // Bug report with diagnostics
    case featureRequest     // Feature request
    case generalFeedback    // General feedback
}

/// Rating for coaching replies
enum ReplyRating: String, Codable {
    case positive = "positive"
    case negative = "negative"
}

/// Feedback entry stored locally
struct FeedbackEntry: Identifiable, Codable {
    let id: UUID
    let type: FeedbackType
    let timestamp: Date
    let rating: ReplyRating?
    let message: String?
    let context: FeedbackContext?
    var isSynced: Bool

    init(
        id: UUID = UUID(),
        type: FeedbackType,
        timestamp: Date = Date(),
        rating: ReplyRating? = nil,
        message: String? = nil,
        context: FeedbackContext? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.rating = rating
        self.message = message
        self.context = context
        self.isSynced = isSynced
    }
}

/// Context for feedback (no PII, just metadata)
struct FeedbackContext: Codable {
    let intent: String?
    let replyIndex: Int?
    let screenName: String?
    let appVersion: String
    let buildNumber: String
    let osVersion: String
    let deviceModel: String

    init(
        intent: String? = nil,
        replyIndex: Int? = nil,
        screenName: String? = nil
    ) {
        self.intent = intent
        self.replyIndex = replyIndex
        self.screenName = screenName
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        self.osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        self.deviceModel = Self.getDeviceModel()
    }

    private static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        return machine
    }
}

// MARK: - Bug Report

/// Structured bug report
struct BugReport: Codable {
    let id: UUID
    let title: String
    let description: String
    let severity: BugSeverity
    let reproducible: Bool
    let stepsToReproduce: String?
    let context: FeedbackContext
    let timestamp: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        severity: BugSeverity = .medium,
        reproducible: Bool = true,
        stepsToReproduce: String? = nil,
        context: FeedbackContext = FeedbackContext()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.severity = severity
        self.reproducible = reproducible
        self.stepsToReproduce = stepsToReproduce
        self.context = context
        self.timestamp = Date()
    }
}

enum BugSeverity: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

// MARK: - Feedback Collector

/// Service for collecting and managing user feedback
@MainActor
class FeedbackCollector: ObservableObject {
    static let shared = FeedbackCollector()

    @Published private(set) var feedbackEntries: [FeedbackEntry] = []
    @Published private(set) var bugReports: [BugReport] = []
    @Published private(set) var totalPositiveRatings: Int = 0
    @Published private(set) var totalNegativeRatings: Int = 0

    private let feedbackKey = "subtext_feedback_entries"
    private let bugReportsKey = "subtext_bug_reports"

    private init() {
        loadFeedback()
    }

    // MARK: - Public Methods

    /// Record a thumbs up/down rating on a coaching reply
    func rateReply(
        rating: ReplyRating,
        intent: CoachingIntent,
        replyIndex: Int
    ) {
        let context = FeedbackContext(
            intent: intent.rawValue,
            replyIndex: replyIndex
        )

        let entry = FeedbackEntry(
            type: .replyRating,
            rating: rating,
            context: context
        )

        addFeedback(entry)

        // Update counters
        if rating == .positive {
            totalPositiveRatings += 1
        } else {
            totalNegativeRatings += 1
        }
    }

    /// Record written feedback on coaching quality
    func submitCoachingFeedback(
        message: String,
        intent: CoachingIntent
    ) {
        let context = FeedbackContext(intent: intent.rawValue)

        let entry = FeedbackEntry(
            type: .coachingQuality,
            message: message,
            context: context
        )

        addFeedback(entry)
    }

    /// Submit a bug report
    func submitBugReport(_ report: BugReport) {
        bugReports.append(report)
        saveBugReports()

        // Also create a feedback entry
        let entry = FeedbackEntry(
            type: .bugReport,
            message: "\(report.title): \(report.description)",
            context: report.context
        )
        addFeedback(entry)
    }

    /// Submit a feature request
    func submitFeatureRequest(description: String) {
        let entry = FeedbackEntry(
            type: .featureRequest,
            message: description,
            context: FeedbackContext()
        )
        addFeedback(entry)
    }

    /// Submit general feedback
    func submitGeneralFeedback(message: String) {
        let entry = FeedbackEntry(
            type: .generalFeedback,
            message: message,
            context: FeedbackContext()
        )
        addFeedback(entry)
    }

    // MARK: - Statistics

    /// Calculate overall satisfaction score (positive / total)
    var satisfactionScore: Double {
        let total = totalPositiveRatings + totalNegativeRatings
        guard total > 0 else { return 0 }
        return Double(totalPositiveRatings) / Double(total)
    }

    /// Get feedback summary for export
    func getFeedbackSummary() -> FeedbackSummary {
        FeedbackSummary(
            totalFeedback: feedbackEntries.count,
            positiveRatings: totalPositiveRatings,
            negativeRatings: totalNegativeRatings,
            bugReportsCount: bugReports.count,
            featureRequestsCount: feedbackEntries.filter { $0.type == .featureRequest }.count,
            satisfactionScore: satisfactionScore,
            timestamp: Date()
        )
    }

    // MARK: - Data Management

    /// Clear all feedback (for privacy)
    func clearAllFeedback() {
        feedbackEntries.removeAll()
        bugReports.removeAll()
        totalPositiveRatings = 0
        totalNegativeRatings = 0
        saveFeedback()
        saveBugReports()
    }

    /// Export feedback as JSON (for manual submission)
    func exportFeedbackJSON() -> Data? {
        let export = FeedbackExport(
            entries: feedbackEntries,
            bugReports: bugReports,
            summary: getFeedbackSummary()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        return try? encoder.encode(export)
    }

    // MARK: - Private Methods

    private func addFeedback(_ entry: FeedbackEntry) {
        feedbackEntries.append(entry)
        saveFeedback()
    }

    private func loadFeedback() {
        // Load feedback entries
        if let data = UserDefaults.standard.data(forKey: feedbackKey),
           let entries = try? JSONDecoder().decode([FeedbackEntry].self, from: data) {
            feedbackEntries = entries

            // Recalculate counters
            for entry in entries where entry.type == .replyRating {
                if entry.rating == .positive {
                    totalPositiveRatings += 1
                } else if entry.rating == .negative {
                    totalNegativeRatings += 1
                }
            }
        }

        // Load bug reports
        if let data = UserDefaults.standard.data(forKey: bugReportsKey),
           let reports = try? JSONDecoder().decode([BugReport].self, from: data) {
            bugReports = reports
        }
    }

    private func saveFeedback() {
        if let data = try? JSONEncoder().encode(feedbackEntries) {
            UserDefaults.standard.set(data, forKey: feedbackKey)
        }
    }

    private func saveBugReports() {
        if let data = try? JSONEncoder().encode(bugReports) {
            UserDefaults.standard.set(data, forKey: bugReportsKey)
        }
    }
}

// MARK: - Export Types

struct FeedbackSummary: Codable {
    let totalFeedback: Int
    let positiveRatings: Int
    let negativeRatings: Int
    let bugReportsCount: Int
    let featureRequestsCount: Int
    let satisfactionScore: Double
    let timestamp: Date
}

struct FeedbackExport: Codable {
    let entries: [FeedbackEntry]
    let bugReports: [BugReport]
    let summary: FeedbackSummary
}

// MARK: - SwiftUI Views

/// View for submitting quick feedback on a reply
struct ReplyFeedbackView: View {
    let intent: CoachingIntent
    let replyIndex: Int
    @State private var hasRated = false

    var body: some View {
        HStack(spacing: 16) {
            if !hasRated {
                Button {
                    FeedbackCollector.shared.rateReply(
                        rating: .positive,
                        intent: intent,
                        replyIndex: replyIndex
                    )
                    hasRated = true
                } label: {
                    Image(systemName: "hand.thumbsup")
                        .foregroundColor(.green)
                }

                Button {
                    FeedbackCollector.shared.rateReply(
                        rating: .negative,
                        intent: intent,
                        replyIndex: replyIndex
                    )
                    hasRated = true
                } label: {
                    Image(systemName: "hand.thumbsdown")
                        .foregroundColor(.red)
                }
            } else {
                Text("Thanks for your feedback!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// View for submitting a bug report
struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var severity: BugSeverity = .medium
    @State private var stepsToReproduce = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Bug Details") {
                    TextField("Title", text: $title)
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }

                Section("Severity") {
                    Picker("Severity", selection: $severity) {
                        ForEach(BugSeverity.allCases, id: \.self) { severity in
                            Text(severity.rawValue).tag(severity)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Steps to Reproduce (Optional)") {
                    TextEditor(text: $stepsToReproduce)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Report Bug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(title.isEmpty || description.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submitReport() {
        isSubmitting = true

        let report = BugReport(
            title: title,
            description: description,
            severity: severity,
            stepsToReproduce: stepsToReproduce.isEmpty ? nil : stepsToReproduce
        )

        FeedbackCollector.shared.submitBugReport(report)
        dismiss()
    }
}

/// View for general feedback
struct FeedbackFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackType: FeedbackType = .generalFeedback
    @State private var message = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Feedback Type") {
                    Picker("Type", selection: $feedbackType) {
                        Text("General Feedback").tag(FeedbackType.generalFeedback)
                        Text("Feature Request").tag(FeedbackType.featureRequest)
                        Text("Coaching Quality").tag(FeedbackType.coachingQuality)
                    }
                }

                Section("Your Feedback") {
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitFeedback()
                    }
                    .disabled(message.isEmpty)
                }
            }
        }
    }

    private func submitFeedback() {
        switch feedbackType {
        case .featureRequest:
            FeedbackCollector.shared.submitFeatureRequest(description: message)
        case .coachingQuality:
            FeedbackCollector.shared.submitCoachingFeedback(message: message, intent: .reply)
        default:
            FeedbackCollector.shared.submitGeneralFeedback(message: message)
        }
        dismiss()
    }
}
