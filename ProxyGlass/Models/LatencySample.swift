import Foundation

struct LatencySample: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let milliseconds: Double
}

struct LatencyResult: Sendable {
    let current: Double
    let min: Double
    let max: Double
    let avg: Double
    let loss: Double

    static let placeholder = LatencyResult(current: 0, min: 0, max: 0, avg: 0, loss: 0)
}
