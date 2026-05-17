import XCTest
@testable import WorthItKit

final class ClassifierAndScoringTests: XCTestCase {
    private let coordinator = AnalysisCoordinator()

    private func product(_ title: String, desc: String = "",
                         price: Decimal? = nil, rating: Double? = nil,
                         reviews: Int? = nil, list: Decimal? = nil) -> ProductData {
        ProductData(sourceURL: URL(string: "https://amazon.com/x")!,
            platform: .amazon, title: title, price: price, currency: "USD",
            listPrice: list, rating: rating, reviewCount: reviews,
            productDescription: desc)
    }

    func testClassifierFragrance() {
        let c = CategoryClassifier().classify(
            product("Versace Eros Eau de Toilette Spray for Men 100ml",
                    desc: "fragrance with notes of mint and vanilla"))
        XCTAssertEqual(c.category, .fragrance)
        XCTAssertGreaterThan(c.confidence, 0.4)
    }

    func testClassifierFallsBackToGeneral() {
        let c = CategoryClassifier().classify(product("Random plastic widget"))
        XCTAssertEqual(c.category, .general)
    }

    func testClassifierNegativeKeywordDisambiguation() {
        let c = CategoryClassifier().classify(
            product("Desk Lamp LED Organizer", desc: "desk lamp desk pad organizer"))
        XCTAssertNotEqual(c.category, .standingDesk)
    }

    func testSuspiciousVerdictOnFakeReviewSignal() {
        let out = coordinator.analyze(product:
            product("Standing Desk Electric Adjustable",
                    desc: "single motor sit-stand desk",
                    price: 89.99, rating: 4.9, reviews: 7, list: 899.99))
        XCTAssertEqual(out.breakdown.verdict, .suspicious)
    }

    func testStrongProductScoresWell() {
        let out = coordinator.analyze(product:
            product("Creed Aventus Eau de Parfum 100ml",
                    desc: String(repeating: "Eau de parfum with notes of bergamot, oakmoss, musk, amber and vanilla. ", count: 8),
                    price: 295, rating: 4.6, reviews: 2841))
        XCTAssertEqual(out.category, .fragrance)
        XCTAssertGreaterThan(out.breakdown.score, 55)
        XCTAssertTrue([.worthIt, .greatValue].contains(out.breakdown.verdict))
        XCTAssertFalse(out.analyzer.metrics.isEmpty)
    }

    func testLowQualityProductScoresPoorly() {
        let out = coordinator.analyze(product:
            product("Cheap thing", desc: "x", price: 5, rating: 2.6, reviews: 400))
        XCTAssertLessThan(out.breakdown.score, 45)
        XCTAssertTrue([.junk, .overpriced].contains(out.breakdown.verdict))
    }

    func testConfidenceInRange() {
        let out = coordinator.analyze(product:
            product("Sony WH-1000XM5 Headphones",
                    desc: "hybrid ANC, LDAC, 30 hours battery, memory foam",
                    price: 348, rating: 4.7, reviews: 12000))
        XCTAssertGreaterThanOrEqual(out.breakdown.confidence, 0)
        XCTAssertLessThanOrEqual(out.breakdown.confidence, 1)
        XCTAssertEqual(out.category, .headphones)
    }
}
