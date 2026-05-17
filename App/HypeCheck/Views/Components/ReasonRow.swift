import SwiftUI

struct ReasonRow: View {
    let reason: Reason

    private var icon: String {
        switch reason.polarity {
        case .positive: return "plus.circle.fill"
        case .negative: return "minus.circle.fill"
        case .neutral: return "circle.fill"
        }
    }
    private var color: Color {
        switch reason.polarity {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .secondary
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(color)
            Text(reason.text).font(.subheadline)
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reason.polarity == .negative ? "Concern" : "Plus"): \(reason.text)")
    }
}

struct MetricCard: View {
    let metric: Metric

    private var color: Color {
        switch metric.rating {
        case .excellent, .good: return .green
        case .fair, .neutral: return .secondary
        case .poor: return .red
        case .warning: return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(metric.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: metric.rating.symbolName)
                    .font(.caption)
                    .foregroundStyle(color)
            }
            Text(metric.value)
                .font(.body.weight(.semibold))
            if let note = metric.note {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
