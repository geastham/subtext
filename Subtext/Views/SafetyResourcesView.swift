//
//  SafetyResourcesView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 4: Safety & Polish
//

import SwiftUI

// MARK: - Safety Resources View

struct SafetyResourcesView: View {
    let analysis: SafetyAnalysis
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    if analysis.overallRisk == .high {
                        urgentBanner
                    }

                    if !analysis.flags.isEmpty {
                        flagsSection
                    }

                    if !analysis.recommendations.isEmpty {
                        recommendationsSection
                    }

                    if !analysis.supportResources.isEmpty {
                        resourcesSection
                    }

                    educationSection

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Safety Resources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 50))
                .foregroundColor(riskColor)

            Text("We noticed some concerning patterns")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("Your safety and well-being matter. Here are some resources that might help.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Urgent Banner

    private var urgentBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("High Risk Detected")
                    .font(.headline)
                    .foregroundColor(.red)
            }

            Text("If you feel unsafe, please reach out to one of the resources below. You deserve support.")
                .font(.subheadline)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Flags Section

    private var flagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patterns Detected")
                .font(.headline)

            ForEach(analysis.flags, id: \.description) { flag in
                SafetyFlagCard(flag: flag)
            }
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)

            ForEach(analysis.recommendations, id: \.self) { recommendation in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(recommendation)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Resources Section

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support Resources")
                .font(.headline)

            ForEach(analysis.supportResources) { resource in
                ResourceCard(resource: resource)
            }
        }
    }

    // MARK: - Education Section

    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learn More")
                .font(.headline)

            Link(destination: URL(string: "https://www.loveisrespect.org/everyone-deserves-a-healthy-relationship/relationship-spectrum/")!) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Understanding Healthy vs. Unhealthy Relationships")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Love Is Respect")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .foregroundColor(.primary)
        }
    }

    // MARK: - Helpers

    private var riskColor: Color {
        switch analysis.overallRisk {
        case .none, .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Safety Flag Card

struct SafetyFlagCard: View {
    let flag: RiskFlag

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: flagIcon)
                    .foregroundColor(severityColor)

                Text(flagTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(severityColor)

                Spacer()

                Text(flag.severity.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(severityColor.opacity(0.2))
                    .foregroundColor(severityColor)
                    .cornerRadius(4)
            }

            Text(flag.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(severityColor.opacity(0.1))
        .cornerRadius(8)
    }

    private var severityColor: Color {
        switch flag.severity {
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var flagIcon: String {
        switch flag.type {
        case .manipulation: return "person.2.wave.2"
        case .gaslighting: return "cloud.fog"
        case .pressuring: return "hand.raised"
        case .toxicity: return "exclamationmark.bubble"
        case .redFlag: return "flag.fill"
        case .violence: return "exclamationmark.triangle.fill"
        }
    }

    private var flagTitle: String {
        switch flag.type {
        case .manipulation: return "Manipulation"
        case .gaslighting: return "Gaslighting"
        case .pressuring: return "Pressuring"
        case .toxicity: return "Toxicity"
        case .redFlag: return "Red Flag"
        case .violence: return "Violence"
        }
    }
}

// MARK: - Resource Card

struct ResourceCard: View {
    let resource: SupportResource

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resource.title)
                .font(.headline)

            Text(resource.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                if let url = phoneURL {
                    Link(destination: url) {
                        Label("Call", systemImage: "phone.fill")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }

                if let url = websiteURL {
                    Link(destination: url) {
                        Label("Website", systemImage: "safari")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var phoneURL: URL? {
        let phoneNumber = resource.phone.filter { $0.isNumber }
        guard !phoneNumber.isEmpty else { return nil }
        return URL(string: "tel:\(phoneNumber)")
    }

    private var websiteURL: URL? {
        URL(string: resource.website)
    }
}

// MARK: - Safety Banner View (Compact)

struct SafetyBannerView: View {
    let analysis: SafetyAnalysis
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(riskColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(bannerTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Tap to see resources")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(riskColor.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(riskColor.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var riskColor: Color {
        switch analysis.overallRisk {
        case .none, .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var bannerTitle: String {
        let count = analysis.flags.count
        switch analysis.overallRisk {
        case .high:
            return "High-risk patterns detected"
        case .medium:
            return "\(count) concerning \(count == 1 ? "pattern" : "patterns") found"
        case .low, .none:
            return "Minor concerns noted"
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleAnalysis = SafetyAnalysis(
        flags: [
            RiskFlag(
                type: .manipulation,
                severity: .high,
                description: "This message uses guilt to control behavior",
                evidence: ["If you loved me, you would do this for me"]
            ),
            RiskFlag(
                type: .gaslighting,
                severity: .medium,
                description: "This message denies your perception of reality",
                evidence: ["That never happened, you're imagining things"]
            )
        ],
        overallRisk: .high,
        recommendations: [
            "Trust your perception of events - your feelings are valid",
            "Consider setting clear boundaries about what you're comfortable with"
        ],
        supportResources: [
            SupportResource(
                title: "National Domestic Violence Hotline",
                description: "24/7 support for anyone experiencing abuse",
                phone: "1-800-799-7233",
                website: "https://www.thehotline.org"
            ),
            SupportResource(
                title: "Crisis Text Line",
                description: "Text HOME to 741741 for free 24/7 support",
                phone: "Text HOME to 741741",
                website: "https://www.crisistextline.org"
            )
        ]
    )

    return SafetyResourcesView(analysis: sampleAnalysis)
}
