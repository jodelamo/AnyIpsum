import Foundation

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
