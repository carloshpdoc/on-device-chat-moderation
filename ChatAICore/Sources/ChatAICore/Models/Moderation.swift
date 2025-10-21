
import Foundation

public struct ModerationVerdict: Sendable {
    public enum Status: Sendable {
        case allowed
        case blocked(reason: String)
    }
    public let status: Status
    public let scores: [String: Double]

    public init(status: Status, scores: [String: Double]) {
        self.status = status
        self.scores = scores
    }
}

public struct ModerationPolicy: Decodable, Sendable {
    public let blockedKeywords: [String]
    public let blockedRegex: [String]
    public let blockedDomains: [String]
    public let maxLength: Int
    public let minToxicity: Double
    public let categoriesThresholds: [String: Double]
}
