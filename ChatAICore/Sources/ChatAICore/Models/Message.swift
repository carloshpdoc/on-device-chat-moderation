
import Foundation

public struct Message: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let text: String
    public let isUser: Bool
    public let createdAt: Date

    public init(id: UUID = UUID(), text: String, isUser: Bool, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.createdAt = createdAt
    }
}
