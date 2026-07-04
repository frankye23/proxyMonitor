import SwiftUI

enum PGConstants {
    static let panelWidth: CGFloat = 360
    static let panelMaxHeight: CGFloat = 580
    static let panelPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let cardCornerRadius: CGFloat = 12
    static let panelCornerRadius: CGFloat = 16
    static let menuBarIconHeight: CGFloat = 18
    static let defaultRefreshInterval: TimeInterval = 30
    static let tunnelPathHeight: CGFloat = 80
    static let sparklineHeight: CGFloat = 20
    static let toolbarHeight: CGFloat = 36
    static let chipCornerRadius: CGFloat = 8
    static let iconButtonSize: CGFloat = 32
}

enum PGStatusColors {
    static let safe = Color("statusSafe")
    static let warn = Color("statusWarn")
    static let danger = Color("statusDanger")
    static let muted = Color("statusMuted")
    static let info = Color("statusInfo")

    static let tunnelStroke = Color("tunnelPathStroke")
    static let tunnelBroken = Color("tunnelPathBroken")
    static let textPrimary = Color("textPrimary")
    static let textSecondary = Color("textSecondary")

    // Liquid Glass status palette
    static let heroTeal = Color(red: 0.2, green: 0.78, blue: 0.68)       // 全部代理
    static let heroBlueGreen = Color(red: 0.25, green: 0.65, blue: 0.72)  // 大部分代理
    static let heroAmber = Color(red: 0.90, green: 0.72, blue: 0.20)      // 混合流量
    static let heroRedOrange = Color(red: 0.88, green: 0.40, blue: 0.30)  // 疑似直连
    static let heroGrayBlue = Color(red: 0.55, green: 0.60, blue: 0.68)   // 无活动流量

    // Glass chip background
    static let chipBackground = Color.primary.opacity(0.06)
    static let chipBorder = Color.primary.opacity(0.08)
}
