import SwiftUI

struct AggregatedTrafficView: View {
    let state: ConnectionState
    let trafficStatus: TrafficStatus
    let trafficSubtitle: String
    let proxyLabel: String
    let geoCity: String
    let snapshot: TrafficSnapshot
    let hasAPI: Bool
    let localLatencyMs: Double
    let exitLatencyMs: Double
    let dnsResult: LeakResult
    let ipv6Result: LeakResult

    @State private var showDetails = false

    var body: some View {
        GlassCard {
            VStack(spacing: 14) {
                // 1. Hero status
                heroSection

                // 2. Traffic distribution bar
                if hasAPI {
                    trafficDistribution
                }

                // 3. Rate tiles
                if hasAPI && snapshot.totalRate > 0 {
                    rateTiles
                }

                // 4. Detection chips
                detectionChips

                // 5. Activity summary
                if hasAPI && snapshot.connectionCount > 0 {
                    activitySummary
                }

                // No API hint
                if !hasAPI {
                    Text("需开启 Clash/Surge API 以查看流量")
                        .font(.system(size: 11))
                        .foregroundStyle(PGStatusColors.muted)
                }
            }
        }
    }

    // MARK: - 1. Hero Status Section

    private var heroSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(trafficStatus.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(trafficStatus.heroColor)

                Text(heroSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(PGStatusColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Status icon with glow
            ZStack {
                Circle()
                    .fill(trafficStatus.heroColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Circle()
                    .fill(trafficStatus.heroColor.opacity(0.08))
                    .frame(width: 52, height: 52)
                Image(systemName: trafficStatus.sfSymbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(trafficStatus.heroColor)
            }
        }
    }

    private var heroSubtitle: String {
        var parts: [String] = []
        if proxyLabel != "无代理" && proxyLabel != "未知" {
            parts.append(proxyLabel)
        }
        if hasAPI && snapshot.connectionCount > 0 {
            parts.append("当前活跃流量")
        } else if hasAPI {
            parts.append("暂无活跃流量")
        }
        if !geoCity.isEmpty && geoCity != "—" {
            parts.append("出口\(geoCity)")
        }
        return parts.isEmpty ? trafficSubtitle : parts.joined(separator: " · ")
    }

    // MARK: - 2. Traffic Distribution Bar

    private var trafficDistribution: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Top 活跃连接占比")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(PGStatusColors.textSecondary)
                Spacer()
            }

            // Glass segmented bar
            GeometryReader { geo in
                let w = geo.size.width
                let proxyW = w * snapshot.proxyRatio
                let directW = w * snapshot.directRatio

                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(PGStatusColors.chipBackground)

                    HStack(spacing: 1) {
                        if snapshot.proxyRatio > 0 {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    LinearGradient(
                                        colors: [PGStatusColors.heroTeal.opacity(0.7), PGStatusColors.heroTeal.opacity(0.5)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(proxyW - 1, 4))
                        }
                        if snapshot.directRatio > 0 {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    LinearGradient(
                                        colors: [PGStatusColors.heroRedOrange.opacity(0.6), PGStatusColors.heroRedOrange.opacity(0.4)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(directW - 1, 4))
                        }
                        if snapshot.unknownRatio > 0 {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(PGStatusColors.heroGrayBlue.opacity(0.3))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .frame(height: 10)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Percentage capsules
            HStack(spacing: 8) {
                if snapshot.proxyBytes > 0 || snapshot.totalBytes > 0 {
                    ratioCapsule("代理", percent: snapshot.proxyRatio * 100, color: PGStatusColors.heroTeal)
                }
                if snapshot.directBytes > 0 {
                    ratioCapsule("直连", percent: snapshot.directRatio * 100, color: PGStatusColors.heroRedOrange)
                }
                if snapshot.unknownBytes > 0 {
                    ratioCapsule("未知", percent: snapshot.unknownRatio * 100, color: PGStatusColors.heroGrayBlue)
                }
                Spacer()
            }
        }
    }

    private func ratioCapsule(_ label: String, percent: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(String(format: "%.0f%% %@", percent, label))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(PGStatusColors.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - 3. Rate Metric Tiles

    private var rateTiles: some View {
        HStack(spacing: 8) {
            if snapshot.proxyDownloadRate > 0 || snapshot.proxyUploadRate > 0 {
                rateTile(
                    label: "代理",
                    download: snapshot.proxyDownloadRate,
                    upload: snapshot.proxyUploadRate,
                    color: PGStatusColors.heroTeal
                )
            }
            if snapshot.directDownloadRate > 0 || snapshot.directUploadRate > 0 {
                rateTile(
                    label: "直连",
                    download: snapshot.directDownloadRate,
                    upload: snapshot.directUploadRate,
                    color: PGStatusColors.heroRedOrange
                )
            }
            if snapshot.unknownDownloadRate > 0 || snapshot.unknownUploadRate > 0 {
                rateTile(
                    label: "未知",
                    download: snapshot.unknownDownloadRate,
                    upload: snapshot.unknownUploadRate,
                    color: PGStatusColors.heroGrayBlue
                )
            }
        }
    }

    private func rateTile(label: String, download: Double, upload: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 8))
                        .foregroundStyle(PGStatusColors.textSecondary)
                    Text(formatRate(download))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(PGStatusColors.textPrimary)
                }
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 8))
                        .foregroundStyle(PGStatusColors.textSecondary)
                    Text(formatRate(upload))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(PGStatusColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: PGConstants.chipCornerRadius)
                .fill(PGStatusColors.chipBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PGConstants.chipCornerRadius)
                .strokeBorder(PGStatusColors.chipBorder)
        )
    }

    // MARK: - 4. Detection Chips

    private var detectionChips: some View {
        ChipFlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
            if localLatencyMs > 0 {
                detectionChip(
                    icon: "bolt.fill",
                    text: "本地 \(Int(localLatencyMs))ms",
                    color: localLatencyColor
                )
            }
            if exitLatencyMs > 0 {
                detectionChip(
                    icon: "globe",
                    text: exitLatencyMs > 5000 ? "出口超时" : "出口 \(Int(exitLatencyMs))ms",
                    color: exitLatencyMs > 5000 ? PGStatusColors.danger : exitLatencyColor
                )
            }
            detectionChip(
                icon: "checkmark.shield",
                text: leakChipText("DNS", result: dnsResult),
                color: leakChipColor(dnsResult)
            )
            detectionChip(
                icon: "network",
                text: leakChipText("IPv6", result: ipv6Result),
                color: leakChipColor(ipv6Result)
            )
        }
    }

    private func detectionChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(PGStatusColors.textSecondary)
        }
        .fixedSize()
        .frame(width: 68, height: 24)
        .background(
            Capsule()
                .fill(PGStatusColors.chipBackground)
        )
        .overlay(
            Capsule()
                .strokeBorder(color.opacity(0.2), lineWidth: 0.5)
        )
    }

    private var localLatencyColor: Color {
        if localLatencyMs < 5 { return PGStatusColors.heroTeal }
        if localLatencyMs < 50 { return PGStatusColors.heroAmber }
        return PGStatusColors.heroRedOrange
    }

    private var exitLatencyColor: Color {
        if exitLatencyMs < 500 { return PGStatusColors.heroTeal }
        if exitLatencyMs < 2000 { return PGStatusColors.heroAmber }
        return PGStatusColors.heroRedOrange
    }

    private func leakChipText(_ label: String, result: LeakResult) -> String {
        switch result {
        case .pass: "\(label) 安全"
        case .fail: "\(label) 泄漏"
        case .testing: "\(label) 检测中"
        case .notApplicable: "\(label) 无出口"
        default: "\(label) 未检测"
        }
    }

    private func leakChipColor(_ result: LeakResult) -> Color {
        switch result {
        case .pass: PGStatusColors.heroTeal
        case .fail: PGStatusColors.heroRedOrange
        case .testing: PGStatusColors.heroAmber
        default: PGStatusColors.heroGrayBlue
        }
    }

    // MARK: - 5. Activity Summary

    private var activitySummary: some View {
        VStack(spacing: 8) {
            HStack {
                Text("活跃摘要")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PGStatusColors.textSecondary)
                Text("(\(snapshot.connectionCount))")
                    .font(.system(size: 10))
                    .foregroundStyle(PGStatusColors.muted)
                Spacer()

                if snapshot.connectionCount > 3 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDetails.toggle()
                        }
                    } label: {
                        Text(showDetails ? "收起" : "详情")
                            .font(.system(size: 10))
                            .foregroundStyle(PGStatusColors.info)
                    }
                    .buttonStyle(.plain)
                }
            }

            // All proxied shortcut
            if snapshot.topConnections.allSatisfy({ $0.routeType == .proxy }) && snapshot.topConnections.count > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(PGStatusColors.heroTeal)
                    Text("当前活跃连接最终均经代理节点")
                        .font(.system(size: 10))
                        .foregroundStyle(PGStatusColors.heroTeal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Connection rows (3 default, all if expanded)
            let displayed = showDetails ? snapshot.topConnections : Array(snapshot.topConnections.prefix(3))
            ForEach(displayed) { conn in
                activityRow(conn)
            }
        }
    }

    private func activityRow(_ conn: AggregatedConnection) -> some View {
        HStack(spacing: 8) {
            // Direct indicator bar
            if conn.routeType == .direct {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(PGStatusColors.heroRedOrange)
                    .frame(width: 3, height: 16)
            }

            // Service name (primary)
            Text(conn.serviceName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PGStatusColors.textPrimary)
                .lineLimit(1)

            Spacer()

            // Route badge
            routeBadgeSmall(conn)

            // Rate
            if conn.currentDownload > 0 {
                Text(formatRate(Double(conn.currentDownload)))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(PGStatusColors.textSecondary)
            }
        }
        .help("\(conn.friendlyProcessName) · \(conn.host.isEmpty ? conn.destinationIP : conn.host)")
    }

    private func routeBadgeSmall(_ conn: AggregatedConnection) -> some View {
        HStack(spacing: 3) {
            switch conn.routeType {
            case .proxy:
                Text("PROXY")
                    .foregroundStyle(PGStatusColors.heroTeal)
            case .direct:
                Text("DIRECT")
                    .foregroundStyle(PGStatusColors.heroRedOrange)
                if conn.wentThroughKernel {
                    Text("· 经本地代理内核")
                        .foregroundStyle(PGStatusColors.textSecondary)
                }
            case .unknown:
                Text("UNKNOWN")
                    .foregroundStyle(PGStatusColors.muted)
            }
        }
        .font(.system(size: 9, weight: .medium))
    }

    // MARK: - Helpers

    private func formatRate(_ bytes: Double) -> String {
        if bytes >= 1_000_000 { return String(format: "%.1f MB/s", bytes / 1_000_000) }
        if bytes >= 1_000 { return String(format: "%.1f KB/s", bytes / 1_000) }
        return String(format: "%.0f B/s", bytes)
    }
}

// MARK: - Chip Flow Layout

struct ChipFlowLayout: Layout {
    var horizontalSpacing: CGFloat = 6
    var verticalSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let containerWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > 0 && currentX + size.width > containerWidth {
                currentX = 0
                currentY += rowHeight + verticalSpacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + horizontalSpacing
            maxWidth = max(maxWidth, currentX - horizontalSpacing)
        }

        return (CGSize(width: maxWidth, height: currentY + rowHeight), origins)
    }
}
