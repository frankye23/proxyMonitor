import Foundation

struct TrafficSnapshot: Sendable {
    let proxyBytes: UInt64
    let directBytes: UInt64
    let unknownBytes: UInt64
    let totalBytes: UInt64
    let proxyDownloadRate: Double
    let proxyUploadRate: Double
    let directDownloadRate: Double
    let directUploadRate: Double
    let unknownDownloadRate: Double
    let unknownUploadRate: Double
    let uploadRate: Double
    let downloadRate: Double
    let topConnections: [AggregatedConnection]
    let riskAlerts: [RiskAlert]
    let connectionCount: Int
    let source: ClashConnectionAPI.Source

    var proxyRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(proxyBytes) / Double(totalBytes)
    }

    var directRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(directBytes) / Double(totalBytes)
    }

    var unknownRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(unknownBytes) / Double(totalBytes)
    }

    var totalRate: Double { proxyDownloadRate + directDownloadRate + unknownDownloadRate }

    static let empty = TrafficSnapshot(
        proxyBytes: 0, directBytes: 0, unknownBytes: 0, totalBytes: 0,
        proxyDownloadRate: 0, proxyUploadRate: 0,
        directDownloadRate: 0, directUploadRate: 0,
        unknownDownloadRate: 0, unknownUploadRate: 0,
        uploadRate: 0, downloadRate: 0,
        topConnections: [], riskAlerts: [],
        connectionCount: 0, source: .none
    )
}

struct AggregatedConnection: Sendable, Identifiable {
    let id: String
    let process: String
    let host: String
    let destinationIP: String
    let upload: UInt64
    let download: UInt64
    let routeType: RouteType
    let wentThroughKernel: Bool
    let proxyChain: String
    let currentUpload: UInt64
    let currentDownload: UInt64

    var totalBytes: UInt64 { upload + download }
    var friendlyProcessName: String { DomainNameMapper.friendlyProcessName(process) }
    var serviceName: String { DomainNameMapper.serviceDisplayName(for: host) }
}

struct RiskAlert: Sendable, Identifiable {
    let id: String
    let type: RiskType
    let severity: Severity
    let title: String
    let description: String
    let suggestion: String

    enum RiskType: Sendable {
        case highSpeedDirect, suspiciousLeak, highSpeedUnknown, rateSpike
    }

    enum Severity: Sendable {
        case high, medium
    }
}

final class ConnectionAggregator: Sendable {
    private let api = ClashConnectionAPI()

    private static let previousBytes = Mutex<[String: UInt64]>([:])
    private static let previousTime = Mutex<Date?>(nil)

    func aggregate() async -> TrafficSnapshot {
        let (connections, source) = await api.fetchConnections()

        guard !connections.isEmpty else {
            return TrafficSnapshot.empty
        }

        var proxyBytes: UInt64 = 0
        var directBytes: UInt64 = 0
        var unknownBytes: UInt64 = 0

        for conn in connections {
            let bytes = conn.totalBytes
            switch conn.routeType {
            case .proxy: proxyBytes += bytes
            case .direct: directBytes += bytes
            case .unknown: unknownBytes += bytes
            }
        }

        let totalBytes = proxyBytes + directBytes + unknownBytes

        let now = Date()
        let prevBytes = ConnectionAggregator.previousBytes.withLock { $0 }
        let prevTime = ConnectionAggregator.previousTime.withLock { $0 }

        var proxyDL: Double = 0, proxyUL: Double = 0
        var directDL: Double = 0, directUL: Double = 0
        var unknownDL: Double = 0, unknownUL: Double = 0
        var totalUploadRate: Double = 0
        var totalDownloadRate: Double = 0

        if let prevTime, now.timeIntervalSince(prevTime) > 0 {
            let dt = now.timeIntervalSince(prevTime)
            for conn in connections {
                let prev = prevBytes[conn.id] ?? 0
                let cur = conn.totalBytes
                if cur > prev {
                    let dlRate = Double(conn.download) / dt
                    let ulRate = Double(conn.upload) / dt
                    switch conn.routeType {
                    case .proxy: proxyDL += dlRate; proxyUL += ulRate
                    case .direct: directDL += dlRate; directUL += ulRate
                    case .unknown: unknownDL += dlRate; unknownUL += ulRate
                    }
                    totalDownloadRate += dlRate
                    totalUploadRate += ulRate
                }
            }
        }

        ConnectionAggregator.previousBytes.withLock { dict in
            for conn in connections { dict[conn.id] = conn.totalBytes }
        }
        ConnectionAggregator.previousTime.withLock { $0 = now }

        let sorted = connections.sorted { $0.totalBytes > $1.totalBytes }
        let top5 = sorted.prefix(5).map { conn -> AggregatedConnection in
            let prev = prevBytes[conn.id] ?? 0
            let curDL = conn.totalBytes > prev ? conn.download : 0
            let curUL = conn.totalBytes > prev ? conn.upload : 0
            return AggregatedConnection(
                id: conn.id,
                process: conn.process,
                host: conn.host,
                destinationIP: conn.destinationIP,
                upload: conn.upload,
                download: conn.download,
                routeType: conn.routeType,
                wentThroughKernel: conn.wentThroughKernel,
                proxyChain: conn.proxyChain,
                currentUpload: curUL,
                currentDownload: curDL
            )
        }

        let risks = detectRisks(topConnections: top5)

        return TrafficSnapshot(
            proxyBytes: proxyBytes,
            directBytes: directBytes,
            unknownBytes: unknownBytes,
            totalBytes: totalBytes,
            proxyDownloadRate: proxyDL,
            proxyUploadRate: proxyUL,
            directDownloadRate: directDL,
            directUploadRate: directUL,
            unknownDownloadRate: unknownDL,
            unknownUploadRate: unknownUL,
            uploadRate: totalUploadRate,
            downloadRate: totalDownloadRate,
            topConnections: top5,
            riskAlerts: risks,
            connectionCount: connections.count,
            source: source
        )
    }

    private func detectRisks(topConnections: [AggregatedConnection]) -> [RiskAlert] {
        var risks: [RiskAlert] = []
        var idx = 0

        for conn in topConnections {
            let speed = Double(conn.currentDownload)
            if conn.routeType == .direct && speed > 1_000_000 {
                idx += 1
                risks.append(RiskAlert(
                    id: "risk-\(idx)",
                    type: .highSpeedDirect,
                    severity: .high,
                    title: "高速直连",
                    description: "\(conn.friendlyProcessName) 正在直连，流量 \(formatBytes(speed))/s",
                    suggestion: "将该应用加入代理规则"
                ))
            }
        }

        return risks
    }

    private func formatBytes(_ bytes: Double) -> String {
        if bytes >= 1_000_000 { return String(format: "%.1f MB", bytes / 1_000_000) }
        if bytes >= 1_000 { return String(format: "%.1f KB", bytes / 1_000) }
        return "\(Int(bytes)) B"
    }
}

private final class Mutex<T>: @unchecked Sendable {
    private var value: T
    private let lock = NSLock()

    init(_ value: T) { self.value = value }

    func withLock<U>(_ body: (inout T) -> U) -> U {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }
}
