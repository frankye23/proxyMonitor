import SwiftUI
import Observation

extension Int {
    func nonZeroOr(_ fallback: Int) -> Int { self == 0 ? fallback : self }
}

enum LeakCheckType: String, Identifiable {
    case dns, ipv6, webrtc
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dns: "DNS 泄漏"
        case .ipv6: "IPv6"
        case .webrtc: "WebRTC"
        }
    }
}

struct ConnectionInfo: Sendable {
    var exitIP: String
    var geo: GeoInfo
    var proxyType: ProxyType
    var latency: LatencyResult
    var latencyHistory: [LatencySample]
    var countryFlag: String
    var localLatencyMs: Double
    var exitLatencyMs: Double

    static let placeholder = ConnectionInfo(
        exitIP: "—",
        geo: .placeholder,
        proxyType: .none,
        latency: .placeholder,
        latencyHistory: [],
        countryFlag: "",
        localLatencyMs: 0,
        exitLatencyMs: 0
    )
}

@MainActor
@Observable
class ProxyStatusViewModel {
    var connectionState: ConnectionState = .unknown
    var connectionInfo: ConnectionInfo = .placeholder
    var leakResults: [LeakCheckType: LeakResult] = [
        .dns: .notChecked,
        .ipv6: .notChecked,
        .webrtc: .notApplicable,
    ]
    var dnsLeakDetail: DNSLeakDetail?
    var ipv6LeakDetail: IPv6LeakDetail?
    var trafficVM = TrafficAggregationViewModel()
    var isDetecting: Bool = false
    var detectionTimedOut: Bool = false

    private var timer: Timer?
    private var monitoringActive = false
    private var currentRefreshTask: Task<Void, Never>?
    private var latencyHistory: [LatencySample] = []
    private var previousExitIP: String?
    private var detectionTimeoutTask: Task<Void, Never>?

    private let proxyDetector = ProxyDetector()
    private let ipGeo = IPGeolocation()
    private let latencyProbe = LatencyProbe()
    private let dnsLeakTest = DNSLeakTest()
    private let ipv6LeakTest = IPv6LeakTest()
    private let networkMonitor = NetworkMonitor()

    private var refreshInterval: TimeInterval {
        TimeInterval(UserDefaults.standard.integer(forKey: "refreshInterval").nonZeroOr(30))
    }

    func startMonitoring() {
        guard !monitoringActive else { return }
        monitoringActive = true
        refresh()
        scheduleTimer()

        networkMonitor.onChange = { [weak self] status in
            Task { @MainActor in
                if status == .unsatisfied {
                    self?.connectionState = .disconnected
                } else {
                    self?.refresh()
                }
            }
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
                self?.scheduleTimer()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        monitoringActive = false
        currentRefreshTask?.cancel()
        networkMonitor.stop()
        detectionTimeoutTask?.cancel()
    }

    func refresh() {
        currentRefreshTask?.cancel()
        connectionState = .detecting
        isDetecting = true
        detectionTimedOut = false

        // 10-second detection timeout
        detectionTimeoutTask?.cancel()
        detectionTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard let self, !Task.isCancelled else { return }
            if self.isDetecting {
                self.detectionTimedOut = true
                self.isDetecting = false
            }
        }

        currentRefreshTask = Task { @MainActor [weak self] in
            guard let self else { return }

            // Run all detection tasks in parallel
            async let proxyResult = self.proxyDetector.detect()
            async let ipInfo = self.ipGeo.fetchExitIPInfo()
            async let latencyResult = self.latencyProbe.measure()
            let trafficTask = Task { @MainActor in await self.trafficVM.refresh() }

            let proxy = await proxyResult
            let latency = await latencyResult
            await trafficTask.value

            // Split latency: local proxy + exit
            var localMs: Double = 0
            var exitMs: Double = 0
            if proxy.proxyType != .none {
                let ports = [7890, 1080, 1087, 9090, 9097]
                for port in ports {
                    if let ms = await self.latencyProbe.measureLocalProxy(port: port) {
                        localMs = ms
                        break
                    }
                }
                exitMs = await self.latencyProbe.measureExitLatency()
            }
            guard !Task.isCancelled else { return }

            // Cancel timeout
            self.detectionTimeoutTask?.cancel()
            self.isDetecting = false

            // Update latency history
            let sample = LatencySample(timestamp: Date(), milliseconds: latency.current)
            self.latencyHistory.append(sample)
            if self.latencyHistory.count > 30 {
                self.latencyHistory = Array(self.latencyHistory.suffix(30))
            }

            let state = self.determineState(proxy: proxy, latency: latency)

            if let ip = await ipInfo {
                let flag = Self.countryCodeToFlag(ip.countryCode)
                self.connectionInfo = ConnectionInfo(
                    exitIP: ip.ip,
                    geo: GeoInfo(
                        country: ip.country,
                        countryCode: ip.countryCode,
                        city: ip.city,
                        isp: ip.isp,
                        asn: ip.asn
                    ),
                    proxyType: proxy.proxyType,
                    latency: latency,
                    latencyHistory: self.latencyHistory,
                    countryFlag: flag,
                    localLatencyMs: localMs,
                    exitLatencyMs: exitMs
                )
            } else {
                self.connectionInfo = ConnectionInfo(
                    exitIP: "—",
                    geo: .placeholder,
                    proxyType: proxy.proxyType,
                    latency: latency,
                    latencyHistory: self.latencyHistory,
                    countryFlag: "",
                    localLatencyMs: localMs,
                    exitLatencyMs: exitMs
                )
            }

            // Compute traffic status from actual connection data
            self.trafficVM.computeTrafficStatus(proxyType: proxy.proxyType)

            self.connectionState = state

            if UserDefaults.standard.bool(forKey: "notifyLatency"),
               latency.current > Double(UserDefaults.standard.integer(forKey: "latencyThreshold").nonZeroOr(300)) {
                NotificationManager.shared.sendLatencyWarning(ms: Int(latency.current))
            }

            if state == .connected || state == .warning {
                self.runLeakTests()
            } else {
                self.leakResults = [
                    .dns: .notApplicable,
                    .ipv6: .notApplicable,
                    .webrtc: .notChecked,
                ]
            }
        }
    }

    private func runLeakTests() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.leakResults[.dns] = .testing
            self.leakResults[.ipv6] = .testing

            async let dnsFull = self.dnsLeakTest.runDetailedCheck()
            async let ipv6Full = self.ipv6LeakTest.checkDetailed(proxyType: self.connectionInfo.proxyType)

            let dnsResult = await dnsFull
            let ipv6Result = await ipv6Full

            self.leakResults[.dns] = dnsResult.result
            self.dnsLeakDetail = dnsResult.detail
            self.leakResults[.ipv6] = ipv6Result.hasIPv6Interface ? (ipv6Result.isLeaking ? .fail : (ipv6Result.ipv6Exit != nil ? .pass : .notChecked)) : .notApplicable
            self.ipv6LeakDetail = ipv6Result

            if dnsResult.result == .fail || ipv6Result.isLeaking {
                if self.connectionState == .connected {
                    self.connectionState = .warning
                }
            }
        }
    }

    private func determineState(proxy: ProxyDetectionResult, latency: LatencyResult) -> ConnectionState {
        switch proxy.state {
        case .direct:
            return .direct
        case .connected:
            if latency.current > 300 || latency.loss > 0.5 {
                return .warning
            }
            return .connected
        case .disconnected:
            return .disconnected
        default:
            return .unknown
        }
    }

    func cycleState() {
        let states: [ConnectionState] = [.connected, .warning, .disconnected, .direct]
        guard let idx = states.firstIndex(of: connectionState) else {
            connectionState = states[0]
            return
        }
        connectionState = states[(idx + 1) % states.count]
    }

    nonisolated private static func countryCodeToFlag(_ code: String) -> String {
        let upper = code.uppercased()
        guard upper.count == 2 else { return "" }
        let base: UInt32 = 0x1F1E6 - 65
        var flag = ""
        for scalar in upper.unicodeScalars {
            if let u = Unicode.Scalar(base + scalar.value) {
                flag.append(String(u))
            }
        }
        return flag
    }
}
