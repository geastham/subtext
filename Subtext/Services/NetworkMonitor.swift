//
//  NetworkMonitor.swift
//  Subtext
//
//  Created by Codegen
//  Phase 4: Safety & Polish
//

import Foundation
import Network

// MARK: - Network Monitor

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private(set) var isConnected = true
    private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    private init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Start Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }

        monitor.start(queue: queue)
    }

    // MARK: - Stop Monitoring

    private func stopMonitoring() {
        monitor.cancel()
    }

    // MARK: - Get Connection Type

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        } else {
            return .unknown
        }
    }
}
