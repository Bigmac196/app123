import Foundation

public enum MetricRating: String, Codable, Sendable {
    case poor, fair, good, excellent, neutral, warning

    public var symbolName: String {
        switch self {
        case .poor: return "xmark.circle.fill"
        case .fair: return "minus.circle.fill"
        case .good: return "checkmark.circle.fill"
        case .excellent: return "star.circle.fill"
        case .neutral: return "circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
}

/// One inferred, expert-style data point shown in the "Expert Insights" cards.
public struct Metric: Codable, Identifiable, Sendable, Equatable {
    public var id: UUID
    public var label: String
    public var value: String
    public var rating: MetricRating
    public var note: String?

    public init(id: UUID = UUID(), label: String, value: String,
                rating: MetricRating = .neutral, note: String? = nil) {
        self.id = id
        self.label = label
        self.value = value
        self.rating = rating
        self.note = note
    }
}
