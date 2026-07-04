import SwiftUI
import AppKit

@MainActor
final class StatusPopover {
    let popover = NSPopover()
    private let vm: ProxyStatusViewModel

    init(vm: ProxyStatusViewModel) {
        self.vm = vm

        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: PGConstants.panelWidth, height: 0)

        let hostingView = NSHostingView(rootView: StatusPanelView(vm: vm))
        hostingView.frame.size = hostingView.fittingSize

        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = hostingView
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
