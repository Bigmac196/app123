import XCTest
@testable import HypeCheckKit

final class ProductParserTests: XCTestCase {
    private func fixture(_ name: String) throws -> String {
        let url = Bundle.module.url(forResource: name,
            withExtension: "html", subdirectory: "Fixtures")
        let path = try XCTUnwrap(url)
        return try String(contentsOf: path, encoding: .utf8)
    }

    func testJSONLDExtraction() throws {
        let html = try fixture("fragrance_jsonld")
        let url = URL(string: "https://www.amazon.com/dp/B000")!
        let p = ProductParser().parse(html: html, url: url)

        XCTAssertEqual(p.title, "Aventus Eau de Parfum 100ml")
        XCTAssertEqual(p.brand, "Creed")
        XCTAssertEqual(p.price, Decimal(string: "295.00"))
        XCTAssertEqual(p.currency, "USD")
        XCTAssertEqual(p.rating, 4.6)
        XCTAssertEqual(p.reviewCount, 2841)
        XCTAssertEqual(p.platform, .amazon)
        XCTAssertTrue(p.productDescription.lowercased().contains("oakmoss"))
        XCTAssertEqual(ParseQuality(product: p), .rich)
    }

    func testOpenGraphAndMicrodataFallback() throws {
        let html = try fixture("suspicious_desk")
        let url = URL(string: "https://example-store.com/desk")!
        let p = ProductParser().parse(html: html, url: url)

        XCTAssertEqual(p.price, Decimal(string: "89.99"))
        XCTAssertEqual(p.rating, 4.9)
        XCTAssertEqual(p.reviewCount, 7)
        XCTAssertFalse(p.title.isEmpty)
    }

    func testDecimalNormalization() {
        XCTAssertEqual(ProductParser.decimalFromText("$1,299.99"),
                       Decimal(string: "1299.99"))
        XCTAssertEqual(ProductParser.decimalFromText("€19,90"),
                       Decimal(string: "19.90"))
        XCTAssertEqual(ProductParser.decimalFromText("Price: 49"),
                       Decimal(string: "49"))
    }
}
