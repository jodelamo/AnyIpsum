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
