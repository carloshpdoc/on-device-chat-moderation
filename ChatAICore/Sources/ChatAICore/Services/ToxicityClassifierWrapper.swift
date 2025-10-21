
import Foundation

public protocol ToxicityScoring: Sendable {
    func score(text: String) throws -> [String: Double]
}

public struct FakeScorer: ToxicityScoring {
    private let fixed: [String: Double]
    public init(fixed: [String: Double] = ["toxicity": 0.05]) {
        self.fixed = fixed
    }
    public func score(text: String) throws -> [String : Double] {
        // exemplo simples: incrementa um pouco se tiver "gritar"
        var scores = fixed
        if text.lowercased().contains("gritar") {
            scores["toxicity"] = min(1.0, (scores["toxicity"] ?? 0.05) + 0.3)
        }
        return scores
    }
}

// Quando você tiver o modelo .mlmodel, crie um tipo que implemente ToxicityScoring
// e use no lugar do FakeScorer no DemoApp.
