import SwiftUI

struct LeakStatusCard: View {
    let results: [LeakCheckType: LeakResult]
    var dnsDetail: DNSLeakDetail?
    var ipv6Detail: IPv6LeakDetail?
    var webRTCDetail: WebRTCLeakDetail?

    @State private var expanded = false

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    ForEach([LeakCheckType.dns, .ipv6, .webrtc], id: \.self) { type in
                        LeakItem(
                            name: type.displayName,
                            result: results[type] ?? .notChecked
                        )
                        .frame(maxWidth: .infinity)

                        if type != .webrtc {
                            Divider()
                                .frame(height: 32)
                        }
                    }
                }

                // Expandable detail section
                if hasDetail {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(expanded ? "收起详情" : "查看详情")
                                .font(.system(size: 11))
                                .foregroundStyle(PGStatusColors.info)
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9))
                                .foregroundStyle(PGStatusColors.info)
                        }
                    }
                    .buttonStyle(.plain)

                    if expanded {
                        VStack(alignment: .leading, spacing: 4) {
                            if let dns = dnsDetail {
                                HStack {
                                    Text("DNS 服务器：")
                                        .font(.system(size: 11))
                                        .foregroundStyle(PGStatusColors.textSecondary)
                                    Text(dns.dnsIP)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(dns.isLeaking ? PGStatusColors.danger : PGStatusColors.safe)
                                }
                                HStack {
                                    Text("出口 IP：")
                                        .font(.system(size: 11))
                                        .foregroundStyle(PGStatusColors.textSecondary)
                                    Text(dns.exitIP)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(PGStatusColors.textPrimary)
                                }
                            }
                            if let ipv6 = ipv6Detail, ipv6.hasIPv6Interface {
                                HStack {
                                    Text("IPv6 接口：")
                                        .font(.system(size: 11))
                                        .foregroundStyle(PGStatusColors.textSecondary)
                                    Text(ipv6.ipv6Exit ?? "无出口")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(ipv6.isLeaking ? PGStatusColors.danger : PGStatusColors.safe)
                                }
                            }
                            if let webrtc = webRTCDetail, !webrtc.localIPs.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("本机 IP（WebRTC 可见）：")
                                        .font(.system(size: 11))
                                        .foregroundStyle(PGStatusColors.textSecondary)
                                    ForEach(webrtc.localIPs, id: \.self) { ip in
                                        Text(ip)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(webrtc.leakingIPs.contains(ip) ? PGStatusColors.danger : PGStatusColors.safe)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }

    private var hasDetail: Bool {
        dnsDetail != nil || (ipv6Detail?.hasIPv6Interface == true) || (webRTCDetail?.localIPs.isEmpty == false)
    }
}

private struct LeakItem: View {
    let name: String
    let result: LeakResult

    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.system(size: 12))
                .foregroundStyle(PGStatusColors.textSecondary)

            HStack(spacing: 4) {
                Image(systemName: result.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(result.color)
                Text(result.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(result.color)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            result == .fail
                ? PGStatusColors.danger.opacity(0.08)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
