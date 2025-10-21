
import Foundation
import Combine

public final class ChatViewModel: ObservableObject {
    @Published public var input: String = ""
    @Published public var messages: [Message] = []
    @Published public var lastModerationReason: String? = nil

    private let moderation: ModerationServiceType

    public init(moderation: ModerationServiceType) {
        self.moderation = moderation
        self.messages = [Message(text: "Oi! Eu sou o Chat com moderação on-device. 😊", isUser: false)]
    }

    public func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let verdict = moderation.evaluate(text)
        switch verdict.status {
        case .allowed:
            messages.append(Message(text: text, isUser: true))
            input = ""
            lastModerationReason = nil

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self else { return }
                let scoresText = verdict.scores.map { "\($0.key)=\(String(format: "%.2f", $0.value))" }.joined(separator: ", ")
                self.messages.append(Message(text: "Entendi! (scores: \(scoresText))", isUser: false))
            }
        case .blocked(let reason):
            lastModerationReason = reason
        }
    }
}
