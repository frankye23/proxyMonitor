import SwiftUI

struct TunnelPathView: View {
    let state: ConnectionState
    let proxyLabel: String

    var body: some View {
        HStack(spacing: 0) {
            NodeView(icon: "house.fill", label: "本地")
                .frame(width: 60)

            TunnelLine(isActive: state == .connected || state == .warning, state: state)
                .frame(height: 2)
                .frame(maxWidth: .infinity)

            NodeView(icon: "shield.fill", label: state.label, tintColor: state.color)
                .frame(width: 80)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: state)

            TunnelLine(isActive: state == .connected || state == .warning, state: state)
                .frame(height: 2)
                .frame(maxWidth: .infinity)

            NodeView(icon: "globe", label: "目标")
                .frame(width: 60)
        }
        .frame(height: PGConstants.tunnelPathHeight - 32)
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: PGConstants.tunnelPathHeight)
        .glassEffect(.regular, in: .rect(cornerRadius: PGConstants.cardCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("隧道路径")
        .accessibilityValue(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        switch state {
        case .connected: "本地通过\(proxyLabel)代理连接到目标，状态正常"
        case .warning: "本地通过\(proxyLabel)代理连接到目标，连接异常"
        case .disconnected: "代理未连接"
        case .direct: "当前未走代理，流量直连"
        case .detecting: "正在检测代理状态"
        case .unknown: "代理状态未知"
        }
    }
}

private struct NodeView: View {
    let icon: String
    let label: String
    var tintColor: Color = PGStatusColors.textSecondary

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(tintColor)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(PGStatusColors.textSecondary)
        }
    }
}

private struct TunnelLine: View {
    let isActive: Bool
    let state: ConnectionState

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let y = size.height / 2
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }

                let strokeColor = isActive ? PGStatusColors.tunnelStroke : PGStatusColors.tunnelBroken
                let style = StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    dash: isActive ? [] : [6, 4]
                )
                context.stroke(path, with: .color(strokeColor.opacity(0.6)), style: style)

                if isActive {
                    let date = timeline.date
                    let speed: Double = state == .warning ? 3.0 : 2.0
                    let t = date.timeIntervalSinceReferenceDate.remainder(dividingBy: speed) / speed
                    for i in 0..<3 {
                        let offset = (t + Double(i) / 3.0).truncatingRemainder(dividingBy: 1.0)
                        let x = size.width * offset
                        let glowRect = CGRect(x: x - 5, y: y - 5, width: 10, height: 10)
                        context.fill(
                            Path(ellipseIn: glowRect),
                            with: .color(PGStatusColors.info.opacity(0.3))
                        )
                        let dotRect = CGRect(x: x - 2, y: y - 2, width: 4, height: 4)
                        context.fill(
                            Path(ellipseIn: dotRect),
                            with: .color(PGStatusColors.info.opacity(0.8))
                        )
                    }
                }
            }
        }
        .drawingGroup()
    }
}
