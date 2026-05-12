import Foundation

public extension String {
    // Trim leading whitespace/newlines (compat for existing calls)
    func trimmingLeading() -> String {
        trimmingLeadingCharacters(in: .whitespacesAndNewlines)
    }

    func trimmingLeadingCharacters(in set: CharacterSet) -> String {
        guard let range = rangeOfCharacter(from: set.inverted) else { return "" }
        return String(self[range.lowerBound...])
    }

    func trimmingTrailingCharacters(in set: CharacterSet = .whitespacesAndNewlines) -> String {
        guard let range = rangeOfCharacter(from: set.inverted, options: .backwards) else { return "" }
        return String(self[..<range.upperBound])
    }
}
