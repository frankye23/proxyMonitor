import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("refreshInterval") private var refreshInterval = 30
    @AppStorage("menuBarDisplay") private var menuBarDisplay = "iconOnly"
    @AppStorage("notifyDisconnect") private var notifyDisconnect = true
    @AppStorage("notifyLeak") private var notifyLeak = true
    @AppStorage("notifyLatency") private var notifyLatency = false
    @AppStorage("latencyThreshold") private var latencyThreshold = 300

    var body: some View {
        Form {
            Section("通用") {
                Toggle("开机启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
                Picker("检测间隔", selection: $refreshInterval) {
                    Text("10 秒").tag(10)
                    Text("30 秒").tag(30)
                    Text("1 分钟").tag(60)
                    Text("5 分钟").tag(300)
                }
            }

            Section("菜单栏") {
                Picker("显示内容", selection: $menuBarDisplay) {
                    Text("仅图标").tag("iconOnly")
                    Text("+ 国家").tag("country")
                    Text("+ 延迟").tag("latency")
                    Text("全部").tag("full")
                }
            }

            Section("通知") {
                Toggle("断连通知", isOn: $notifyDisconnect)
                Toggle("泄漏通知", isOn: $notifyLeak)
                Toggle("延迟告警", isOn: $notifyLatency)
                if notifyLatency {
                    Stepper("告警阈值: \(latencyThreshold)ms", value: $latencyThreshold, in: 100...500, step: 50)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 320)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set launch at login: \(error)")
            }
        }
    }
}
