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
}

private struct FixedRandomNumberGenerator: RandomNumberGenerator {
    mutating func next() -> UInt64 { 0 }
}

final class ShortcutManagerTests: XCTestCase {
    func testFailedUpdateRestoresPreviousShortcut() throws {
        let original = Shortcut.default
        let replacement = Shortcut(keyCode: 11, modifiers: original.modifiers, keyName: "B")
        var registrationAttempts: [Shortcut] = []
        var unregistrationCount = 0

        let manager = ShortcutManager(
            action: {},
            registerHotKey: { shortcut, reference in
                registrationAttempts.append(shortcut)
                if shortcut == replacement {
                    return OSStatus(-9878)
                }
                reference.pointee = OpaquePointer(bitPattern: registrationAttempts.count)
                return noErr
            },
            unregisterHotKey: { _ in
                unregistrationCount += 1
                return noErr
            }
        )

        try manager.update(original)
        XCTAssertThrowsError(try manager.update(replacement))
        XCTAssertEqual(registrationAttempts, [original, replacement, original])
        XCTAssertEqual(unregistrationCount, 1)

        try manager.update(original)
        XCTAssertEqual(registrationAttempts, [original, replacement, original])
        XCTAssertEqual(unregistrationCount, 1)
    }
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
