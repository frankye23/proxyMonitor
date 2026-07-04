import Foundation

struct IPv6LeakDetail: Sendable {
    let hasIPv6Interface: Bool
    let ipv6Exit: String?
    let isLeaking: Bool
}

final class IPv6LeakTest: Sendable {
    func check(proxyType: ProxyType = .none) async -> LeakResult {
        let detail = await checkDetailed(proxyType: proxyType)
        if !detail.hasIPv6Interface { return .notApplicable }
        if detail.isLeaking { return .fail }
        if detail.ipv6Exit != nil { return .pass }
        return .notChecked
    }

    func checkDetailed(proxyType: ProxyType = .none) async -> IPv6LeakDetail {
        let ipv6Active = checkActiveIPv6()
        if !ipv6Active {
            return IPv6LeakDetail(hasIPv6Interface: false, ipv6Exit: nil, isLeaking: false)
        }

        guard let url = URL(string: "https://api6.ip.sb/") else {
            return IPv6LeakDetail(hasIPv6Interface: true, ipv6Exit: nil, isLeaking: false)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ipv6 = json["ip"] as? String, !ipv6.isEmpty else {
                return IPv6LeakDetail(hasIPv6Interface: true, ipv6Exit: nil, isLeaking: false)
            }
            // TUN-mode proxies capture all traffic including IPv6,
            // so a valid IPv6 response means the proxy handles it — not a leak
            if proxyType.capturesAllTraffic {
                return IPv6LeakDetail(hasIPv6Interface: true, ipv6Exit: ipv6, isLeaking: false)
            }
            return IPv6LeakDetail(hasIPv6Interface: true, ipv6Exit: ipv6, isLeaking: true)
        } catch {
            return IPv6LeakDetail(hasIPv6Interface: true, ipv6Exit: nil, isLeaking: false)
        }
    }

    private func checkActiveIPv6() -> Bool {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else { return false }
        defer { freeifaddrs(ifaddrPtr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let iface = ptr?.pointee {
            let name = String(cString: iface.ifa_name)
            if name == "lo0" { ptr = iface.ifa_next; continue }
            if iface.ifa_addr.pointee.sa_family == UInt8(AF_INET6) {
                if iface.ifa_flags & UInt32(IFF_UP) != 0,
                   iface.ifa_flags & UInt32(IFF_RUNNING) != 0 {
                    return true
                }
            }
            ptr = iface.ifa_next
        }
        return false
    }
}
