import Foundation

/// Final route decision for a connection.
enum RouteType: Sendable {
    case proxy    // Final route through proxy node
    case direct   // Final route direct
    case unknown  // Cannot determine
}

/// Unified connection data source — tries Clash API first, then Surge.
final class ClashConnectionAPI: Sendable {
    private let clashAPI = ClashAPI()
    private let surgeAPI = SurgeAPI()

    enum Source: Sendable {
        case clash, surge, none
    }

    func fetchConnections() async -> (connections: [TrafficConnection], source: Source) {
        let clashConns = await clashAPI.fetchConnections()
        if !clashConns.isEmpty {
            return (clashConns.map { TrafficConnection(from: $0) }, .clash)
        }

        let surgeConns = await surgeAPI.fetchConnections()
        if !surgeConns.isEmpty {
            return (surgeConns.map { TrafficConnection(from: $0) }, .surge)
        }

        return ([], .none)
    }
}

/// Normalized connection record for traffic aggregation.
struct TrafficConnection: Sendable, Identifiable {
    let id: String
    let host: String
    let destinationIP: String
    let process: String
    let upload: UInt64
    let download: UInt64
    let routeType: RouteType
    let wentThroughKernel: Bool
    let proxyChain: String

    init(from clash: ClashConnection) {
        self.id = clash.id
        self.host = clash.host
        self.destinationIP = clash.destinationIP
        self.process = clash.process.replacingOccurrences(of: ".exe", with: "")
        self.upload = clash.upload
        self.download = clash.download
        // chains contains "DIRECT" means mihomo routed direct, not proxy
        let proxyChains = clash.chains.filter { $0 != "DIRECT" && $0 != "REJECT" }
        self.routeType = proxyChains.isEmpty ? .direct : .proxy
        self.wentThroughKernel = true
        self.proxyChain = clash.chains.joined(separator: " → ")
    }

    init(from surge: SurgeConnection) {
        self.id = surge.id
        self.host = surge.host
        self.destinationIP = surge.destinationIP
        self.process = surge.process.replacingOccurrences(of: ".exe", with: "")
        self.upload = surge.upload
        self.download = surge.download
        self.routeType = surge.isDirect ? .direct : .proxy
        self.wentThroughKernel = true
        self.proxyChain = surge.isDirect ? "" : "Surge"
    }

    var totalBytes: UInt64 { upload + download }
}
