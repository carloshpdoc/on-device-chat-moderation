
import Foundation

public protocol ModerationServiceType: Sendable {
    func evaluate(_ text: String) -> ModerationVerdict
}

public final class ModerationService: @unchecked Sendable, ModerationServiceType {
    private let policy: ModerationPolicy
    private let rules: RuleEngine
    private let scorer: ToxicityScoring

    public init(policy: ModerationPolicy, scorer: ToxicityScoring) {
        self.policy = policy
        self.rules = RuleEngine(policy: policy)
        self.scorer = scorer
    }

    public static func loadPolicy() -> ModerationPolicy {
        let url = Bundle.module.url(forResource: "ModerationPolicy", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(ModerationPolicy.self, from: data)
    }

    public func evaluate(_ text: String) -> ModerationVerdict {
        if let quick = rules.quickCheck(text) { return quick }

        do {
            let scores = try scorer.score(text: text)
            if let tox = scores["toxicity"], tox >= policy.minToxicity {
                return ModerationVerdict(status: .blocked(reason: "Toxicidade alta (\(Int(tox*100))%)."), scores: scores)
            }
            for (cat, thr) in policy.categoriesThresholds {
                if let s = scores[cat], s >= thr {
                    return ModerationVerdict(status: .blocked(reason: "Categoria \(cat) acima do limite (\(Int(s*100))%)."), scores: scores)
                }
            }
            return ModerationVerdict(status: .allowed, scores: scores)
        } catch {
            return ModerationVerdict(status: .blocked(reason: "Falha na avaliação local."), scores: [:])
        }
    }
}
