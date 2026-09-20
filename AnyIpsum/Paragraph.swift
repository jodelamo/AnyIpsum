import Foundation

struct ParagraphConfiguration: Equatable {
    static let sentenceCountLimits = 1...100
    static let wordsPerSentenceLimits = 1...100
    static let defaultSentenceCount = 5...7
    static let defaultWordsPerSentence = 4...8

    private static let minimumSentenceCountKey = "minimumSentenceCount"
    private static let maximumSentenceCountKey = "maximumSentenceCount"
    private static let minimumWordsPerSentenceKey = "minimumWordsPerSentence"
    private static let maximumWordsPerSentenceKey = "maximumWordsPerSentence"

    let sentenceCount: ClosedRange<Int>
    let wordsPerSentence: ClosedRange<Int>

    init(
        sentenceCount: ClosedRange<Int> = defaultSentenceCount,
        wordsPerSentence: ClosedRange<Int> = defaultWordsPerSentence
    ) {
        self.sentenceCount = Self.clamp(sentenceCount, to: Self.sentenceCountLimits)
        self.wordsPerSentence = Self.clamp(
            wordsPerSentence,
            to: Self.wordsPerSentenceLimits
        )
    }

    init(defaults: UserDefaults) {
        self.init(
            sentenceCount: Self.range(
                from: defaults,
                minimumKey: Self.minimumSentenceCountKey,
                maximumKey: Self.maximumSentenceCountKey,
                fallback: Self.defaultSentenceCount
            ),
            wordsPerSentence: Self.range(
                from: defaults,
                minimumKey: Self.minimumWordsPerSentenceKey,
                maximumKey: Self.maximumWordsPerSentenceKey,
                fallback: Self.defaultWordsPerSentence
            )
        )
    }

    func save(to defaults: UserDefaults) {
        defaults.set(sentenceCount.lowerBound, forKey: Self.minimumSentenceCountKey)
        defaults.set(sentenceCount.upperBound, forKey: Self.maximumSentenceCountKey)
        defaults.set(wordsPerSentence.lowerBound, forKey: Self.minimumWordsPerSentenceKey)
        defaults.set(wordsPerSentence.upperBound, forKey: Self.maximumWordsPerSentenceKey)
    }

    private static func range(
        from defaults: UserDefaults,
        minimumKey: String,
        maximumKey: String,
        fallback: ClosedRange<Int>
    ) -> ClosedRange<Int> {
        guard defaults.object(forKey: minimumKey) != nil,
              defaults.object(forKey: maximumKey) != nil else {
            return fallback
        }

        let minimum = defaults.integer(forKey: minimumKey)
        let maximum = defaults.integer(forKey: maximumKey)
        return minimum <= maximum ? minimum...maximum : fallback
    }

    private static func clamp(
        _ range: ClosedRange<Int>,
        to limits: ClosedRange<Int>
    ) -> ClosedRange<Int> {
        let minimum = min(max(range.lowerBound, limits.lowerBound), limits.upperBound)
        let maximum = min(max(range.upperBound, minimum), limits.upperBound)
        return minimum...maximum
    }
}

enum ParagraphGenerator {
    private static let maxPhraseLength = 3
    private static let recentWordLimit = 5

    static func generate(
        from source: String,
        sentenceCount: ClosedRange<Int> = 5...7,
        wordsPerSentence: ClosedRange<Int> = 4...8,
        using random: inout some RandomNumberGenerator
    ) -> String {
        let words = source.words
        guard !words.isEmpty, !sentenceCount.isEmpty, !wordsPerSentence.isEmpty else {
            return ""
        }

        var recentWords: [String] = []

        return (0..<Int.random(in: sentenceCount, using: &random))
            .map { _ in
                let count = Int.random(in: wordsPerSentence, using: &random)
                var sentenceWords: [String] = []

                while sentenceWords.count < count {
                    let remainingWords = count - sentenceWords.count
                    let phraseLength = min(maxPhraseLength, remainingWords)
                    let candidates = phraseCandidates(
                        from: words,
                        length: phraseLength,
                        excluding: recentWords,
                        after: sentenceWords.last
                    )
                    let fallbackCandidates = candidates.isEmpty
                        ? phraseCandidates(
                            from: words,
                            length: phraseLength,
                            excluding: [],
                            after: sentenceWords.last
                        )
                        : candidates
                    let phrase = fallbackCandidates.randomElement(using: &random)
                        ?? (words.count >= phraseLength
                            ? Array(words.prefix(phraseLength))
                            : [words[0]])

                    sentenceWords.append(contentsOf: phrase)
                    for word in phrase {
                        recentWords.append(word.lowercased())
                    }
                    if recentWords.count > recentWordLimit {
                        recentWords.removeFirst(recentWords.count - recentWordLimit)
                    }

                }

                let sentence = sentenceWords
                    .joined(separator: " ")
                    .lowercased()
                    .capitalizeFirstLetter()
                return sentence + "."
            }
            .joined(separator: " ")
    }

    private static func phraseCandidates(
        from words: [String],
        length: Int,
        excluding recentWords: [String],
        after previousWord: String?
    ) -> [[String]] {
        guard length > 0, words.count >= length else { return [] }

        let recentWordSet = Set(recentWords)
        return (0...(words.count - length)).compactMap { start in
            let phrase = Array(words[start..<(start + length)])
            let normalizedPhrase = phrase.map { $0.lowercased() }
            guard normalizedPhrase.allSatisfy({ !recentWordSet.contains($0) }) else { return nil }
            guard normalizedPhrase.first != previousWord?.lowercased() else { return nil }
            guard !zip(normalizedPhrase, normalizedPhrase.dropFirst()).contains(where: ==) else {
                return nil
            }
            return phrase
        }
    }

    static func generate(from source: String) -> String {
        var random = SystemRandomNumberGenerator()
        return generate(from: source, using: &random)
    }
}
