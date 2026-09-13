import AppKit
import Observation

@MainActor
@Observable
final class AppModel {
    let variations: [Variation]
    private(set) var shortcut: Shortcut
    private(set) var shortcutError: String?

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
        do {
            try manager.start(with: shortcut)
        } catch let error as ShortcutManagerError where shouldRestoreDefault(after: error) {
            restoreDefaultShortcut(after: error, using: manager)
        } catch {
            shortcutError = error.localizedDescription
        }
    }

    func updateShortcut(_ newShortcut: Shortcut) {
        guard let shortcutManager else {
            shortcutError = "The global shortcut handler is unavailable."
            return
        }

        do {
            try shortcutManager.update(newShortcut)
            shortcut = newShortcut
            ShortcutManager.saveShortcut(newShortcut)
            shortcutError = nil
        } catch {
            shortcutError = error.localizedDescription
        }
    }

    func resetShortcut() {
        updateShortcut(.default)
    }

    func copy(_ variation: Variation) {
        let paragraph = ParagraphGenerator.generate(from: variation.words)
        PasteboardWriter.copy(paragraph)
    }

    private func restoreDefaultShortcut(after error: ShortcutManagerError, using manager: ShortcutManager) {
        guard shortcut != .default else {
            shortcutError = error.localizedDescription
            return
        }

        do {
            try manager.update(.default)
            shortcut = .default
            ShortcutManager.saveShortcut(.default)
            shortcutError = "The saved shortcut was unavailable, so the default was restored."
        } catch {
            shortcutError = error.localizedDescription
        }
    }

    private func shouldRestoreDefault(after error: ShortcutManagerError) -> Bool {
        if case .hotKeyRegistrationFailed = error {
            return shortcut != .default
        }
        return false
    }
}
