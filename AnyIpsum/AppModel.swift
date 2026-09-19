import AppKit
import KeyboardShortcuts
import Observation

@MainActor
@Observable
final class AppModel {
    private(set) var variations: [Variation]
    private(set) var variationError: String?
    private(set) var launchesAtLogin: Bool
    private(set) var launchAtLoginError: String?

    @ObservationIgnored private var shortcutManager: ShortcutManager?
    @ObservationIgnored private var statusItemController: StatusItemController?
    @ObservationIgnored private let launchAtLoginManager = LaunchAtLoginManager()

    init() {
        variations = (try? VariationStore.load()) ?? []
        ShortcutManager.migrateLegacyShortcut()
        launchesAtLogin = launchAtLoginManager.isEnabled
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
    }

    func resetShortcut() {
        KeyboardShortcuts.reset(.openMenu)
    }

    func setLaunchesAtLogin(_ enabled: Bool) {
        do {
            try launchAtLoginManager.setEnabled(enabled)
            launchesAtLogin = launchAtLoginManager.isEnabled
            launchAtLoginError = launchAtLoginManager.requiresApproval
                ? "Allow AnyIpsum in System Settings to launch it automatically."
                : nil
        } catch {
            launchesAtLogin = launchAtLoginManager.isEnabled
            launchAtLoginError = error.localizedDescription
        }
    }

    func copy(_ variation: Variation) {
        let paragraph = ParagraphGenerator.generate(from: variation.words)
        PasteboardWriter.copy(paragraph)
    }

    func importVariation(from url: URL, named name: String) {
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                throw VariationStoreError.emptyName
            }
            guard !variations.contains(where: {
                VariationStore.normalizedName($0.name) == VariationStore.normalizedName(trimmedName)
            }) else {
                throw VariationStoreError.duplicateName
            }

            try VariationStore.validateImportFileSize(url)
            let text = try String(contentsOf: url, encoding: .utf8)
            let words = VariationStore.uniqueWords(in: text)
            guard !words.isEmpty else {
                throw VariationStoreError.emptyWords
            }

            try VariationStore.add(Variation(name: trimmedName, words: words.joined(separator: " ")))
            variations = try VariationStore.load()
            variationError = nil
            statusItemController?.refreshMenu()
        } catch {
            variationError = error.localizedDescription
        }
    }

    func deleteVariation(_ variation: Variation) {
        do {
            try VariationStore.remove(variation)
            variations = try VariationStore.load()
            variationError = nil
            statusItemController?.refreshMenu()
        } catch {
            variationError = error.localizedDescription
        }
    }

    func reorderVariations(from source: IndexSet, to destination: Int) {
        var reorderedVariations = variations
        reorderedVariations.move(fromOffsets: source, toOffset: destination)

        do {
            try VariationStore.reorder(reorderedVariations)
            variations = reorderedVariations
            variationError = nil
            statusItemController?.refreshMenu()
        } catch {
            variationError = error.localizedDescription
        }
    }

}
