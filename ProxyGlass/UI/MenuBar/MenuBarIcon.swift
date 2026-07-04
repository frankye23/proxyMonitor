import AppKit
import SwiftUI

@MainActor
final class MenuBarIcon {
    private let statusItem: NSStatusItem
    private let vm: ProxyStatusViewModel
    private let popover: StatusPopover

    init(vm: ProxyStatusViewModel) {
        self.vm = vm
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = StatusPopover(vm: vm)

        configureButton()
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = NSImage(systemSymbolName: vm.connectionState.icon, accessibilityDescription: "ProxyGlass")?
            .withSymbolConfiguration(config)
        button.image = image
        button.image?.isTemplate = true
    }

    func updateForState(_ state: ConnectionState) {
        guard let button = statusItem.button else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)

        if let baseImage = NSImage(systemSymbolName: state.icon, accessibilityDescription: "ProxyGlass")?
            .withSymbolConfiguration(config) {
            let nsColor = colorForState(state)
            let tinted = tintedImage(baseImage, color: nsColor)
            button.image = tinted
        }

        if !vm.connectionInfo.exitIP.isEmpty && vm.connectionInfo.exitIP != "—" {
            let geo = vm.connectionInfo.geo
            button.title = " \(geo.countryCode) · \(Int(vm.connectionInfo.latency.current))ms"
        } else {
            button.title = ""
        }
    }

    private func colorForState(_ state: ConnectionState) -> NSColor {
        switch state {
        case .connected: NSColor(named: "statusSafe") ?? .systemGreen
        case .warning: NSColor(named: "statusWarn") ?? .systemOrange
        case .disconnected: NSColor(named: "statusMuted") ?? .systemGray
        case .direct: NSColor(named: "statusDanger") ?? .systemRed
        case .detecting: NSColor(named: "statusInfo") ?? .systemBlue
        case .unknown: NSColor(named: "statusMuted") ?? .systemGray
        }
    }

    private func tintedImage(_ image: NSImage, color: NSColor) -> NSImage {
        let tinted = image.copy() as! NSImage
        tinted.lockFocus()
        color.set()
        NSRect(origin: .zero, size: tinted.size).fill(using: .sourceAtop)
        tinted.unlockFocus()
        tinted.isTemplate = false
        return tinted
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        popover.toggle(relativeTo: button)
    }
}
