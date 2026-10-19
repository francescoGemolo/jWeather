import AppKit
import Combine

final class StatusItemController: NSObject {
    private let store: WeatherStore
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover: PopoverController
    private var cancellable: AnyCancellable?

    init(store: WeatherStore) {
        self.store = store
        self.popover = PopoverController(store: store)
        super.init()

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.imagePosition = .imageLeading
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        }
        updateButton()
        cancellable = store.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.updateButton() }
        }
    }

    func showWidget() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button)
    }

    private func updateButton() {
        guard let button = statusItem.button else { return }
        let title = " " + store.menuBarTemperature
        if button.title != title { button.title = title }
        let image = NSImage(systemSymbolName: store.menuSymbolName,
                            accessibilityDescription: store.condition.label)
        image?.isTemplate = true
        button.image = image
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            popover.toggle(relativeTo: sender)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        let refresh = NSMenuItem(title: WeatherMessages.menuRefresh, action: #selector(refreshNow), keyEquivalent: "")
        refresh.target = self
        menu.addItem(refresh)
        let tools = NSMenuItem(title: WeatherMessages.menuTestTools, action: #selector(openTestTools), keyEquivalent: "")
        tools.target = self
        menu.addItem(tools)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: WeatherMessages.menuQuit, action: #selector(quit), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func refreshNow() { store.refresh(.manual) }

    @objc private func openTestTools() {
        showWidget()
        store.activeSheet = .test
    }

    @objc private func quit() { NSApp.terminate(nil) }
}