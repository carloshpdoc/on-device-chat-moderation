
import Foundation

public final class RuleEngine: @unchecked Sendable {
    private let policy: ModerationPolicy
    private let regexes: [NSRegularExpression]

    public init(policy: ModerationPolicy) {
        self.policy = policy
        self.regexes = policy.blockedRegex.compactMap {
            try? NSRegularExpression(pattern: $0, options: [])
        }
    }

    public func quickCheck(_ text: String) -> ModerationVerdict? {
        if text.count > policy.maxLength {
            return ModerationVerdict(status: .blocked(reason: "Mensagem excede \(policy.maxLength) caracteres."), scores: [:])
        }
        let lower = text.lowercased()

        if policy.blockedKeywords.contains(where: { lower.contains($0.lowercased()) }) {
            return ModerationVerdict(status: .blocked(reason: "Contém palavra bloqueada pela política."), scores: [:])
        }

        if policy.blockedDomains.contains(where: { lower.contains($0.lowercased()) }) {
            return ModerationVerdict(status: .blocked(reason: "Link para domínio proibido."), scores: [:])
        }

        for rx in regexes {
            let range = NSRange(lower.startIndex..<lower.endIndex, in: lower)
            if rx.firstMatch(in: lower, options: [], range: range) != nil {
                return ModerationVerdict(status: .blocked(reason: "Padrão proibido detectado."), scores: [:])
            }
        }
        return nil
    }
}
