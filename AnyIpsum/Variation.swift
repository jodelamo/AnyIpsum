import Foundation

struct Variation: Codable, Identifiable, Hashable, Sendable {
    let name: String
    let words: String

    var id: String { name }
}

enum VariationStoreError: LocalizedError, Equatable {
    case emptyName
    case duplicateName
    case emptyWords
    case fileTooLarge

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Enter a name for the variation."
        case .duplicateName:
            return "A variation with that name already exists."
        case .emptyWords:
            return "The selected file does not contain any words."
        case .fileTooLarge:
            return "Imported text files must be 10 KB or smaller."
        }
    }
}

enum VariationStore {
    static let maxImportFileSize = 10 * 1024

    static func validateImportFileSize(_ url: URL) throws {
        let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard fileSize <= maxImportFileSize else {
            throw VariationStoreError.fileTooLarge
        }
    }

    static func load(
        bundle: Bundle = .main,
        storageURL: URL? = nil,
        fileManager: FileManager = .default
    ) throws -> [Variation] {
        let builtInVariations = try loadBuiltInVariations(bundle: bundle)
        let persisted = try loadPersistedVariations(
            bundle: bundle,
            storageURL: storageURL,
            fileManager: fileManager
        )
        let deletedNames = Set(persisted.deletedBuiltInNames.map(normalizedName))
        let availableBuiltIns = builtInVariations.filter {
            !deletedNames.contains(normalizedName($0.name))
        }

        return applyOrder(
            to: availableBuiltIns + persisted.customVariations,
            order: persisted.variationOrder
        )
    }

    static func add(
        _ variation: Variation,
        bundle: Bundle = .main,
        storageURL: URL? = nil,
        fileManager: FileManager = .default
    ) throws {
        let normalizedVariationName = normalizedName(variation.name)
        guard !normalizedVariationName.isEmpty else {
            throw VariationStoreError.emptyName
        }

        let existingVariations = try load(
            bundle: bundle,
            storageURL: storageURL,
            fileManager: fileManager
        )
        guard !existingVariations.contains(where: {
            normalizedName($0.name) == normalizedVariationName
        }) else {
            throw VariationStoreError.duplicateName
        }

        var persisted = try loadPersistedVariations(
            bundle: bundle,
            storageURL: storageURL,
            fileManager: fileManager
        )
        persisted.customVariations.append(variation)
        try savePersistedVariations(
            persisted,
            bundle: bundle,
            storageURL: storageURL,
            fileManager: fileManager
        )
    }

    static func remove(
        _ variation: Variation,
        bundle: Bundle = .main,
        storageURL: URL? = nil,
        fileManager: FileManager = .default
    ) throws {
        var persisted = try loadPersistedVariations(
            bundle: bundle,
            storageURL: storageURL,
            fileManager: fileManager
        )
        let normalizedVariationName = normalizedName(variation.name)

        if let customIndex = persisted.customVariations.firstIndex(where: {
            normalizedName($0.name) == normalizedVariationName
        }) {
            persisted.customVariations.remove(at: customIndex)
        } else {
            let builtInVariations = try loadBuiltInVariations(bundle: bundle)
            if builtInVariations.contains(where: {
                normalizedName($0.name) == normalizedVariationName
            }) {
                persisted.deletedBuiltInNames.append(variation.name)
            }
        }
        persisted.variationOrder.removeAll { $0 == normalizedVariationName }

        try savePersistedVariations(
            persisted,
            bundle: bundle,
            storageURL: storageURL,
            fileManager: fileManager
        )
    }

    static func reorder(
        _ variations: [Variation],
        bundle: Bundle = .main,
        storageURL: URL? = nil,
        fileManager: FileManager = .default
    ) throws {
        var persisted = try loadPersistedVariations(
            bundle: bundle,
            storageURL: storageURL,
            fileManager: fileManager
        )
        persisted.variationOrder = variations.map { normalizedName($0.name) }
        try savePersistedVariations(
            persisted,
            bundle: bundle,
            storageURL: storageURL,
            fileManager: fileManager
        )
    }

    static func uniqueWords(in text: String) -> [String] {
        var seen = Set<String>()

        return text.words.filter { word in
            seen.insert(word.lowercased()).inserted
        }
    }

    static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func loadBuiltInVariations(bundle: Bundle) throws -> [Variation] {
        guard let url = bundle.url(forResource: "Ipsum", withExtension: "plist") else {
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: url)
        let values = try PropertyListDecoder().decode([String: String].self, from: data)

        return values
            .compactMap { name, words in
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedWords = words.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty, !trimmedWords.isEmpty else { return nil }
                return Variation(name: trimmedName, words: trimmedWords)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func applyOrder(to variations: [Variation], order: [String]) -> [Variation] {
        guard !order.isEmpty else { return variations }

        let variationsByName = Dictionary(uniqueKeysWithValues: variations.map {
            (normalizedName($0.name), $0)
        })
        let orderedNames = order + variations.map { normalizedName($0.name) }

        var seen = Set<String>()
        return orderedNames.compactMap { name in
            guard seen.insert(name).inserted else { return nil }
            return variationsByName[name]
        }
    }

    private static func loadPersistedVariations(
        bundle: Bundle,
        storageURL: URL?,
        fileManager: FileManager
    ) throws -> PersistedVariations {
        let url = storageURL ?? defaultStorageURL(bundle: bundle, fileManager: fileManager)
        guard fileManager.fileExists(atPath: url.path) else {
            return PersistedVariations()
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(PersistedVariations.self, from: data)
    }

    private static func savePersistedVariations(
        _ persisted: PersistedVariations,
        bundle: Bundle,
        storageURL: URL?,
        fileManager: FileManager
    ) throws {
        let url = storageURL ?? defaultStorageURL(bundle: bundle, fileManager: fileManager)
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(persisted)
        try data.write(to: url, options: .atomic)
    }

    private static func defaultStorageURL(bundle: Bundle, fileManager: FileManager) -> URL {
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let applicationName = bundle.bundleIdentifier ?? "AnyIpsum"
        return applicationSupport
            .appendingPathComponent(applicationName, isDirectory: true)
            .appendingPathComponent("Variations.json")
    }

    private struct PersistedVariations: Codable {
        var customVariations: [Variation] = []
        var deletedBuiltInNames: [String] = []
        var variationOrder: [String] = []

        private enum CodingKeys: String, CodingKey {
            case customVariations
            case deletedBuiltInNames
            case variationOrder
        }

        init() {}

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            customVariations = try container.decodeIfPresent([Variation].self, forKey: .customVariations) ?? []
            deletedBuiltInNames = try container.decodeIfPresent([String].self, forKey: .deletedBuiltInNames) ?? []
            variationOrder = try container.decodeIfPresent([String].self, forKey: .variationOrder) ?? []
        }
    }
}
