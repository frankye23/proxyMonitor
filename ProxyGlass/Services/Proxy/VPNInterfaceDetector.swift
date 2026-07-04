import Foundation

struct VPNDetectionResult: Sendable {
    let type: ProxyType
    let interfaceName: String
    let details: String?
}

struct VPNInterfaceInfo: Sendable {
    let name: String
    let hasIPv4: Bool
    let hasIPv6: Bool
}

final class VPNInterfaceDetector: Sendable {
    /// Returns all active non-loopback interfaces grouped by type.
    /// Does NOT treat utun as TUN — macOS creates utun for AirDrop/iCloud/Handoff.
    func detectInterfaces() -> [VPNInterfaceInfo] {
        var interfaces: [String: VPNInterfaceInfo] = [:]
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else {
            return []
        }
        defer { freeifaddrs(ifaddrPtr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let iface = ptr?.pointee {
            let name = String(cString: iface.ifa_name)
            let family = iface.ifa_addr.pointee.sa_family

            if iface.ifa_flags & UInt32(IFF_UP) != 0,
               iface.ifa_flags & UInt32(IFF_LOOPBACK) == 0,
               iface.ifa_flags & UInt32(IFF_RUNNING) != 0 {
                var info = interfaces[name] ?? VPNInterfaceInfo(name: name, hasIPv4: false, hasIPv6: false)
                if family == UInt8(AF_INET) { info = VPNInterfaceInfo(name: name, hasIPv4: true, hasIPv6: info.hasIPv6) }
                if family == UInt8(AF_INET6) { info = VPNInterfaceInfo(name: name, hasIPv4: info.hasIPv4, hasIPv6: true) }
                interfaces[name] = info
            }
            ptr = iface.ifa_next
        }

        return Array(interfaces.values)
    }

    /// Checks if a default route goes through a utun interface by parsing the routing table.
    func hasDefaultRouteViaUtun() -> Bool {
        guard let output = runCommand("/usr/sbin/netstat", args: ["-rn", "-f", "inet"]) else { return false }
        for line in output.components(separatedBy: "\n") {
            let cols = line.split(separator: " ", omittingEmptySubsequences: true)
            // default route line: "default <gateway> ... <interface>"
            if cols.count >= 6, cols[0] == "default" {
                let iface = String(cols.last ?? "")
                if iface.hasPrefix("utun") { return true }
            }
        }
        // Also check inet6
        guard let output6 = runCommand("/usr/sbin/netstat", args: ["-rn", "-f", "inet6"]) else { return false }
        for line in output6.components(separatedBy: "\n") {
            let cols = line.split(separator: " ", omittingEmptySubsequences: true)
            if cols.count >= 3, cols[0] == "default" {
                let iface = String(cols.last ?? "")
                if iface.hasPrefix("utun") { return true }
            }
        }
        return false
    }

    /// Detect non-utun VPN interfaces (IPSec, PPP, WireGuard, tap, tun).
    /// These are definitive VPN indicators.
    func detectDefinitiveVPN(interfaces: [VPNInterfaceInfo]) -> VPNDetectionResult? {
        for iface in interfaces {
            if iface.name.hasPrefix("ipsec") {
                return VPNDetectionResult(type: .ipsec, interfaceName: iface.name, details: "IPSec: \(iface.name)")
            }
            if iface.name.hasPrefix("ppp") {
                return VPNDetectionResult(type: .openVPN, interfaceName: iface.name, details: "PPP: \(iface.name)")
            }
            if iface.name.hasPrefix("wg") {
                return VPNDetectionResult(type: .wireguard, interfaceName: iface.name, details: "WireGuard: \(iface.name)")
            }
            if iface.name.hasPrefix("tun") || iface.name.hasPrefix("tap") {
                return VPNDetectionResult(type: .openVPN, interfaceName: iface.name, details: "OpenVPN: \(iface.name)")
            }
        }
        return nil
    }

    /// Returns true if any utun interface with an IP is present.
    func hasUtunWithIP(interfaces: [VPNInterfaceInfo]) -> Bool {
        interfaces.contains { $0.name.hasPrefix("utun") && ($0.hasIPv4 || $0.hasIPv6) }
    }

    private func runCommand(_ path: String, args: [String]) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}
