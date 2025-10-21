import XCTest
@testable import ChatAICore

final class ChatAICoreTests: XCTestCase {

    // MARK: - Message Tests

    func testMessageCreation() {
        let message = Message(text: "Hello", isUser: true)
        XCTAssertEqual(message.text, "Hello")
        XCTAssertTrue(message.isUser)
    }

    // MARK: - RuleEngine Tests

    func testRuleEngineBlocksLongMessages() {
        let policy = ModerationPolicy(
            blockedKeywords: [],
            blockedRegex: [],
            blockedDomains: [],
            maxLength: 10,
            minToxicity: 0.8,
            categoriesThresholds: [:]
        )
        let engine = RuleEngine(policy: policy)

        let verdict = engine.quickCheck("This is a very long message that exceeds the limit")
        XCTAssertNotNil(verdict)

        if case .blocked(let reason) = verdict?.status {
            XCTAssertTrue(reason.contains("excede"))
        } else {
            XCTFail("Expected blocked verdict")
        }
    }

    func testRuleEngineBlocksKeywords() {
        let policy = ModerationPolicy(
            blockedKeywords: ["spam", "ofensa"],
            blockedRegex: [],
            blockedDomains: [],
            maxLength: 2000,
            minToxicity: 0.8,
            categoriesThresholds: [:]
        )
        let engine = RuleEngine(policy: policy)

        let verdict = engine.quickCheck("Esta mensagem contém SPAM")
        XCTAssertNotNil(verdict)

        if case .blocked(let reason) = verdict?.status {
            XCTAssertTrue(reason.contains("palavra bloqueada"))
        } else {
            XCTFail("Expected blocked verdict")
        }
    }

    func testRuleEngineBlocksDomains() {
        let policy = ModerationPolicy(
            blockedKeywords: [],
            blockedRegex: [],
            blockedDomains: ["spam.com", "phishing.net"],
            maxLength: 2000,
            minToxicity: 0.8,
            categoriesThresholds: [:]
        )
        let engine = RuleEngine(policy: policy)

        let verdict = engine.quickCheck("Visite https://spam.com para mais")
        XCTAssertNotNil(verdict)

        if case .blocked(let reason) = verdict?.status {
            XCTAssertTrue(reason.contains("domínio proibido"))
        } else {
            XCTFail("Expected blocked verdict")
        }
    }

    func testRuleEngineAllowsCleanMessages() {
        let policy = ModerationPolicy(
            blockedKeywords: ["spam"],
            blockedRegex: [],
            blockedDomains: [],
            maxLength: 2000,
            minToxicity: 0.8,
            categoriesThresholds: [:]
        )
        let engine = RuleEngine(policy: policy)

        let verdict = engine.quickCheck("Olá, tudo bem?")
        XCTAssertNil(verdict)
    }

    // MARK: - FakeScorer Tests

    func testFakeScorerReturnsScores() throws {
        let scorer = FakeScorer()
        let scores = try scorer.score(text: "teste")

        XCTAssertNotNil(scores["toxicity"])
        XCTAssertEqual(scores["toxicity"], 0.05)
    }

    func testFakeScorerDetectsGritar() throws {
        let scorer = FakeScorer()
        let scores = try scorer.score(text: "vou gritar com você!")

        XCTAssertNotNil(scores["toxicity"])
        XCTAssertGreaterThan(scores["toxicity"]!, 0.05)
    }

    // MARK: - ModerationService Tests

    func testModerationServiceBlocksToxicContent() {
        let policy = ModerationPolicy(
            blockedKeywords: [],
            blockedRegex: [],
            blockedDomains: [],
            maxLength: 2000,
            minToxicity: 0.3,
            categoriesThresholds: [:]
        )
        let scorer = FakeScorer(fixed: ["toxicity": 0.9])
        let service = ModerationService(policy: policy, scorer: scorer)

        let verdict = service.evaluate("conteúdo tóxico")

        if case .blocked(let reason) = verdict.status {
            XCTAssertTrue(reason.contains("Toxicidade alta"))
        } else {
            XCTFail("Expected blocked verdict for toxic content")
        }
    }

    func testModerationServiceAllowsCleanContent() {
        let policy = ModerationPolicy(
            blockedKeywords: [],
            blockedRegex: [],
            blockedDomains: [],
            maxLength: 2000,
            minToxicity: 0.8,
            categoriesThresholds: [:]
        )
        let scorer = FakeScorer(fixed: ["toxicity": 0.05])
        let service = ModerationService(policy: policy, scorer: scorer)

        let verdict = service.evaluate("mensagem limpa")

        if case .allowed = verdict.status {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected allowed verdict for clean content")
        }
    }
}
