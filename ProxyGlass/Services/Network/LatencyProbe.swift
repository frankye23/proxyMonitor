import Foundation
import Network

struct SplitLatency: Sendable {
    let local: Double  // TCP connect to local proxy port
    let exit: Double   // Through proxy to remote endpoint
    let current: Double // backward compat: equals local
    let min: Double
    let max: Double
    let avg: Double
    let loss: Double

    static let placeholder = SplitLatency(local: 0, exit: 0, current: 0, min: 0, max: 0, avg: 0, loss: 0)
}

final class LatencyProbe: Sendable {
    private let targets: [(String, UInt16)] = [
        ("1.1.1.1", 443),
        ("8.8.8.8", 443),
        ("cloudflare.com", 443),
    ]

    /// Measure local proxy latency (TCP connect to 127.0.0.1:port)
    func measureLocalProxy(port: Int) async -> Double? {
        await measureSingle(host: "127.0.0.1", port: UInt16(port))
    }

    /// Measure exit latency through proxy (via Clash API to a remote endpoint)
    func measureExitLatency() async -> Double {
        let start = ContinuousClock.now
        guard let url = URL(string: "https://www.gstatic.com/generate_204") else { return 0 }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            let elapsed = start.duration(to: .now)
            let ms = Double(elapsed.components.seconds) * 1000.0
                + Double(elapsed.components.attoseconds) / 1_000_000_000_000_000.0
            if let http = response as? HTTPURLResponse, http.statusCode == 204 || http.statusCode == 200 {
                return ms
            }
            return 0
        } catch {
            return 0
        }
    }

    /// Legacy measure for backward compat
    func measure() async -> LatencyResult {
        var samples: [Double] = []

        for (host, port) in targets {
            if let ms = await measureSingle(host: host, port: port) {
                samples.append(ms)
            }
        }

        guard !samples.isEmpty else {
            return LatencyResult(current: 0, min: 0, max: 0, avg: 0, loss: 1.0)
        }

        let loss = Double(targets.count - samples.count) / Double(targets.count)
        return LatencyResult(
            current: samples.last ?? 0,
            min: samples.min() ?? 0,
            max: samples.max() ?? 0,
            avg: samples.reduce(0, +) / Double(samples.count),
            loss: loss
        )
    }

    private func measureSingle(host: String, port: UInt16) async -> Double? {
        await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(rawValue: port)!,
                using: .tcp
            )
            let start = ContinuousClock.now
            let didResume = Mutex<Bool>(false)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let elapsed = start.duration(to: .now)
                    let ms = Double(elapsed.components.seconds) * 1000.0
                        + Double(elapsed.components.attoseconds) / 1_000_000_000_000_000.0
                    connection.cancel()
                    let shouldResume = didResume.withLock { val -> Bool in
                        if val { return false }
                        val = true
                        return true
                    }
                    if shouldResume { continuation.resume(returning: ms) }
                case .failed:
                    connection.cancel()
                    let shouldResume = didResume.withLock { val -> Bool in
                        if val { return false }
                        val = true
                        return true
                    }
                    if shouldResume { continuation.resume(returning: nil) }
                case .waiting:
                    connection.cancel()
                    let shouldResume = didResume.withLock { val -> Bool in
                        if val { return false }
                        val = true
                        return true
                    }
                    if shouldResume { continuation.resume(returning: nil) }
                default:
                    break
                }
            }

            connection.start(queue: .global())

            Task {
                try? await Task.sleep(for: .seconds(5))
                connection.cancel()
                let shouldResume = didResume.withLock { val -> Bool in
                    if val { return false }
                    val = true
                    return true
                }
                if shouldResume { continuation.resume(returning: nil) }
            }
        }
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
