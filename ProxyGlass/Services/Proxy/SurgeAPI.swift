import Foundation

struct SurgeInfo: Sendable {
    let proxyType: ProxyType
    let details: String
}

struct SurgeConnection: Sendable, Identifiable {
    let id: String
    let host: String
    let destinationIP: String
    let process: String
    let upload: UInt64
    let download: UInt64
    let startTime: Double
    let isDirect: Bool
}

final class SurgeAPI: Sendable {
    private let defaultPorts: [Int] = [6166, 6167]

    private var ports: [Int] {
        let customPort = UserDefaults.standard.integer(forKey: "customSurgePort")
        return customPort > 0 ? [customPort] : defaultPorts
    }

    private var host: String {
        let custom = UserDefaults.standard.string(forKey: "customSurgeHost") ?? ""
        return custom.isEmpty ? "127.0.0.1" : custom
    }

    func query() async throws -> SurgeInfo? {
        for port in ports {
            if let result = try await queryGlobal(port: port) {
                return result
            }
        }
        return nil
    }

    /// Fetch active connections from Surge API /v1/connections endpoint.
    func fetchConnections() async -> [SurgeConnection] {
        for port in ports {
            if let connections = try? await queryConnections(port: port) {
                return connections
            }
        }
        return []
    }

    private func queryConnections(port: Int) async throws -> [SurgeConnection]? {
        let url = URL(string: "http://\(host):\(port)/v1/connections")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let conns = json["connections"] as? [[String: Any]] else { return nil }

        return conns.compactMap { dict -> SurgeConnection? in
            guard let id = dict["id"] as? String else { return nil }
            return SurgeConnection(
                id: id,
                host: dict["host"] as? String ?? "",
                destinationIP: dict["remoteAddress"] as? String ?? "",
                process: dict["processName"] as? String ?? "",
                upload: dict["uploadTotal"] as? UInt64 ?? 0,
                download: dict["downloadTotal"] as? UInt64 ?? 0,
                startTime: dict["startDate"] as? Double ?? 0,
                isDirect: dict["policy"] as? String == "DIRECT"
            )
        }
    }

    private func queryGlobal(port: Int) async throws -> SurgeInfo? {
        let url = URL(string: "http://\(host):\(port)/v1/global")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let mode = json["mode"] as? String ?? "unknown"
        return SurgeInfo(proxyType: .unknown, details: "Surge (\(mode))")
    }
}
