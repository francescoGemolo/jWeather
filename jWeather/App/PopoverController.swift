import AppKit
import SwiftUI

final class PopoverPanel: NSPanel {
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: Theme.panelWidth, height: 380),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .popUpMenu
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool { true }
}

final class PopoverController: NSObject, NSWindowDelegate {
    private let store: WeatherStore
    private let model: PopoverModel
    private let panel: PopoverPanel
    private let hosting: NSHostingView<PopoverRootView>
    private let blurView = NSVisualEffectView()
    private var keyMonitor: Any?
    private var lastHide = Date.distantPast

    init(store: WeatherStore) {
        let model = PopoverModel()
        self.store = store
        self.model = model
        self.hosting = NSHostingView(rootView: PopoverRootView(store: store, model: model))
        self.panel = PopoverPanel()
        super.init()
        blurView.material = .popover
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        hosting.frame = blurView.bounds
        hosting.autoresizingMask = [.width, .height]
        blurView.addSubview(hosting)
        panel.contentView = blurView
        panel.delegate = self
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if panel.isVisible {
            hide()
        } else if Date().timeIntervalSince(lastHide) > 0.2 {
            show(relativeTo: button)
        }
    }

    func show(relativeTo button: NSStatusBarButton) {
        guard !panel.isVisible, let buttonWindow = button.window else { return }
        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))

        hosting.layoutSubtreeIfNeeded()
        var size = hosting.fittingSize
        if size.width < 10 || size.height < 10 { size = NSSize(width: Theme.panelWidth, height: 380) }

        let visible = (buttonWindow.screen ?? NSScreen.main)?.visibleFrame ?? .zero
        var x = buttonRect.midX - size.width / 2
        x = min(max(x, visible.minX + 8), visible.maxX - size.width - 8)
        let y = buttonRect.minY - size.height - 2

        model.appeared = false
        model.caretX = min(max(buttonRect.midX - x, 40), size.width - 40)
        blurView.maskImage = Self.shapeMask(size: size, caretX: model.caretX)
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            panel.animator().alphaValue = 1
        }
        NSApp.activate()
        installKeyMonitor()
        store.popoverDidOpen()
        DispatchQueue.main.async { self.model.appeared = true }
    }

    private static func shapeMask(size: NSSize, caretX: CGFloat) -> NSImage {
        NSImage(size: size, flipped: true) { rect in
            let radius = Theme.panelRadius
            let top = PopoverShape.caretHeight
            let half = PopoverShape.caretWidth / 2
            let x = min(max(caretX, radius + half + 2), rect.width - radius - half - 2)
            let path = NSBezierPath()
            path.move(to: NSPoint(x: radius, y: top))
            path.line(to: NSPoint(x: x - half, y: top))
            path.line(to: NSPoint(x: x - 2.4, y: 1.2))
            path.curve(to: NSPoint(x: x + 2.4, y: 1.2), controlPoint1: NSPoint(x: x - 1.0, y: 0.1), controlPoint2: NSPoint(x: x + 1.0, y: 0.1))
            path.line(to: NSPoint(x: x + half, y: top))
            path.line(to: NSPoint(x: rect.width - radius, y: top))
            path.appendArc(from: NSPoint(x: rect.width, y: top), to: NSPoint(x: rect.width, y: rect.height), radius: radius)
            path.appendArc(from: NSPoint(x: rect.width, y: rect.height), to: NSPoint(x: 0, y: rect.height), radius: radius)
            path.appendArc(from: NSPoint(x: 0, y: rect.height), to: NSPoint(x: 0, y: top), radius: radius)
            path.appendArc(from: NSPoint(x: 0, y: top), to: NSPoint(x: rect.width / 2, y: top), radius: radius)
            path.close()
            NSColor.black.setFill()
            path.fill()
            return true
        }
    }

    func hide() {
        guard panel.isVisible else { return }
        model.appeared = false
        store.activeSheet = nil
        panel.orderOut(nil)
        removeKeyMonitor()
        lastHide = Date()
    }

    func windowDidResignKey(_ notification: Notification) { hide() }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.panel.isVisible else { return event }
            switch event.keyCode {
            case 53:
                if self.store.activeSheet != nil { self.store.activeSheet = nil } else { self.hide() }
                return nil
            case 123 where self.store.activeSheet == nil:
                self.store.selectAdjacentCity(-1)
                return nil
            case 124 where self.store.activeSheet == nil:
                self.store.selectAdjacentCity(1)
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor { NSEvent.removeMonitor(monitor) }
        keyMonitor = nil
    }
}