import Foundation

/// Proxy detection orchestrator — coordinates multi-step detection strategy
final class ProxyDetector: Sendable {
    private let systemProxyReader = SystemProxyReader()
    private let vpnDetector = VPNInterfaceDetector()
    private let clashAPI = ClashAPI()
    private let surgeAPI = SurgeAPI()

    /// Detect proxy using the refined priority strategy:
    /// 1. Definitive VPN interfaces (IPSec/PPP/WireGuard/tun/tap)
    /// 2. Clash/Surge API — determines TUN vs System mode by checking utun + route
    /// 3. System proxy config
    /// 4. Environment variable proxy
    /// 5. utun-only fallback (only if route goes through utun)
    func detect() async -> ProxyDetectionResult {
        let interfaces = vpnDetector.detectInterfaces()

        // Step 1: Definitive VPN interfaces (non-utun)
        if let vpnResult = vpnDetector.detectDefinitiveVPN(interfaces: interfaces) {
            return ProxyDetectionResult(
                state: .connected,
                proxyType: vpnResult.type,
                source: .vpnInterface,
                details: vpnResult.details
            )
        }

        let hasUtunIP = vpnDetector.hasUtunWithIP(interfaces: interfaces)
        let hasRouteUtun = hasUtunIP ? vpnDetector.hasDefaultRouteViaUtun() : false

        // Step 2: Clash API
        if let clashResult = try? await clashAPI.query() {
            // Determine Clash mode: if utun active + route goes through utun → TUN, else System
            let isTUN = hasUtunIP && hasRouteUtun
            let proxyType: ProxyType = isTUN ? .clashTun : .clashSystem
            return ProxyDetectionResult(
                state: .connected,
                proxyType: proxyType,
                source: .clashAPI,
                details: clashResult.details
            )
        }

        // Step 3: Surge API
        if let surgeResult = try? await surgeAPI.query() {
            let isTUN = hasUtunIP && hasRouteUtun
            let proxyType: ProxyType = isTUN ? .surgeTun : .surgeSystem
            return ProxyDetectionResult(
                state: .connected,
                proxyType: proxyType,
                source: .surgeAPI,
                details: surgeResult.details
            )
        }

        // Step 4: System proxy config
        if let sysProxy = systemProxyReader.read() {
            return ProxyDetectionResult(
                state: .connected,
                proxyType: sysProxy.proxyType,
                source: .systemProxy,
                details: sysProxy.details
            )
        }

        // Step 5: Environment variable proxy
        if let envProxy = detectEnvProxy() {
            return ProxyDetectionResult(
                state: .connected,
                proxyType: .envProxy,
                source: .envProxy,
                details: envProxy
            )
        }

        // Step 6: utun-only fallback — only if default route goes through utun
        // This catches WireGuard or other VPN tools that don't expose an API
        if hasUtunIP && hasRouteUtun {
            return ProxyDetectionResult(
                state: .connected,
                proxyType: .tun,
                source: .vpnInterface,
                details: "TUN (route via utun)"
            )
        }

        return ProxyDetectionResult(
            state: .direct,
            proxyType: .none,
            source: .none,
            details: nil
        )
    }

    private func detectEnvProxy() -> String? {
        let env = ProcessInfo.processInfo.environment
        if let http = env["http_proxy"] ?? env["HTTP_PROXY"] {
            return "HTTP: \(http)"
        }
        if let https = env["https_proxy"] ?? env["HTTPS_PROXY"] {
            return "HTTPS: \(https)"
        }
        if let all = env["all_proxy"] ?? env["ALL_PROXY"] {
            return "ALL: \(all)"
        }
        return nil
    }
}

struct ProxyDetectionResult: Sendable {
    let state: ConnectionState
    let proxyType: ProxyType
    let source: DetectionSource
    let details: String?

    enum DetectionSource: Sendable {
        case vpnInterface, clashAPI, surgeAPI, systemProxy, envProxy, none
    }
}
