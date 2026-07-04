import SystemConfiguration

struct SystemProxyResult: Sendable {
    let proxyType: ProxyType
    let details: String?
}

final class SystemProxyReader: Sendable {
    func read() -> SystemProxyResult? {
        let store = SCDynamicStoreCreate(nil, "ProxyGlass" as CFString, nil, nil)
        let proxyKey = "State:/Network/Global/Proxies" as CFString

        guard let dict = SCDynamicStoreCopyValue(store, proxyKey) as? [String: Any] else {
            return nil
        }

        // Check SOCKS proxy
        if let enabled = dict["SOCKSEnable"] as? Bool, enabled,
           let host = dict["SOCKSProxy"] as? String {
            return SystemProxyResult(
                proxyType: .socks5,
                details: "SOCKS \(host):\(dict["SOCKSPort"] ?? 0)"
            )
        }

        // Check HTTP proxy
        if let enabled = dict["HTTPEnable"] as? Bool, enabled,
           let host = dict["HTTPProxy"] as? String {
            return SystemProxyResult(
                proxyType: .http,
                details: "HTTP \(host):\(dict["HTTPPort"] ?? 0)"
            )
        }

        // Check HTTPS proxy
        if let enabled = dict["HTTPSEnable"] as? Bool, enabled,
           let host = dict["HTTPSProxy"] as? String {
            return SystemProxyResult(
                proxyType: .https,
                details: "HTTPS \(host):\(dict["HTTPSPort"] ?? 0)"
            )
        }

        // Check PAC
        if let enabled = dict["ProxyAutoConfigEnable"] as? Bool, enabled,
           let url = dict["ProxyAutoConfigURLString"] as? String {
            return SystemProxyResult(
                proxyType: .http,
                details: "PAC \(url)"
            )
        }

        return nil
    }
}
