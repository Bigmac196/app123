import Foundation
import SwiftSoup

/// SwiftSoup-backed per-platform selector fallback. Only used when the
/// dependency-free JSON-LD / OpenGraph path didn't already fill a field.
/// Pure local parsing — SwiftSoup makes no network calls.
struct SwiftSoupHTMLExtractor: HTMLExtracting {
    func selectorData(html: String, platform: Platform) -> SelectorExtraction {
        guard let doc = try? SwiftSoup.parse(html) else { return SelectorExtraction() }
        var sx = SelectorExtraction()

        switch platform {
        case .amazon:
            sx.title = try? doc.select("#productTitle").first()?.text()
            sx.priceText = (try? doc.select(".a-price .a-offscreen").first()?.text())
                ?? (try? doc.select("#priceblock_ourprice").first()?.text())
            sx.ratingText = try? doc.select("#acrPopover").first()?.attr("title")
            sx.reviewCountText = try? doc.select("#acrCustomerReviewText").first()?.text()
            sx.brand = try? doc.select("#bylineInfo").first()?.text()
            sx.bullets = (try? doc.select("#feature-bullets li").array()
                .compactMap { try? $0.text() }) ?? []
            sx.specs = parseSpecTable(doc, selector: "#productDetails_techSpec_section_1 tr")

        case .walmart, .target:
            // Next.js / redux apps embed JSON; grab the visible H1 + text as a hint.
            sx.title = try? doc.select("h1").first()?.text()
            sx.description = try? doc.select("[data-testid='product-description']")
                .first()?.text()

        default:
            sx.title = try? doc.select("h1").first()?.text()
            sx.bullets = (try? doc.select("ul li").array().prefix(12)
                .compactMap { try? $0.text() }
                .filter { $0.count > 15 && $0.count < 220 }) ?? []
        }

        if (sx.description ?? "").isEmpty {
            sx.description = try? doc.select("#productDescription").first()?.text()
        }
        return sx
    }

    private func parseSpecTable(_ doc: Document, selector: String) -> [String: String] {
        var specs: [String: String] = [:]
        guard let rows = try? doc.select(selector).array() else { return specs }
        for row in rows {
            if let k = try? row.select("th").first()?.text(),
               let v = try? row.select("td").first()?.text(),
               !k.isEmpty, !v.isEmpty {
                specs[k] = v
            }
        }
        return specs
    }
}
