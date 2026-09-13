import Foundation

enum ParagraphGenerator {
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

        var previousWord: String?

        return (0..<Int.random(in: sentenceCount, using: &random))
            .map { _ in
                let count = Int.random(in: wordsPerSentence, using: &random)
                let sentence = (0..<count)
                    .map { _ in
                        let randomWord = words.randomElement(using: &random)!
                        let word = randomWord.lowercased() == previousWord
                            ? words.first { $0.lowercased() != previousWord } ?? randomWord
                            : randomWord
                        previousWord = word.lowercased()
                        return word
                    }
                    .joined(separator: " ")
                    .lowercased()
                    .capitalizeFirstLetter()
                return sentence + "."
            }
            .joined(separator: " ")
    }

    static func generate(from source: String) -> String {
        var random = SystemRandomNumberGenerator()
        return generate(from: source, using: &random)
    }
}
