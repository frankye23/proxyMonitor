import Foundation

struct DNSLeakDetail: Sendable {
    let dnsIP: String
    let exitIP: String
    let dnsCountry: String
    let isLeaking: Bool
}

struct DNSLeakTestResult: Sendable {
    let result: LeakResult
    let detail: DNSLeakDetail?
    let rawDNSIP: String?
}

final class DNSLeakTest: Sendable {
    private let ipGeo = IPGeolocation()

    func runQuickCheck() async -> LeakResult {
        let full = await runDetailedCheck()
        return full.result
    }

    func runDetailedCheck() async -> DNSLeakTestResult {
        // Primary: ipleak.net JSON endpoint — returns the DNS server IP seen from the outside
        guard let url = URL(string: "https://ipleak.net/json/") else {
            return DNSLeakTestResult(result: .notChecked, detail: nil, rawDNSIP: nil)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dnsIP = json["dns_ip"] as? String, !dnsIP.isEmpty else {
                return DNSLeakTestResult(result: .notChecked, detail: nil, rawDNSIP: nil)
            }

            let exitIP = json["ip"] as? String ?? ""

            if exitIP.isEmpty {
                // Can't determine exit IP from this endpoint, compare with our own exit IP
                if let ourExitIP = await ipGeo.fetchExitIPInfo() {
                    let isLeaking = !areSameNetwork(dnsIP, ourExitIP.ip)
                    return DNSLeakTestResult(
                        result: isLeaking ? .fail : .pass,
                        detail: DNSLeakDetail(dnsIP: dnsIP, exitIP: ourExitIP.ip, dnsCountry: "", isLeaking: isLeaking),
                        rawDNSIP: dnsIP
                    )
                }
                return DNSLeakTestResult(result: .notChecked, detail: nil, rawDNSIP: dnsIP)
            }

            let isLeaking = !areSameNetwork(dnsIP, exitIP)
            return DNSLeakTestResult(
                result: isLeaking ? .fail : .pass,
                detail: DNSLeakDetail(dnsIP: dnsIP, exitIP: exitIP, dnsCountry: "", isLeaking: isLeaking),
                rawDNSIP: dnsIP
            )
        } catch {
            return DNSLeakTestResult(result: .notChecked, detail: nil, rawDNSIP: nil)
        }
    }

    // Check if two IPs are likely on the same network (same /24 or similar ISP block)
    private func areSameNetwork(_ ip1: String, _ ip2: String) -> Bool {
        let parts1 = ip1.split(separator: ".")
        let parts2 = ip2.split(separator: ".")
        guard parts1.count >= 3, parts2.count >= 3 else { return false }
        // Compare first 3 octets (/24 block)
        return parts1[0] == parts2[0] && parts1[1] == parts2[1] && parts1[2] == parts2[2]
    }
}
