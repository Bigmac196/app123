import SwiftUI

struct ExpertInsightsSection: View {
    let result: AnalyzerResult

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Expert Insights")
                    .font(.headline)
                Spacer()
                Text(result.category.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.tint.opacity(0.15), in: Capsule())
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(result.metrics) { MetricCard(metric: $0) }
            }

            if !result.explanations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(result.explanations, id: \.self) { line in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(line).font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }

            Text("Estimated from the listing — not lab-verified.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.tint.opacity(0.35), lineWidth: 1)
                .background(.tint.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 18)))
    }
}
