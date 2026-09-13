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
