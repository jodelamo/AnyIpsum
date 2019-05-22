import Foundation

extension String {
    var words: [String] {
        get {
            return components(separatedBy: .punctuationCharacters)
                .joined(separator: "")
                .components(separatedBy: " ")
                .filter { !$0.isEmpty }
        }
    }
}
