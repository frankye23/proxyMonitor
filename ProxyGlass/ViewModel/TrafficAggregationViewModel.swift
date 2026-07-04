import SwiftUI
import Observation

@MainActor
@Observable
class TrafficAggregationViewModel {
    var snapshot: TrafficSnapshot = .empty
    var isLoading: Bool = true
    var trafficStatus: TrafficStatus = .noData
    var subtitle: String = ""

    private let aggregator = ConnectionAggregator()

    func refresh() async {
        let result = await aggregator.aggregate()
        withAnimation(.easeInOut(duration: 0.3)) {
            snapshot = result
            isLoading = false
        }
    }

    func computeTrafficStatus(proxyType: ProxyType) {
        guard snapshot.source != .none else {
            trafficStatus = .noData
            subtitle = "无 Clash/Surge API 数据"
            return
        }

        if snapshot.connectionCount == 0 || snapshot.totalRate < 1024 {
            trafficStatus = .noTraffic
            subtitle = idleSubtitle(proxyType: proxyType)
            return
        }

        let proxyRatio = snapshot.proxyRatio

        if snapshot.directBytes == 0 && snapshot.unknownBytes == 0 {
            trafficStatus = .allProxied
            subtitle = "当前活跃连接最终均经代理节点"
        } else if snapshot.proxyBytes == 0 {
            trafficStatus = .allDirect
            subtitle = "当前活跃连接最终均直连"
        } else if proxyRatio > 0.8 {
            trafficStatus = .mostlyProxied
            subtitle = "大部分流量最终经代理节点"
        } else if proxyRatio >= 0.2 {
            trafficStatus = .mixed
            subtitle = "部分流量经代理节点，部分直连"
        } else {
            trafficStatus = .mostlyDirect
            subtitle = "大部分流量最终直连"
        }
    }

    private func idleSubtitle(proxyType: ProxyType) -> String {
        switch proxyType {
        case .none:
            return "未检测到代理配置"
        default:
            return "已检测到 \(proxyType.displayName) 代理配置，但当前没有足够流量判断"
        }
    }

    var dataSourceLabel: String {
        switch snapshot.source {
        case .clash: "Clash"
        case .surge: "Surge"
        case .none: ""
        }
    }

    var hasData: Bool {
        snapshot.source != .none
    }

    func formatBytes(_ bytes: UInt64) -> String {
        let b = Double(bytes)
        if b >= 1_000_000_000 { return String(format: "%.1f GB", b / 1_000_000_000) }
        if b >= 1_000_000 { return String(format: "%.1f MB", b / 1_000_000) }
        if b >= 1_000 { return String(format: "%.1f KB", b / 1_000) }
        return "\(Int(b)) B"
    }

    func formatRate(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond >= 1_000_000 { return String(format: "%.1f MB/s", bytesPerSecond / 1_000_000) }
        if bytesPerSecond >= 1_000 { return String(format: "%.1f KB/s", bytesPerSecond / 1_000) }
        return String(format: "%.0f B/s", bytesPerSecond)
    }
}
