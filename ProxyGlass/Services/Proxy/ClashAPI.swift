import Foundation

struct ClashProxyInfo: Sendable {
    let proxyType: ProxyType
    let details: String
}

struct ClashConnection: Sendable, Identifiable {
    let id: String
    let host: String
    let destinationIP: String
    let process: String
    let upload: UInt64
    let download: UInt64
    let startTime: String
    let chains: [String]
    let rule: String
}

final class ClashAPI: Sendable {
    private let ports: [Int] = [9090, 7890, 9097, 1080, 1087]

    func query() async throws -> ClashProxyInfo? {
        for port in ports {
            if let result = try await queryProxies(port: port) {
                return result
            }
            if let result = try await queryConfigs(port: port) {
                return result
            }
        }
        return nil
    }

    /// Fetch active connections from Clash API /connections endpoint.
    func fetchConnections() async -> [ClashConnection] {
        for port in ports {
            if let connections = try? await queryConnections(port: port) {
                return connections
            }
        }
        return []
    }

    private func queryConnections(port: Int) async throws -> [ClashConnection]? {
        let url = URL(string: "http://127.0.0.1:\(port)/connections")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let conns = json["connections"] as? [[String: Any]] else { return nil }

        return conns.compactMap { dict -> ClashConnection? in
            guard let id = dict["id"] as? String else { return nil }
            let meta = dict["metadata"] as? [String: Any] ?? [:]
            return ClashConnection(
                id: id,
                host: meta["host"] as? String ?? "",
                destinationIP: meta["destinationIP"] as? String ?? "",
                process: meta["process"] as? String ?? "",
                upload: dict["upload"] as? UInt64 ?? 0,
                download: dict["download"] as? UInt64 ?? 0,
                startTime: dict["start"] as? String ?? "",
                chains: dict["chains"] as? [String] ?? [],
                rule: dict["rule"] as? String ?? ""
            )
        }
    }

    private func queryProxies(port: Int) async throws -> ClashProxyInfo? {
        let url = URL(string: "http://127.0.0.1:\(port)/proxies")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let proxies = json["proxies"] as? [String: Any] else { return nil }

        for (_, proxy) in proxies {
            if let dict = proxy as? [String: Any],
               let type = dict["type"] as? String,
               (type == "Selector" || type == "URLTest" || type == "Fallback"),
               let now = dict["now"] as? String,
               !now.isEmpty {
                // Look up the selected proxy's actual type
                let selectedType = (proxies[now] as? [String: Any])?["type"] as? String
                let proxyType = selectedType.map { ClashAPI.classifyClashType($0) } ?? .unknown
                return ClashProxyInfo(proxyType: proxyType, details: "Clash: \(now)")
            }
        }

        if !proxies.isEmpty {
            return ClashProxyInfo(proxyType: .unknown, details: "Clash: active (\(proxies.count) proxies)")
        }
        return nil
    }

    private func queryConfigs(port: Int) async throws -> ClashProxyInfo? {
        let url = URL(string: "http://127.0.0.1:\(port)/configs")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let mode = json["mode"] as? String ?? "unknown"
        return ClashProxyInfo(proxyType: .unknown, details: "Clash (\(mode))")
    }

    static func classifyClashType(_ type: String) -> ProxyType {
        switch type.lowercased() {
        case "socks5": return .socks5
        case "http": return .http
        case "shadowsocks", "ss": return .shadowsocks
        case "vmess": return .vmess
        case "trojan": return .trojan
        case "vless": return .vless
        case "wireguard", "wg": return .wireguard
        case "hysteria", "hysteria2": return .unknown
        default: return .unknown
        }
    }
}
