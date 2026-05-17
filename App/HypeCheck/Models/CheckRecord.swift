import Foundation
import SwiftData
import HypeCheckKit

/// Persisted history entry. Stores the full analysis as archived JSON so the
/// results screen can be re-rendered offline without re-fetching.
@Model
final class CheckRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var sourceURL: URL
    var title: String
    var verdictRaw: String
    var score: Double
    var confidence: Double
    var categoryRaw: String
    var outcomeData: Data

    init(outcome: AnalysisOutcome) {
        self.id = UUID()
        self.createdAt = outcome.createdAt
        self.sourceURL = outcome.product.sourceURL
        self.title = outcome.product.title
        self.verdictRaw = outcome.breakdown.verdict.rawValue
        self.score = outcome.breakdown.score
        self.confidence = outcome.breakdown.confidence
        self.categoryRaw = outcome.category.rawValue
        self.outcomeData = (try? JSONEncoder().encode(outcome)) ?? Data()
    }

    var outcome: AnalysisOutcome? {
        try? JSONDecoder().decode(AnalysisOutcome.self, from: outcomeData)
    }

    var verdict: Verdict { Verdict(rawValue: verdictRaw) ?? .suspicious }
}
