import XCTest
@testable import HypeCheckKit

final class AnalyzerTests: XCTestCase {
    private func p(_ title: String, _ desc: String,
                   price: Decimal? = nil) -> ProductData {
        ProductData(sourceURL: URL(string: "https://x.com")!,
            title: title, price: price, productDescription: desc)
    }

    func testFragranceConcentrationDrivesLongevity() {
        let r = FragranceAnalyzer().analyze(
            p("Parfum", "extrait de parfum, notes of oud, amber, musk"))
        let longevity = r.metrics.first { $0.label == "Longevity" }
        XCTAssertEqual(longevity?.value.contains("Very long"), true)
        XCTAssertGreaterThan(r.confidence, 0.4)
        XCTAssertGreaterThan(r.categoryScoreDelta, 0)
    }

    func testDeskDualMotorRaisesStability() {
        let r = DeskAnalyzer().analyze(
            p("Standing Desk", "dual motor steel frame 350 lb capacity 7 year warranty"))
        XCTAssertEqual(r.metrics.first { $0.label == "Stability" }?.value, "High")
        XCTAssertGreaterThan(r.categoryScoreDelta, 0.2)
    }

    func testPowerBankInflatedCapacityFlagged() {
        let r = PowerBankAnalyzer().analyze(
            p("Power Bank", "900000mAh portable charger super huge"))
        XCTAssertTrue(r.metrics.contains { $0.value.contains("Implausibly high") })
        XCTAssertLessThan(r.categoryScoreDelta, 0)
    }

    func testSkincareIrritationRisk() {
        let r = SkincareAnalyzer().analyze(
            p("Serum", "contains retinol, fragrance, denatured alcohol", price: 12))
        let risk = r.metrics.first { $0.label == "Irritation Risk" }
        XCTAssertEqual(risk?.rating, .warning)
    }

    func testSupplementProprietaryBlendPenalized() {
        let r = SupplementAnalyzer().analyze(
            p("Fat Burner", "proprietary blend, miracle detox, clinically proven, burn fat"))
        XCTAssertLessThan(r.categoryScoreDelta, 0)
        XCTAssertTrue(r.explanations.contains { $0.lowercased().contains("medical") })
    }

    func testGenericAnalyzerAlwaysReturnsResult() {
        let r = GenericAnalyzer().analyze(
            p("Unknown item", "some text", price: 20))
        XCTAssertEqual(r.category, .general)
        XCTAssertFalse(r.explanations.isEmpty)
    }
}
