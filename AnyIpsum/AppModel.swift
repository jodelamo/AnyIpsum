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
    private(set) var sentenceCount: ClosedRange<Int>
    private(set) var wordsPerSentence: ClosedRange<Int>

    @ObservationIgnored private var shortcutManager: ShortcutManager?
    @ObservationIgnored private var statusItemController: StatusItemController?
    @ObservationIgnored private let launchAtLoginManager = LaunchAtLoginManager()
    @ObservationIgnored private let copyNotificationManager = CopyNotificationManager()
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        let paragraphConfiguration = ParagraphConfiguration(defaults: defaults)

        self.defaults = defaults
        variations = (try? VariationStore.load()) ?? []
        sentenceCount = paragraphConfiguration.sentenceCount
        wordsPerSentence = paragraphConfiguration.wordsPerSentence
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

    func setMinimumSentenceCount(_ count: Int) {
        let minimum = min(
            max(count, ParagraphConfiguration.sentenceCountLimits.lowerBound),
            sentenceCount.upperBound
        )
        sentenceCount = minimum...sentenceCount.upperBound
        saveParagraphConfiguration()
    }

    func setMaximumSentenceCount(_ count: Int) {
        let maximum = min(
            max(count, sentenceCount.lowerBound),
            ParagraphConfiguration.sentenceCountLimits.upperBound
        )
        sentenceCount = sentenceCount.lowerBound...maximum
        saveParagraphConfiguration()
    }

    func setMinimumWordsPerSentence(_ count: Int) {
        let minimum = min(
            max(count, ParagraphConfiguration.wordsPerSentenceLimits.lowerBound),
            wordsPerSentence.upperBound
        )
        wordsPerSentence = minimum...wordsPerSentence.upperBound
        saveParagraphConfiguration()
    }

    func setMaximumWordsPerSentence(_ count: Int) {
        let maximum = min(
            max(count, wordsPerSentence.lowerBound),
            ParagraphConfiguration.wordsPerSentenceLimits.upperBound
        )
        wordsPerSentence = wordsPerSentence.lowerBound...maximum
        saveParagraphConfiguration()
    }

    func copy(_ variation: Variation) {
        var random = SystemRandomNumberGenerator()
        let paragraph = ParagraphGenerator.generate(
            from: variation.words,
            sentenceCount: sentenceCount,
            wordsPerSentence: wordsPerSentence,
            using: &random
        )
        guard PasteboardWriter.copy(paragraph) else { return }

        copyNotificationManager.notifyCopied(wordCount: paragraph.words.count)
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

    private func saveParagraphConfiguration() {
        ParagraphConfiguration(
            sentenceCount: sentenceCount,
            wordsPerSentence: wordsPerSentence
        ).save(to: defaults)
    }
}
