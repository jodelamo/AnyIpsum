import Foundation

extension String {
    var words: [String] {
        components(separatedBy: .punctuationCharacters)
            .joined(separator: "")
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
    }
}
