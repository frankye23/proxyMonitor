import SwiftUI

struct ConnectionInfoCard: View {
    let info: ConnectionInfo
    let state: ConnectionState

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if !info.exitIP.isEmpty && info.exitIP != "—" {
                        CopyableText(text: info.exitIP)
                    } else {
                        Text("—")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(PGStatusColors.muted)
                    }
                    Spacer()
                    if !info.countryFlag.isEmpty {
                        Text(info.countryFlag)
                            .font(.system(size: 14))
                    }
                }

                Text(info.geo.displayLocation)
                    .font(.system(size: 13))
                    .foregroundStyle(PGStatusColors.textSecondary)

                Divider()

                HStack {
                    Text(info.proxyType.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PGStatusColors.info)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(PGStatusColors.info.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Spacer()

                    if info.latency.current > 0 {
                        Text("\(Int(info.latency.current))ms")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(latencyColor)
                            .contentTransition(.numericText())

                        Text("· \(Int(info.latency.loss * 100))% 丢包")
                            .font(.system(size: 12))
                            .foregroundStyle(PGStatusColors.textSecondary)
                    }
                }

                if !info.latencyHistory.isEmpty {
                    LatencySparkline(samples: info.latencyHistory, color: latencyColor)
                        .frame(height: PGConstants.sparklineHeight)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("连接详情")
        .accessibilityValue(accessibilityValue)
    }

    private var latencyColor: Color {
        let ms = info.latency.current
        if ms < 100 { return PGStatusColors.safe }
        if ms < 300 { return PGStatusColors.warn }
        return PGStatusColors.danger
    }

    private var accessibilityValue: String {
        var parts: [String] = []
        if info.exitIP != "—" { parts.append("出口IP \(info.exitIP)") }
        if info.geo.country != "—" { parts.append(info.geo.displayLocation) }
        parts.append("协议 \(info.proxyType.displayName)")
        if info.latency.current > 0 { parts.append("延迟 \(Int(info.latency.current))毫秒") }
        return parts.joined(separator: "，")
    }
}
