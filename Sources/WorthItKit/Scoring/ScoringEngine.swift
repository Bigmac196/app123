import Foundation

/// Weighted, explainable, fully deterministic scoring. Each signal emits a
/// `Reason`; signals are combined into a 0–100 score, mapped to a `Verdict`
/// with a hard "suspicious" override.
public struct ScoringEngine: Sendable {
    public init() {}

    public func score(product: ProductData,
                      category: ProductCategory,
                      analyzer: AnalyzerResult,
                      parseQuality: ParseQuality,
                      classifierConfidence: Double) -> ScoreBreakdown {

        var reasons: [Reason] = []
        // Each signal contributes a value in -1...+1, later weighted.
        var weightedSum = 0.0
        var weightTotal = 0.0
        var signalCount = 0

        func add(_ value: Double, _ weight: Double,
                 _ text: String, positiveWhenHigh: Bool = true) {
            weightedSum += value * weight
            weightTotal += weight
            signalCount += 1
            let polarity: ReasonPolarity = value > 0.15 ? .positive
                : (value < -0.15 ? .negative : .neutral)
            reasons.append(Reason(text: text, polarity: polarity,
                                  weight: abs(value) * weight))
        }

        // 1. Rating ------------------------------------------------------
        if let rating = product.rating {
            let v = ((rating - 3.5) / 1.5).clamped(-1, 1)
            add(v, ScoringRules.wRating,
                String(format: "Customer rating %.1f/5", rating))
        }

        // 2. Review volume ----------------------------------------------
        if let count = product.reviewCount {
            let tier = HeuristicKit.reviewVolumeTier(count)
            let v = (Double(tier.rawValue) - 1.5) / 2.5
            add(v.clamped(-1, 1), ScoringRules.wReviewVolume,
                "\(count) reviews (\(count < 25 ? "thin" : "solid") sample)")
        }

        // 3. Rating × volume combo (fake-review smell) ------------------
        if let rating = product.rating, let count = product.reviewCount {
            if rating >= 4.6 && count < 30 {
                add(-0.8, ScoringRules.wRatingVolumeCombo,
                    "Near-perfect rating on very few reviews — possible seeded reviews")
            } else if rating >= 4.2 && count >= 500 {
                add(0.7, ScoringRules.wRatingVolumeCombo,
                    "Strong rating sustained over many reviews")
            } else {
                add(0.1, ScoringRules.wRatingVolumeCombo,
                    "Rating/volume ratio looks normal")
            }
        }

        // 4. Price plausibility -----------------------------------------
        if let price = HeuristicKit.double(product.price),
           let band = ScoringRules.typicalBand(category) {
            let v: Double
            let txt: String
            if price < band.low * 0.4 {
                v = -0.7; txt = "Price far below typical range — quality/authenticity risk"
            } else if price > band.high * 1.4 {
                v = -0.5; txt = "Priced well above typical range for the category"
            } else if price <= band.low {
                v = 0.6; txt = "Priced at the low end of the typical range"
            } else {
                v = 0.2; txt = "Price within the typical range"
            }
            add(v, ScoringRules.wPricePlausibility, txt)
        }

        // 5. Discount plausibility --------------------------------------
        if let disc = product.discountFraction {
            let v = disc >= 0.85 ? -0.8 : (disc >= 0.6 ? -0.3 : 0.2)
            add(v, ScoringRules.wDiscountPlausibility,
                "\(Int(disc * 100))% off list price")
        }

        // 6. Listing quality --------------------------------------------
        let richness = product.productDescription.count
            + product.bullets.joined().count + product.specs.count * 30
        let lq = richness > 600 ? 0.6 : (richness < 120 ? -0.6 : 0.1)
        add(lq, ScoringRules.wListingQuality,
            richness > 600 ? "Detailed, specific listing"
                : (richness < 120 ? "Sparse, low-effort listing" : "Adequate listing detail"))

        // 7. Category analyzer delta ------------------------------------
        if category != .general || analyzer.categoryScoreDelta != 0 {
            add(analyzer.categoryScoreDelta, ScoringRules.wCategoryDelta,
                "Category specialist (\(category.displayName)) assessment")
        }

        // Combine → 0...100 ---------------------------------------------
        let normalized = weightTotal > 0 ? weightedSum / weightTotal : 0
        let score = ((normalized + 1) / 2 * 100).clamped(0, 100)

        // Confidence -----------------------------------------------------
        let confidence = ([
            parseQuality.confidenceFloor,
            classifierConfidence,
            0.4 + analyzer.confidence * 0.6,
            min(1, 0.3 + Double(signalCount) * 0.12)
        ].reduce(0, +) / 4).clamped(0, 1)

        // Verdict (with suspicious override) ----------------------------
        let verdict = Self.verdict(score: score, product: product,
                                   category: category)
        return ScoreBreakdown(verdict: verdict, score: score,
                              confidence: confidence, reasons: reasons)
    }

    static func verdict(score: Double, product: ProductData,
                        category: ProductCategory) -> Verdict {
        // Hard suspicious flags
        if let r = product.rating, let c = product.reviewCount,
           r >= ScoringRules.suspiciousHighRating,
           c < ScoringRules.suspiciousLowReviews {
            return .suspicious
        }
        if let disc = product.discountFraction,
           disc >= ScoringRules.suspiciousDiscount,
           (product.productDescription.count + product.bullets.joined().count) < 120 {
            return .suspicious
        }
        if let p = HeuristicKit.double(product.price), p <= 0.01 {
            return .suspicious
        }

        switch score {
        case ScoringRules.greatValueFloor...:
            if let p = HeuristicKit.double(product.price),
               let band = ScoringRules.typicalBand(category), p <= band.low {
                return .greatValue
            }
            return .worthIt
        case ScoringRules.worthItFloor..<ScoringRules.greatValueFloor:
            return .worthIt
        case ScoringRules.overpricedFloor..<ScoringRules.worthItFloor:
            return .overpriced
        default:
            return .junk
        }
    }
}

private extension Double {
    func clamped(_ lo: Double, _ hi: Double) -> Double { min(hi, max(lo, self)) }
}
