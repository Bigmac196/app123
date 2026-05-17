import Foundation

public enum Verdict: String, Codable, Sendable, CaseIterable {
    case greatValue = "Great Value"
    case worthIt = "Worth It"
    case overpriced = "Probably Overpriced"
    case junk = "Likely Junk"
    case suspicious = "Suspicious Listing"

    public var symbolName: String {
        switch self {
        case .greatValue: return "checkmark.seal.fill"
        case .worthIt: return "hand.thumbsup.fill"
        case .overpriced: return "dollarsign.circle.fill"
        case .junk: return "hand.thumbsdown.fill"
        case .suspicious: return "exclamationmark.shield.fill"
        }
    }

    /// Hex color used by the verdict badge.
    public var tintHex: String {
        switch self {
        case .greatValue: return "#1DB954"
        case .worthIt: return "#34C759"
        case .overpriced: return "#FF9F0A"
        case .junk: return "#FF3B30"
        case .suspicious: return "#AF52DE"
        }
    }

    public var headline: String {
        switch self {
        case .greatValue: return "Great Value"
        case .worthIt: return "Worth It"
        case .overpriced: return "Probably Overpriced"
        case .junk: return "Likely Junk"
        case .suspicious: return "Suspicious Listing"
        }
    }
}

public enum ReasonPolarity: String, Codable, Sendable {
    case positive, negative, neutral
}

public struct Reason: Codable, Identifiable, Sendable, Equatable {
    public var id: UUID
    public var text: String
    public var polarity: ReasonPolarity
    public var weight: Double

    public init(id: UUID = UUID(), text: String,
                polarity: ReasonPolarity, weight: Double) {
        self.id = id
        self.text = text
        self.polarity = polarity
        self.weight = weight
    }
}

/// The full explainable scoring output rendered on the results screen.
public struct ScoreBreakdown: Codable, Sendable, Equatable {
    public var verdict: Verdict
    public var score: Double          // 0...100
    public var confidence: Double     // 0...1
    public var reasons: [Reason]

    public init(verdict: Verdict, score: Double,
                confidence: Double, reasons: [Reason]) {
        self.verdict = verdict
        self.score = score
        self.confidence = confidence
        self.reasons = reasons
    }

    public var positiveReasons: [Reason] {
        reasons.filter { $0.polarity == .positive }
            .sorted { $0.weight > $1.weight }
    }
    public var negativeReasons: [Reason] {
        reasons.filter { $0.polarity == .negative }
            .sorted { $0.weight > $1.weight }
    }
}

/// A complete, self-contained analysis ready to display or persist.
public struct AnalysisOutcome: Codable, Sendable, Equatable {
    public var product: ProductData
    public var category: ProductCategory
    public var analyzer: AnalyzerResult
    public var breakdown: ScoreBreakdown
    public var createdAt: Date

    public init(product: ProductData, category: ProductCategory,
                analyzer: AnalyzerResult, breakdown: ScoreBreakdown,
                createdAt: Date = Date()) {
        self.product = product
        self.category = category
        self.analyzer = analyzer
        self.breakdown = breakdown
        self.createdAt = createdAt
    }
}
