import Foundation

/// Optional hook for richer DOM/selector extraction (e.g. a SwiftSoup-backed
/// implementation in the iOS app). The Foundation-only parser already handles
/// JSON-LD / OpenGraph / microdata; an extractor can add per-platform CSS
/// selector fallbacks. Returning `nil` fields means "no opinion".
public protocol HTMLExtracting: Sendable {
    func selectorData(html: String, platform: Platform) -> SelectorExtraction
}

public struct SelectorExtraction: Sendable {
    public var title: String?
    public var brand: String?
    public var priceText: String?
    public var ratingText: String?
    public var reviewCountText: String?
    public var bullets: [String]
    public var specs: [String: String]
    public var description: String?
    public init(title: String? = nil, brand: String? = nil, priceText: String? = nil,
                ratingText: String? = nil, reviewCountText: String? = nil,
                bullets: [String] = [], specs: [String: String] = [:],
                description: String? = nil) {
        self.title = title; self.brand = brand; self.priceText = priceText
        self.ratingText = ratingText; self.reviewCountText = reviewCountText
        self.bullets = bullets; self.specs = specs; self.description = description
    }
}

/// Layered, dependency-free product extractor.
/// Order: JSON-LD → OpenGraph/Twitter meta → microdata → injected selector
/// extractor → shared page text from the share extension.
public struct ProductParser: Sendable {
    private let extractor: (any HTMLExtracting)?

    public init(extractor: (any HTMLExtracting)? = nil) {
        self.extractor = extractor
    }

    public func parse(html: String,
                      url: URL,
                      sharedPageText: String? = nil) -> ProductData {
        let platform = Platform(host: url.host)
        var p = ProductData(sourceURL: url, platform: platform)

        // 1. JSON-LD ----------------------------------------------------
        if let ld = Self.jsonLDProduct(in: html) {
            p.title = (ld["name"] as? String)?.cleaned ?? p.title
            if let brand = ld["brand"] {
                p.brand = ((brand as? [String: Any])?["name"] as? String)
                    ?? (brand as? String)
            }
            if let offers = Self.firstOffer(ld) {
                p.price = Self.decimal(offers["price"])
                p.currency = offers["priceCurrency"] as? String
            }
            if let agg = ld["aggregateRating"] as? [String: Any] {
                p.rating = Self.double(agg["ratingValue"])
                p.reviewCount = Self.int(agg["reviewCount"] ?? agg["ratingCount"])
            }
            if let desc = ld["description"] as? String { p.productDescription = desc.cleaned }
            if let img = ld["image"] as? String, let u = URL(string: img) { p.imageURLs = [u] }
            if let imgs = ld["image"] as? [String] {
                p.imageURLs = imgs.compactMap(URL.init(string:))
            }
        }

        // 2. OpenGraph / Twitter meta -----------------------------------
        if p.title.isEmpty { p.title = Self.meta(html, "og:title") ?? "" }
        if p.productDescription.isEmpty {
            p.productDescription = Self.meta(html, "og:description")
                ?? Self.meta(html, "description") ?? ""
        }
        if p.price == nil {
            p.price = Self.decimalFromText(
                Self.meta(html, "og:price:amount")
                ?? Self.meta(html, "product:price:amount"))
        }
        if p.currency == nil {
            p.currency = Self.meta(html, "og:price:currency")
                ?? Self.meta(html, "product:price:currency")
        }
        if p.imageURLs.isEmpty, let img = Self.meta(html, "og:image"),
           let u = URL(string: img) { p.imageURLs = [u] }

        // 3. Microdata --------------------------------------------------
        if p.price == nil {
            p.price = Self.decimalFromText(Self.microdata(html, "price"))
        }
        if p.rating == nil { p.rating = Self.double(Self.microdata(html, "ratingValue")) }
        if p.reviewCount == nil {
            p.reviewCount = Self.int(Self.microdata(html, "reviewCount"))
        }

        // 4. Injected selector extractor (e.g. SwiftSoup) ---------------
        if let extractor {
            let sx = extractor.selectorData(html: html, platform: platform)
            if p.title.isEmpty, let t = sx.title { p.title = t.cleaned }
            if p.brand == nil { p.brand = sx.brand }
            if p.price == nil { p.price = Self.decimalFromText(sx.priceText) }
            if p.rating == nil { p.rating = Self.ratingFromText(sx.ratingText) }
            if p.reviewCount == nil {
                p.reviewCount = Self.reviewCountFromText(sx.reviewCountText)
            }
            if p.bullets.isEmpty { p.bullets = sx.bullets }
            if p.specs.isEmpty { p.specs = sx.specs }
            if p.productDescription.isEmpty, let d = sx.description {
                p.productDescription = d.cleaned
            }
        }

        // 5. Raw text fallback (shared page text wins if HTML was JS-only)
        let visible = Self.visibleText(from: html)
        if p.title.isEmpty {
            p.title = Self.titleTag(html)?.cleaned ?? sharedPageText?.firstLine ?? ""
        }
        if p.rating == nil { p.rating = Self.ratingFromText(visible) }
        if p.reviewCount == nil { p.reviewCount = Self.reviewCountFromText(visible) }
        if p.price == nil { p.price = Self.decimalFromText(visible) }

        let textPool = [sharedPageText ?? "", visible].joined(separator: " ")
        p.rawTextSample = String(textPool.prefix(8000))
        if p.productDescription.isEmpty {
            p.productDescription = String((sharedPageText ?? visible).prefix(1200))
        }
        return p
    }

    // MARK: - JSON-LD

    static func jsonLDProduct(in html: String) -> [String: Any]? {
        let pattern = #"<script[^>]*type=["']application/ld\+json["'][^>]*>([\s\S]*?)</script>"#
        guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        else { return nil }
        let ns = html as NSString
        for m in re.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            let json = ns.substring(with: m.range(at: 1))
            guard let data = json.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) else { continue }
            if let found = findProductNode(obj) { return found }
        }
        return nil
    }

    private static func findProductNode(_ obj: Any) -> [String: Any]? {
        if let dict = obj as? [String: Any] {
            let type = (dict["@type"] as? String)
                ?? (dict["@type"] as? [String])?.first ?? ""
            if type.lowercased().contains("product") { return dict }
            if let graph = dict["@graph"] {
                return findProductNode(graph)
            }
        }
        if let arr = obj as? [Any] {
            for el in arr { if let f = findProductNode(el) { return f } }
        }
        return nil
    }

    private static func firstOffer(_ ld: [String: Any]) -> [String: Any]? {
        if let o = ld["offers"] as? [String: Any] { return o }
        if let arr = ld["offers"] as? [[String: Any]] { return arr.first }
        return nil
    }

    // MARK: - Meta / microdata / text helpers

    static func meta(_ html: String, _ key: String) -> String? {
        let patterns = [
            "<meta[^>]+(?:property|name)=[\"']\(NSRegularExpression.escapedPattern(for: key))[\"'][^>]+content=[\"']([^\"']+)[\"']",
            "<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+(?:property|name)=[\"']\(NSRegularExpression.escapedPattern(for: key))[\"']"
        ]
        for pat in patterns {
            if let v = firstGroup(html, pat) { return v.htmlDecoded }
        }
        return nil
    }

    static func microdata(_ html: String, _ prop: String) -> String? {
        let pat = "itemprop=[\"']\(prop)[\"'][^>]*(?:content=[\"']([^\"']+)[\"']|>\\s*([^<]+))"
        guard let re = try? NSRegularExpression(pattern: pat, options: .caseInsensitive)
        else { return nil }
        let ns = html as NSString
        guard let m = re.firstMatch(in: html, range: NSRange(location: 0, length: ns.length))
        else { return nil }
        for i in [1, 2] where m.range(at: i).location != NSNotFound {
            let s = ns.substring(with: m.range(at: i))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty { return s.htmlDecoded }
        }
        return nil
    }

    static func titleTag(_ html: String) -> String? {
        firstGroup(html, "<title[^>]*>([^<]+)</title>")?.htmlDecoded
    }

    static func visibleText(from html: String) -> String {
        var s = html
        for tag in ["script", "style", "noscript", "svg", "head"] {
            s = s.replacingOccurrences(
                of: "<\(tag)[\\s\\S]*?</\(tag)>",
                with: " ", options: [.regularExpression, .caseInsensitive])
        }
        s = s.replacingOccurrences(of: "<[^>]+>", with: " ",
                                   options: .regularExpression)
        return s.htmlDecoded
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Number normalization

    static func decimal(_ any: Any?) -> Decimal? {
        if let d = any as? Double { return Decimal(d) }
        if let i = any as? Int { return Decimal(i) }
        if let s = any as? String { return decimalFromText(s) }
        return nil
    }

    static func decimalFromText(_ text: String?) -> Decimal? {
        guard let text else { return nil }
        guard let r = text.range(
            of: #"[\d]+([.,][\d]{3})*([.,][\d]{1,2})?"#,
            options: .regularExpression) else { return nil }
        var num = String(text[r])
        if num.contains(",") && num.contains(".") {
            num = num.replacingOccurrences(of: ",", with: "")
        } else if num.filter({ $0 == "," }).count == 1,
                  let after = num.split(separator: ",").last, after.count == 2 {
            num = num.replacingOccurrences(of: ",", with: ".")
        } else {
            num = num.replacingOccurrences(of: ",", with: "")
        }
        return Decimal(string: num)
    }

    static func double(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String { return Double(s.filter { "0123456789.".contains($0) }) }
        return nil
    }

    static func int(_ any: Any?) -> Int? {
        if let i = any as? Int { return i }
        if let d = any as? Double { return Int(d) }
        if let s = any as? String {
            return Int(s.filter { $0.isNumber })
        }
        return nil
    }

    static func ratingFromText(_ text: String?) -> Double? {
        guard let text else { return nil }
        if let r = text.range(of: #"([0-5](\.\d)?)\s*(out of 5|/\s?5|stars?|star rating)"#,
                              options: [.regularExpression, .caseInsensitive]),
           let v = Double(text[r].prefix(while: { $0.isNumber || $0 == "." })) {
            return v
        }
        return nil
    }

    static func reviewCountFromText(_ text: String?) -> Int? {
        guard let text else { return nil }
        if let r = text.range(of: #"([\d,]+)\s*(ratings?|reviews?|global ratings)"#,
                              options: [.regularExpression, .caseInsensitive]) {
            return Int(text[r].filter { $0.isNumber })
        }
        return nil
    }

    private static func firstGroup(_ html: String, _ pattern: String) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        else { return nil }
        let ns = html as NSString
        guard let m = re.firstMatch(in: html, range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges > 1 else { return nil }
        return ns.substring(with: m.range(at: 1))
    }
}

extension String {
    var cleaned: String {
        htmlDecoded
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var firstLine: String {
        components(separatedBy: .newlines).first?
            .trimmingCharacters(in: .whitespaces) ?? self
    }
    var htmlDecoded: String {
        var s = self
        let map = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"",
                   "&#39;": "'", "&apos;": "'", "&nbsp;": " ", "&#x27;": "'"]
        for (k, v) in map { s = s.replacingOccurrences(of: k, with: v) }
        // numeric entities
        if let re = try? NSRegularExpression(pattern: "&#(\\d+);") {
            let ns = s as NSString
            for m in re.matches(in: s, range: NSRange(location: 0, length: ns.length)).reversed() {
                if let code = Int(ns.substring(with: m.range(at: 1))),
                   let scalar = Unicode.Scalar(code) {
                    s = (s as NSString).replacingCharacters(
                        in: m.range, with: String(Character(scalar)))
                }
            }
        }
        return s
    }
}
