import Foundation

/// Fallback analyzer. Works purely from universal trust signals: rating,
/// review volume, listing richness and discount plausibility.
public struct GenericAnalyzer: ProductAnalyzer {
    public let category: ProductCategory = .general
    public init() {}

    public func analyze(_ product: ProductData) -> AnalyzerResult {
        var metrics: [Metric] = []
        var explanations: [String] = []
        var delta = 0.0
        var signals = 0

        if let rating = product.rating {
            let tier = HeuristicKit.ratingTier(rating)
            let rMetric: MetricRating
            switch tier {
            case .veryHigh, .high: rMetric = .good; delta += 0.25
            case .mid: rMetric = .fair
            default: rMetric = .poor; delta -= 0.25
            }
            metrics.append(Metric(label: "Customer Rating",
                value: String(format: "%.1f / 5", rating), rating: rMetric))
            signals += 1
        }

        if let count = product.reviewCount {
            let tier = HeuristicKit.reviewVolumeTier(count)
            let rMetric: MetricRating = tier.rawValue >= HeuristicKit.Tier.mid.rawValue
                ? .good : (tier == .veryLow ? .warning : .fair)
            if tier == .veryLow {
                explanations.append("Very few reviews (\(count)) — limited social proof.")
                delta -= 0.1
            } else if tier.rawValue >= HeuristicKit.Tier.high.rawValue {
                delta += 0.1
            }
            metrics.append(Metric(label: "Review Volume",
                value: "\(count) reviews", rating: rMetric))
            signals += 1
        }

        let richness = product.productDescription.count
            + product.bullets.joined().count + product.specs.count * 30
        if richness > 600 {
            metrics.append(Metric(label: "Listing Detail", value: "Thorough",
                rating: .good, note: "Detailed description and specs"))
            delta += 0.1
        } else if richness < 120 {
            metrics.append(Metric(label: "Listing Detail", value: "Sparse",
                rating: .warning, note: "Thin listing — common with low-effort resellers"))
            delta -= 0.15
            explanations.append("Listing is unusually thin for a genuine product.")
        }
        signals += 1

        if let disc = product.discountFraction, disc >= 0.7 {
            metrics.append(Metric(label: "Discount", value: "\(Int(disc * 100))% off",
                rating: .warning, note: "Steep permanent discounts are often inflated MSRPs"))
            delta -= 0.1
            explanations.append("Aggressive \(Int(disc * 100))% discount — verify the original price is real.")
        }

        if explanations.isEmpty {
            explanations.append("Scored on universal trust signals only — no category specialist matched.")
        }

        let confidence = min(0.7, 0.25 + Double(signals) * 0.12)
        return AnalyzerResult(category: .general, metrics: metrics,
            explanations: explanations, confidence: confidence,
            categoryScoreDelta: max(-1, min(1, delta)))
    }
}
