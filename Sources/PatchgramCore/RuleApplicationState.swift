import Foundation

public enum RuleApplicationState: String, Codable, Sendable {
    case applied
    case notApplied
    case partial
    case unavailable

    public var isEnabled: Bool {
        self == .applied || self == .partial
    }
}
