import Foundation

struct Variation: Identifiable, Hashable, Sendable {
    let name: String
    let words: String

    var id: String { name }
}

enum VariationStore {
    static func load(bundle: Bundle = .main) throws -> [Variation] {
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
}
