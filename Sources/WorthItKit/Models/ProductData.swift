import Foundation

public enum Platform: String, Codable, Sendable, CaseIterable {
    case amazon, tiktokShop, walmart, target, temu, ebay, shein, aliexpress, unknown

    public init(host: String?) {
        guard let h = host?.lowercased() else { self = .unknown; return }
        switch true {
        case h.contains("amazon"), h.contains("amzn"): self = .amazon
        case h.contains("tiktok"): self = .tiktokShop
        case h.contains("walmart"): self = .walmart
        case h.contains("target"): self = .target
        case h.contains("temu"): self = .temu
        case h.contains("ebay"): self = .ebay
        case h.contains("shein"): self = .shein
        case h.contains("aliexpress"): self = .aliexpress
        default: self = .unknown
        }
    }
}

/// Structured listing data extracted from a product page. The single source of
/// truth consumed by the classifier, analyzers and scoring engine.
public struct ProductData: Codable, Equatable, Sendable {
    public var sourceURL: URL
    public var platform: Platform
    public var title: String
    public var brand: String?
    public var price: Decimal?
    public var currency: String?
    public var listPrice: Decimal?
    public var rating: Double?
    public var reviewCount: Int?
    public var productDescription: String
    public var bullets: [String]
    public var specs: [String: String]
    public var imageURLs: [URL]
    public var rawTextSample: String

    public init(
        sourceURL: URL,
        platform: Platform = .unknown,
        title: String = "",
        brand: String? = nil,
        price: Decimal? = nil,
        currency: String? = nil,
        listPrice: Decimal? = nil,
        rating: Double? = nil,
        reviewCount: Int? = nil,
        productDescription: String = "",
        bullets: [String] = [],
        specs: [String: String] = [:],
        imageURLs: [URL] = [],
        rawTextSample: String = ""
    ) {
        self.sourceURL = sourceURL
        self.platform = platform
        self.title = title
        self.brand = brand
        self.price = price
        self.currency = currency
        self.listPrice = listPrice
        self.rating = rating
        self.reviewCount = reviewCount
        self.productDescription = productDescription
        self.bullets = bullets
        self.specs = specs
        self.imageURLs = imageURLs
        self.rawTextSample = rawTextSample
    }

    /// Lower-cased haystack of every text field, used by keyword heuristics.
    public var searchableText: String {
        var parts = [title, brand ?? "", productDescription, rawTextSample]
        parts.append(contentsOf: bullets)
        parts.append(contentsOf: specs.map { "\($0.key) \($0.value)" })
        return parts.joined(separator: " \n ").lowercased()
    }

    public var discountFraction: Double? {
        guard let list = listPrice, let price, list > 0, price < list else { return nil }
        let d = (list - price) / list
        return NSDecimalNumber(decimal: d).doubleValue
    }
}

/// How much usable signal the parser recovered. Gates downstream confidence.
public enum ParseQuality: String, Codable, Sendable {
    case rich, partial, sparse

    public init(product: ProductData) {
        var score = 0
        if !product.title.isEmpty { score += 1 }
        if product.price != nil { score += 1 }
        if product.rating != nil { score += 1 }
        if product.reviewCount != nil { score += 1 }
        if product.productDescription.count > 120 || !product.bullets.isEmpty { score += 1 }
        if !product.specs.isEmpty { score += 1 }
        switch score {
        case 5...: self = .rich
        case 2..<5: self = .partial
        default: self = .sparse
        }
    }

    public var confidenceFloor: Double {
        switch self {
        case .rich: return 0.85
        case .partial: return 0.6
        case .sparse: return 0.35
        }
    }
}
