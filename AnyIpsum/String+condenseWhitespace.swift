import Foundation

extension String {
    func condenseWhitespace() -> String {
        let components = self.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return components
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
