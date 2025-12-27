//
//  OfflineBannerView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 4: Safety & Polish
//

import SwiftUI

// MARK: - Offline Banner View

struct OfflineBannerView: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("Offline - Some features unavailable")
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.2))
        .foregroundColor(.orange)
        .cornerRadius(8)
    }
}

// MARK: - Network Status Indicator

struct NetworkStatusIndicator: View {
    let networkMonitor = NetworkMonitor.shared

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(networkMonitor.isConnected ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var statusText: String {
        if !networkMonitor.isConnected {
            return "Offline"
        }

        switch networkMonitor.connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Wired"
        case .unknown:
            return "Connected"
        }
    }
}

// MARK: - Offline Mode View

struct OfflineModeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                Text("You're Offline")
                    .font(.headline)

                Text("AI coaching requires an internet connection. Your saved conversations are still available.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 12) {
                offlineFeature(icon: "checkmark.circle.fill", text: "View saved conversations", available: true)
                offlineFeature(icon: "checkmark.circle.fill", text: "Review past coaching sessions", available: true)
                offlineFeature(icon: "xmark.circle.fill", text: "Generate new coaching", available: false)
                offlineFeature(icon: "xmark.circle.fill", text: "Safety analysis", available: false)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Spacer()
        }
        .padding()
    }

    private func offlineFeature(icon: String, text: String, available: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(available ? .green : .red)

            Text(text)
                .font(.subheadline)
                .foregroundColor(available ? .primary : .secondary)
        }
    }
}

// MARK: - Offline Wrapper View

struct OfflineAwareView<Content: View>: View {
    let networkMonitor = NetworkMonitor.shared
    let requiresNetwork: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        if !networkMonitor.isConnected && requiresNetwork {
            OfflineModeView()
        } else {
            VStack(spacing: 0) {
                if !networkMonitor.isConnected {
                    OfflineBannerView()
                        .padding(.vertical, 8)
                }

                content()
            }
        }
    }
}

// MARK: - Preview

#Preview("Offline Banner") {
    OfflineBannerView()
}

#Preview("Network Status") {
    NetworkStatusIndicator()
}

#Preview("Offline Mode") {
    OfflineModeView()
}
