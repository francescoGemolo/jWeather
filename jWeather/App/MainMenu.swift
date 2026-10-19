import AppKit

enum MainMenu {
    static func make() -> NSMenu {
        let menu = NSMenu()

        let appItem = NSMenuItem()
        let app = NSMenu()
        app.addItem(withTitle: WeatherMessages.menuAbout,
                    action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        app.addItem(.separator())
        app.addItem(withTitle: WeatherMessages.menuHide,
                    action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(.separator())
        app.addItem(withTitle: WeatherMessages.menuQuit,
                    action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = app
        menu.addItem(appItem)

        let editItem = NSMenuItem()
        let edit = NSMenu(title: WeatherMessages.menuEdit)
        edit.addItem(withTitle: WeatherMessages.menuCut, action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: WeatherMessages.menuCopy, action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: WeatherMessages.menuPaste, action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: WeatherMessages.menuSelectAll, action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        menu.addItem(editItem)

        return menu
    }
}