import Foundation

/// Output of a category analyzer: structured metrics, plain-language
/// explanations, a confidence in those inferences, and a signed nudge to the
/// overall score (-1 great … +1 poor is *not* the convention — see below).
///
/// `categoryScoreDelta` is in `-1...+1` where **positive means the
/// category-specific signals were favourable** (raises the final score) and
/// negative means unfavourable. Magnitude reflects strength of evidence.
public struct AnalyzerResult: Codable, Sendable, Equatable {
    public var category: ProductCategory
    public var metrics: [Metric]
    public var explanations: [String]
    public var confidence: Double
    public var categoryScoreDelta: Double

    public init(category: ProductCategory,
                metrics: [Metric] = [],
                explanations: [String] = [],
                confidence: Double = 0,
                categoryScoreDelta: Double = 0) {
        self.category = category
        self.metrics = metrics
        self.explanations = explanations
        self.confidence = min(1, max(0, confidence))
        self.categoryScoreDelta = min(1, max(-1, categoryScoreDelta))
    }
}
