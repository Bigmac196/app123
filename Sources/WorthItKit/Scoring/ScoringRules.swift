import Foundation

/// All tunable scoring constants in one place for easy calibration.
public enum ScoringRules {
    // Signal weights (sum ≈ 1.0)
    public static let wRating = 0.25
    public static let wReviewVolume = 0.15
    public static let wRatingVolumeCombo = 0.10
    public static let wPricePlausibility = 0.15
    public static let wDiscountPlausibility = 0.10
    public static let wListingQuality = 0.10
    public static let wCategoryDelta = 0.15

    // Verdict thresholds (0...100)
    public static let greatValueFloor = 78.0
    public static let worthItFloor = 55.0
    public static let overpricedFloor = 38.0

    // Suspicious hard-flag triggers
    public static let suspiciousHighRating = 4.7
    public static let suspiciousLowReviews = 20
    public static let suspiciousDiscount = 0.85

    /// Rough "typical" price band (USD) per category — used only to judge
    /// plausibility, never to hard-fail. Skipped when price/currency unknown.
    public static func typicalBand(_ c: ProductCategory) -> (low: Double, high: Double)? {
        switch c {
        case .fragrance: return (25, 180)
        case .standingDesk: return (150, 800)
        case .officeChair: return (90, 1500)
        case .headphones: return (20, 400)
        case .skincare: return (8, 90)
        case .clothing: return (10, 150)
        case .supplement: return (10, 70)
        case .powerBank: return (15, 120)
        case .kitchenAppliance: return (30, 500)
        case .ledLighting: return (10, 120)
        case .general: return nil
        }
    }
}
