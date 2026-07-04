import SwiftUI

enum ConnectionState: String, CaseIterable, Sendable {
    case connected
    case warning
    case disconnected
    case direct
    case detecting
    case unknown

    var icon: String {
        switch self {
        case .connected: "shield.checkered"
        case .warning: "shield.checkered"
        case .disconnected: "shield.slash"
        case .direct: "shield.lefthalf.filled"
        case .detecting: "shield.checkered"
        case .unknown: "shield.slash"
        }
    }

    var color: Color {
        switch self {
        case .connected: PGStatusColors.safe
        case .warning: PGStatusColors.warn
        case .disconnected: PGStatusColors.danger
        case .direct: PGStatusColors.muted
        case .detecting: PGStatusColors.info
        case .unknown: PGStatusColors.muted
        }
    }

    var label: String {
        switch self {
        case .connected: "已连接"
        case .warning: "连接异常"
        case .disconnected: "未连接"
        case .direct: "裸连"
        case .detecting: "检测中"
        case .unknown: "未知"
        }
    }

    var tunnelPathLineStyle: PathLineStyle {
        switch self {
        case .connected, .warning, .detecting: .solid
        case .disconnected, .direct, .unknown: .dashed
        }
    }

    enum PathLineStyle {
        case solid
        case dashed
    }
}

/// Traffic-based status derived from actual connection data (Clash API /connections).
enum TrafficStatus: Sendable {
    case allProxied
    case mostlyProxied
    case mixed
    case mostlyDirect
    case allDirect
    case noTraffic
    case noData

    var title: String {
        switch self {
        case .allProxied: "全部代理"
        case .mostlyProxied: "大部分代理"
        case .mixed: "混合流量"
        case .mostlyDirect: "大部分直连"
        case .allDirect: "全部直连"
        case .noTraffic: "无活动流量"
        case .noData: "状态未知"
        }
    }

    var icon: String {
        switch self {
        case .allProxied: "checkmark.shield"
        case .mostlyProxied: "shield.lefthalf.filled"
        case .mixed: "network"
        case .mostlyDirect: "shield.slash"
        case .allDirect: "arrow.down.right.circle"
        case .noTraffic: "network.slash"
        case .noData: "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .allProxied: PGStatusColors.safe
        case .mostlyProxied: PGStatusColors.safe
        case .mixed: PGStatusColors.warn
        case .mostlyDirect: PGStatusColors.danger
        case .allDirect: PGStatusColors.danger
        case .noTraffic: PGStatusColors.muted
        case .noData: PGStatusColors.muted
        }
    }

    var heroColor: Color {
        switch self {
        case .allProxied: PGStatusColors.heroTeal
        case .mostlyProxied: PGStatusColors.heroBlueGreen
        case .mixed: PGStatusColors.heroAmber
        case .mostlyDirect: PGStatusColors.heroRedOrange
        case .allDirect: PGStatusColors.heroRedOrange
        case .noTraffic: PGStatusColors.heroGrayBlue
        case .noData: PGStatusColors.heroGrayBlue
        }
    }

    var sfSymbol: String {
        switch self {
        case .allProxied: "checkmark.shield"
        case .mostlyProxied: "shield.lefthalf.filled"
        case .mixed: "network"
        case .mostlyDirect: "shield.slash"
        case .allDirect: "arrow.down.right.circle"
        case .noTraffic: "network.slash"
        case .noData: "questionmark.circle"
        }
    }
}
