enum ProxyType: String, CaseIterable, Sendable {
    case socks5, socks4, http, https
    case shadowsocks, shadowsocksR
    case vmess, vless, trojan
    case wireguard, openVPN, ipsec
    case tun, icloudRelay
    case clashTun, clashSystem, surgeTun, surgeSystem
    case systemProxy, envProxy
    case none, unknown

    var capturesAllTraffic: Bool {
        switch self {
        case .tun, .clashTun, .surgeTun, .wireguard, .openVPN, .ipsec:
            true
        default:
            false
        }
    }

    var displayName: String {
        switch self {
        case .socks5: "SOCKS5"
        case .socks4: "SOCKS4"
        case .http: "HTTP"
        case .https: "HTTPS"
        case .shadowsocks: "Shadowsocks"
        case .shadowsocksR: "ShadowsocksR"
        case .vmess: "VMess"
        case .vless: "VLESS"
        case .trojan: "Trojan"
        case .wireguard: "WireGuard"
        case .openVPN: "OpenVPN"
        case .ipsec: "IPSec"
        case .tun: "TUN"
        case .icloudRelay: "iCloud Private Relay"
        case .clashTun: "Clash (TUN)"
        case .clashSystem: "Clash (System)"
        case .surgeTun: "Surge (TUN)"
        case .surgeSystem: "Surge (System)"
        case .systemProxy: "系统代理"
        case .envProxy: "环境变量代理"
        case .none: "无代理"
        case .unknown: "未知"
        }
    }
}
