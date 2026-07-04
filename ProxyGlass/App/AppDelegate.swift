import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarIcon: MenuBarIcon?
    private let vm = ProxyStatusViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        menuBarIcon = MenuBarIcon(vm: vm)
        vm.startMonitoring()
        observeChanges()
    }

    func applicationWillTerminate(_ notification: Notification) {
        vm.stopMonitoring()
    }

    private func observeChanges() {
        withObservationTracking {
            _ = vm.connectionState
            _ = vm.connectionInfo
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.menuBarIcon?.updateForState(self.vm.connectionState)
                self.observeChanges()
            }
        }
    }
}
