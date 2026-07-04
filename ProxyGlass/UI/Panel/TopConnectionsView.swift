import SwiftUI

struct TopConnectionsView: View {
    let connections: [AggregatedConnection]
    let totalCount: Int

    var body: some View {
        VStack(spacing: 8) {
            if connections.isEmpty {
                Text("无活跃连接")
                    .font(.system(size: 11))
                    .foregroundStyle(PGStatusColors.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            } else {
                // All proxied shortcut
                if connections.allSatisfy({ $0.routeType == .proxy }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(PGStatusColors.heroTeal)
                        Text("当前活跃连接最终均经代理节点")
                            .font(.system(size: 11))
                            .foregroundStyle(PGStatusColors.heroTeal)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 2)
                }

                ForEach(connections) { conn in
                    connectionRow(conn)
                }

                if totalCount > 5 {
                    Text("共 \(totalCount) 条活跃连接，显示 Top 5")
                        .font(.system(size: 9))
                        .foregroundStyle(PGStatusColors.muted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(.top, 4)
    }

    private func connectionRow(_ conn: AggregatedConnection) -> some View {
        HStack(spacing: 8) {
            if conn.routeType == .direct {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(PGStatusColors.heroRedOrange)
                    .frame(width: 3, height: 16)
            }

            HStack(spacing: 6) {
                Text(conn.friendlyProcessName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PGStatusColors.textPrimary)

                Text("·")
                    .foregroundStyle(PGStatusColors.muted)

                Text(conn.serviceName)
                    .font(.system(size: 10))
                    .foregroundStyle(PGStatusColors.textSecondary)

                Text("·")
                    .foregroundStyle(PGStatusColors.muted)

                routeBadge(conn)

                Spacer()

                if conn.currentDownload > 0 {
                    Text(formatRate(Double(conn.currentDownload)))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(PGStatusColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 4)
        .help(conn.host.isEmpty ? conn.destinationIP : conn.host)
    }

    private func routeBadge(_ conn: AggregatedConnection) -> some View {
        Group {
            switch conn.routeType {
            case .proxy:
                Text("PROXY")
                    .foregroundStyle(PGStatusColors.heroTeal)
            case .direct:
                HStack(spacing: 2) {
                    Text("DIRECT")
                        .foregroundStyle(PGStatusColors.heroRedOrange)
                    if conn.wentThroughKernel {
                        Text("· 经本地代理内核")
                            .foregroundStyle(PGStatusColors.textSecondary)
                    }
                }
            case .unknown:
                Text("UNKNOWN")
                    .foregroundStyle(PGStatusColors.muted)
            }
        }
        .font(.system(size: 9, weight: .medium))
    }

    private func formatRate(_ bytes: Double) -> String {
        if bytes >= 1_000_000 { return String(format: "%.1f MB/s", bytes / 1_000_000) }
        if bytes >= 1_000 { return String(format: "%.1f KB/s", bytes / 1_000) }
        return String(format: "%.0f B/s", bytes)
    }
}
