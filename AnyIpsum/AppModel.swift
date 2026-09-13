import AppKit
import Observation

@MainActor
@Observable
final class AppModel {
    let variations: [Variation]
    private(set) var shortcut: Shortcut

    @ObservationIgnored private var shortcutManager: ShortcutManager?
    @ObservationIgnored private var statusItemController: StatusItemController?

    init() {
        variations = (try? VariationStore.load()) ?? []
        shortcut = ShortcutManager.loadShortcut()
    }

    func start() {
        guard shortcutManager == nil else { return }

        statusItemController = StatusItemController(model: self)
        let manager = ShortcutManager { [weak self] in
            Task { @MainActor in
                self?.statusItemController?.openMenu()
            }
        }
        shortcutManager = manager
        manager.start(with: shortcut)
    }

    func updateShortcut(_ newShortcut: Shortcut) {
        shortcut = newShortcut
        ShortcutManager.saveShortcut(newShortcut)
        shortcutManager?.update(newShortcut)
    }

    func resetShortcut() {
        updateShortcut(.default)
    }

    func copy(_ variation: Variation) {
        let paragraph = ParagraphGenerator.generate(from: variation.words)
        PasteboardWriter.copy(paragraph)
    }
}
