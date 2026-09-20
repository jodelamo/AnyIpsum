import XCTest
@testable import AnyIpsum

final class ParagraphGeneratorTests: XCTestCase {
    func testGeneratorHonorsSentenceAndWordBounds() {
        var random = FixedRandomNumberGenerator()
        let paragraph = ParagraphGenerator.generate(
            from: "alpha beta gamma delta",
            sentenceCount: 2...2,
            wordsPerSentence: 3...3,
            using: &random
        )

        let sentences = paragraph.split(separator: ".")
        XCTAssertEqual(sentences.count, 2)
        XCTAssertTrue(sentences.allSatisfy { $0.split(separator: " ").count == 3 })
        XCTAssertTrue(paragraph.hasSuffix("."))
    }

    func testGeneratorReturnsEmptyParagraphForEmptyInput() {
        var random = FixedRandomNumberGenerator()
        let paragraph = ParagraphGenerator.generate(from: " ", using: &random)

        XCTAssertEqual(paragraph, "")
    }

    func testGeneratorDoesNotRepeatAdjacentWords() {
        var random = FixedRandomNumberGenerator()
        let paragraph = ParagraphGenerator.generate(
            from: "alpha beta",
            sentenceCount: 2...2,
            wordsPerSentence: 3...3,
            using: &random
        )

        let words = paragraph
            .split { $0 == " " || $0 == "." }
            .map(String.init)

        XCTAssertFalse(zip(words, words.dropFirst()).contains { $0 == $1 })
    }

    func testGeneratorPreservesSourcePhrases() {
        var random = FixedRandomNumberGenerator()
        let paragraph = ParagraphGenerator.generate(
            from: "alpha beta gamma delta",
            sentenceCount: 1...1,
            wordsPerSentence: 3...3,
            using: &random
        )

        XCTAssertEqual(paragraph, "Alpha beta gamma.")
    }

    func testGeneratorAvoidsRecentWordsWhenAlternativesExist() {
        var random = FixedRandomNumberGenerator()
        let paragraph = ParagraphGenerator.generate(
            from: "alpha beta gamma delta epsilon zeta",
            sentenceCount: 1...1,
            wordsPerSentence: 6...6,
            using: &random
        )
        let words = paragraph
            .split { $0 == " " || $0 == "." }
            .map(String.init)

        XCTAssertEqual(Set(words.map { $0.lowercased() }).count, 6)
    }
}

final class StringExtensionTests: XCTestCase {
    func testWordsSplitPunctuationWithoutMergingWords() {
        XCTAssertEqual("hello,world".words, ["hello", "world"])
    }

    func testWordsSplitPunctuationAndWhitespace() {
        XCTAssertEqual("hello...\nworld".words, ["hello", "world"])
    }

    func testWordsReturnsEmptyForWhitespaceAndPunctuation() {
        XCTAssertEqual("!?\n  \t".words, [])
    }

    func testCapitalizeFirstLetterHandlesUnicodeAndEmptyStrings() {
        XCTAssertEqual("éclair".capitalizeFirstLetter(), "Éclair")
        XCTAssertEqual("".capitalizeFirstLetter(), "")
    }
}

final class CopyNotificationManagerTests: XCTestCase {
    func testMessageReportsPluralWordCount() {
        XCTAssertEqual(CopyNotificationManager.message(wordCount: 42), "Copied 42 words")
    }

    func testMessageUsesSingularForOneWord() {
        XCTAssertEqual(CopyNotificationManager.message(wordCount: 1), "Copied 1 word")
    }
}

private struct FixedRandomNumberGenerator: RandomNumberGenerator {
    mutating func next() -> UInt64 { 0 }
}

final class VariationStoreTests: XCTestCase {
    private var temporaryURLs: [URL] = []

    override func tearDown() {
        for url in temporaryURLs {
            try? FileManager.default.removeItem(at: url)
        }
        temporaryURLs.removeAll()
        super.tearDown()
    }

    func testUniqueWordsIgnoresCaseAndPreservesFirstSpelling() {
        let words = VariationStore.uniqueWords(in: "Cat cat DOG dog kitten")

        XCTAssertEqual(words, ["Cat", "DOG", "kitten"])
    }

    func testUniqueWordsReturnsEmptyForPunctuationAndWhitespace() {
        let words = VariationStore.uniqueWords(in: "!?\n  \t")

        XCTAssertTrue(words.isEmpty)
    }

    func testCustomVariationsAndBuiltInDeletionsPersist() throws {
        let bundle = try makeBundle(with: ["Built In": "alpha beta"])
        let storageURL = makeTemporaryURL().appendingPathComponent("Variations.json")
        let builtIn = Variation(name: "Built In", words: "alpha beta")
        let custom = Variation(name: "Cat Ipsum", words: "cat kitten")

        XCTAssertEqual(
            try VariationStore.load(bundle: bundle, storageURL: storageURL),
            [builtIn]
        )

        try VariationStore.add(custom, bundle: bundle, storageURL: storageURL)
        try VariationStore.remove(builtIn, bundle: bundle, storageURL: storageURL)

        XCTAssertEqual(
            try VariationStore.load(bundle: bundle, storageURL: storageURL),
            [custom]
        )
    }

    func testLoremIpsumIsTheFirstDefaultVariation() throws {
        let bundle = try makeBundle(with: [
            "Bacon Ipsum": "bacon words",
            "Cat Ipsum": "cat words",
            "Cupcake Ipsum": "cupcake words",
            "Lorem Ipsum": "lorem words",
            "Pirate Ipsum": "pirate words"
        ])
        let storageURL = makeTemporaryURL().appendingPathComponent("Variations.json")

        XCTAssertEqual(
            try VariationStore.load(bundle: bundle, storageURL: storageURL).map(\.name),
            ["Lorem Ipsum", "Bacon Ipsum", "Cat Ipsum", "Cupcake Ipsum", "Pirate Ipsum"]
        )
    }

    func testAddingVariationWithDuplicateNameIsRejected() throws {
        let bundle = try makeBundle(with: ["Built In": "alpha beta"])
        let storageURL = makeTemporaryURL().appendingPathComponent("Variations.json")

        XCTAssertThrowsError(
            try VariationStore.add(
                Variation(name: "built in", words: "different words"),
                bundle: bundle,
                storageURL: storageURL
            )
        ) { error in
            XCTAssertEqual(error as? VariationStoreError, .duplicateName)
        }
    }

    func testImportFileSizeLimitAllows10KBAndRejectsLargerFiles() throws {
        let allowedURL = makeTemporaryURL()
        try Data(repeating: 0x61, count: VariationStore.maxImportFileSize).write(to: allowedURL)
        XCTAssertNoThrow(try VariationStore.validateImportFileSize(allowedURL))

        let oversizedURL = makeTemporaryURL()
        try Data(repeating: 0x61, count: VariationStore.maxImportFileSize + 1).write(to: oversizedURL)
        XCTAssertThrowsError(try VariationStore.validateImportFileSize(oversizedURL)) { error in
            XCTAssertEqual(error as? VariationStoreError, .fileTooLarge)
        }
    }

    func testVariationOrderPersistsAcrossReloads() throws {
        let bundle = try makeBundle(with: [
            "First": "alpha beta",
            "Second": "gamma delta"
        ])
        let storageURL = makeTemporaryURL().appendingPathComponent("Variations.json")
        let first = Variation(name: "First", words: "alpha beta")
        let second = Variation(name: "Second", words: "gamma delta")

        try VariationStore.reorder(
            [second, first],
            bundle: bundle,
            storageURL: storageURL
        )

        XCTAssertEqual(
            try VariationStore.load(bundle: bundle, storageURL: storageURL),
            [second, first]
        )
    }

    private func makeBundle(with variations: [String: String]) throws -> Bundle {
        let bundleURL = makeTemporaryURL().appendingPathExtension("bundle")
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let data = try PropertyListSerialization.data(
            fromPropertyList: variations,
            format: .xml,
            options: 0
        )
        try data.write(to: bundleURL.appendingPathComponent("Ipsum.plist"))
        return try XCTUnwrap(Bundle(url: bundleURL))
    }

    private func makeTemporaryURL() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        temporaryURLs.append(url)
        return url
    }
}
