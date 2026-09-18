import Foundation

extension String {
    var words: [String] {
        split { $0.isWhitespace || $0.isPunctuation }
            .map(String.init)
    }
}
