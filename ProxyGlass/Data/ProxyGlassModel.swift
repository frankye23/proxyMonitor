import SwiftData
import Foundation

@Model
final class DetectionRecord {
    var timestamp: Date
    var exitIP: String
    var country: String
    var proxyType: String
    var latencyMS: Double
    var dnsLeak: Bool
    var connectionState: String

    init(timestamp: Date, exitIP: String, country: String, proxyType: String, latencyMS: Double, dnsLeak: Bool, connectionState: String) {
        self.timestamp = timestamp
        self.exitIP = exitIP
        self.country = country
        self.proxyType = proxyType
        self.latencyMS = latencyMS
        self.dnsLeak = dnsLeak
        self.connectionState = connectionState
    }
}
