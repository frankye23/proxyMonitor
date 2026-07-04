import SwiftUI

struct StatusPanelView: View {
    @Bindable var vm: ProxyStatusViewModel
    @State private var visibleCards = 0
    @State private var isFirstAppear = true

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 0) {
                // Scrollable content area
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: PGConstants.cardSpacing) {
                        if vm.connectionState == .unknown && isFirstAppear {
                            SkeletonTrafficCard()
                            SkeletonCard()
                        } else if vm.detectionTimedOut {
                            GlassCard {
                                VStack(spacing: 12) {
                                    Image(systemName: "clock.badge.exclamationmark")
                                        .font(.system(size: 24))
                                        .foregroundStyle(PGStatusColors.warn)
                                    Text("检测超时")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(PGStatusColors.warn)
                                    Button {
                                        vm.refresh()
                                    } label: {
                                        Label("重新检测", systemImage: "arrow.clockwise")
                                            .font(.system(size: 12))
                                            .foregroundStyle(PGStatusColors.info)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            // Main traffic card (hero + rates + chips + activity)
                            AggregatedTrafficView(
                                state: vm.connectionState,
                                trafficStatus: vm.trafficVM.trafficStatus,
                                trafficSubtitle: vm.trafficVM.subtitle,
                                proxyLabel: vm.connectionInfo.proxyType.displayName,
                                geoCity: vm.connectionInfo.geo.city,
                                snapshot: vm.trafficVM.snapshot,
                                hasAPI: vm.trafficVM.hasData,
                                localLatencyMs: vm.connectionInfo.localLatencyMs,
                                exitLatencyMs: vm.connectionInfo.exitLatencyMs,
                                dnsResult: vm.leakResults[.dns] ?? .notChecked,
                                ipv6Result: vm.leakResults[.ipv6] ?? .notChecked
                            )
                            .opacity(visibleCards >= 1 ? 1 : 0)

                            // Connection info (exit IP + geo)
                            ConnectionInfoCard(
                                info: vm.connectionInfo,
                                state: vm.connectionState
                            )
                            .opacity(visibleCards >= 2 ? 1 : 0)

                            // Security leak detection
                            LeakStatusCard(
                                results: vm.leakResults,
                                dnsDetail: vm.dnsLeakDetail,
                                ipv6Detail: vm.ipv6LeakDetail,
                                webRTCDetail: vm.webRTCLeakDetail
                            )
                            .opacity(visibleCards >= 3 ? 1 : 0)
                        }
                    }
                    .padding(.horizontal, PGConstants.panelPadding)
                    .padding(.top, PGConstants.panelPadding)
                    .padding(.bottom, PGConstants.cardSpacing)
                }

                // Bottom toolbar — glass icon buttons
                HStack(spacing: 16) {
                    Spacer()

                    GlassIconButton(systemName: "arrow.clockwise", help: "刷新") {
                        vm.refresh()
                    }

                    GlassIconButton(systemName: "gearshape", help: "设置") {
                        openSettings()
                    }

                    GlassIconButton(systemName: "power", help: "退出 ProxyGlass") {
                        NSApp.terminate(nil)
                    }

                    Spacer()
                }
                .frame(height: PGConstants.toolbarHeight)
                .padding(.bottom, PGConstants.panelPadding)
            }
        }
        .frame(width: PGConstants.panelWidth)
        .frame(maxHeight: PGConstants.panelMaxHeight)
        .onAppear {
            isFirstAppear = true
            Task {
                await NotificationManager.shared.requestPermission()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFirstAppear = false
                }
                animateCardsIn()
            }
        }
        .onDisappear {
            vm.stopMonitoring()
            visibleCards = 0
        }
        .onChange(of: vm.connectionState) { _, newState in
            sendNotification(for: newState)
        }
    }

    private func animateCardsIn() {
        for i in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    visibleCards = i
                }
            }
        }
    }

    private func sendNotification(for state: ConnectionState) {
        guard !isFirstAppear else { return }
        switch state {
        case .disconnected:
            NotificationManager.shared.sendDisconnectNotification()
        case .direct:
            NotificationManager.shared.sendDirectConnectionNotification()
        default:
            break
        }
    }

    private func openSettings() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

// MARK: - Glass Icon Button

private struct GlassIconButton: View {
    let systemName: String
    let help: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(PGStatusColors.textSecondary)
                .frame(width: PGConstants.iconButtonSize, height: PGConstants.iconButtonSize)
                .background(
                    Circle()
                        .fill(isHovered ? PGStatusColors.chipBackground : Color.clear)
                )
                .overlay(
                    Circle()
                        .strokeBorder(PGStatusColors.chipBorder, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Skeleton

private struct SkeletonTrafficCard: View {
    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        SkeletonView(width: 100, height: 16)
                        SkeletonView(width: 200, height: 10)
                    }
                    Spacer()
                    SkeletonView(width: 44, height: 44)
                        .clipShape(Circle())
                }

                SkeletonView(height: 10)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                HStack(spacing: 8) {
                    SkeletonView(height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    SkeletonView(height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                HStack(spacing: 6) {
                    SkeletonView(width: 60, height: 20)
                        .clipShape(Capsule())
                    SkeletonView(width: 70, height: 20)
                        .clipShape(Capsule())
                    SkeletonView(width: 55, height: 20)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
