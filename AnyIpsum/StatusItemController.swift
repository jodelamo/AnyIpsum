import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let model: AppModel
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    init(model: AppModel) {
        self.model = model
        super.init()

        if let image = NSImage(named: "MenuIcon") {
            image.isTemplate = true
            statusItem.button?.image = image
        }
        statusItem.menu = makeMenu()
    }

    func openMenu() {
        statusItem.button?.performClick(nil)
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        for (index, variation) in model.variations.enumerated() {
            let item = NSMenuItem(
                title: variation.name,
                action: #selector(copyVariation(_:)),
                keyEquivalent: index < 9 ? "\(index + 1)" : ""
            )
            item.target = self
            item.tag = index
            item.keyEquivalentModifierMask = []
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let settings = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settings.target = self
        menu.addItem(settings)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit AnyIpsum",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quit)

        return menu
    }

    @objc private func copyVariation(_ sender: NSMenuItem) {
        guard model.variations.indices.contains(sender.tag) else { return }
        model.copy(model.variations[sender.tag])
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            guard let settingsCommand = self.findSettingsCommand(in: NSApp.mainMenu),
                  let action = settingsCommand.action else {
                return
            }
            NSApp.sendAction(action, to: settingsCommand.target, from: settingsCommand)
        }
    }

    private func findSettingsCommand(in menu: NSMenu?) -> NSMenuItem? {
        guard let menu else { return nil }

        for item in menu.items {
            if item.keyEquivalent == ",", item.keyEquivalentModifierMask.contains(.command) {
                return item
            }
            if let command = findSettingsCommand(in: item.submenu) {
                return command
            }
        }
        return nil
    }
}
