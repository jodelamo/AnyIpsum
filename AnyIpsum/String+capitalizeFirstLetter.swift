import Foundation

extension String {
    func capitalizeFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
}
