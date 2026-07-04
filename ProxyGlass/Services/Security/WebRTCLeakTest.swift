import Foundation

struct WebRTCLeakDetail: Sendable {
    let localIPs: [String]
    let exitIP: String?
    let leakingIPs: [String]
    let isLeaking: Bool
}

final class WebRTCLeakTest: Sendable {
    private let ipGeo = IPGeolocation()

    func runQuickCheck(proxyType: ProxyType = .none) async -> LeakResult {
        let detail = await runDetailedCheck(proxyType: proxyType)
        if detail.localIPs.isEmpty { return .notChecked }
        if proxyType.capturesAllTraffic { return .pass }
        return detail.isLeaking ? .fail : .pass
    }

    func runDetailedCheck(proxyType: ProxyType = .none) async -> WebRTCLeakDetail {
        let localIPs = enumerateLocalIPs()
        guard !localIPs.isEmpty else {
            return WebRTCLeakDetail(localIPs: [], exitIP: nil, leakingIPs: [], isLeaking: false)
        }

        guard let exitInfo = await ipGeo.fetchExitIPInfo() else {
            return WebRTCLeakDetail(localIPs: localIPs, exitIP: nil, leakingIPs: [], isLeaking: false)
        }

        let exitIP = exitInfo.ip

        // If proxy captures all traffic (TUN), WebRTC is routed through the tunnel — no leak
        if proxyType.capturesAllTraffic {
            return WebRTCLeakDetail(localIPs: localIPs, exitIP: exitIP, leakingIPs: [], isLeaking: false)
        }

        // Filter out loopback and link-local; real LAN IPs are potential leak vectors
        let leakingIPs = localIPs.filter { ip in
            guard ip != exitIP else { return false }
            // Link-local IPv6 (fe80::) and loopback are not real leaks
            if ip.hasPrefix("fe80:") { return false }
            return true
        }

        return WebRTCLeakDetail(
            localIPs: localIPs,
            exitIP: exitIP,
            leakingIPs: leakingIPs,
            isLeaking: !leakingIPs.isEmpty
        )
    }

    private nonisolated func enumerateLocalIPs() -> [String] {
        var results: [String] = []
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else { return [] }
        defer { freeifaddrs(ifaddrPtr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let iface = ptr?.pointee {
            let name = String(cString: iface.ifa_name)
            // Skip loopback
            if name == "lo0" { ptr = iface.ifa_next; continue }
            // Skip utun (proxy kernel) and awdl (AirDrop)
            if name.hasPrefix("utun") || name.hasPrefix("awdl") || name.hasPrefix("llw") {
                ptr = iface.ifa_next; continue
            }

            guard let addr = iface.ifa_addr else { ptr = iface.ifa_next; continue }
            let family = addr.pointee.sa_family

            var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) == 0 {
                let ip = String(cString: hostBuffer)
                if family == UInt8(AF_INET) {
                    results.append(ip)
                } else if family == UInt8(AF_INET6) && !ip.hasPrefix("fe80") {
                    results.append(ip)
                }
            }
            ptr = iface.ifa_next
        }
        return results
    }
}
