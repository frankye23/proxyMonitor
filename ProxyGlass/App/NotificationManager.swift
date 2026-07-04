import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func sendDisconnectNotification() {
        send(title: "代理连接已断开", body: "检测到网络连接变化，流量可能直连", priority: "high")
    }

    func sendDirectConnectionNotification() {
        send(title: "⚠️ 未走代理", body: "当前流量未通过代理，真实 IP 可能已暴露", priority: "critical")
    }

    func sendLeakNotification(type: String) {
        send(title: "泄漏检测失败", body: "\(type)请求未走代理通道，可能泄露真实地址", priority: "high")
    }

    func sendLatencyWarning(ms: Int) {
        send(title: "延迟过高", body: "当前延迟 \(ms)ms，建议检查代理连接", priority: "low")
    }

    func sendIPChangeNotification(from oldIP: String, to newIP: String) {
        send(title: "出口地址已变更", body: "IP 从 \(oldIP) 变为 \(newIP)", priority: "medium")
    }

    private func send(title: String, body: String, priority: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
