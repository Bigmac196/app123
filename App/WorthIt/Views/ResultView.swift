import SwiftUI
import WorthItKit

struct ResultView: View {
    let outcome: AnalysisOutcome

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VerdictBadge(verdict: outcome.breakdown.verdict,
                             score: outcome.breakdown.score)
                ConfidenceBar(confidence: outcome.breakdown.confidence)

                productSummary

                ReasonsSection(breakdown: outcome.breakdown)

                if !outcome.analyzer.metrics.isEmpty {
                    ExpertInsightsSection(result: outcome.analyzer)
                }

                Link(destination: outcome.product.sourceURL) {
                    Label("Open original listing", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Text("WorthIt verdicts are heuristic estimates from the listing "
                     + "text, not lab tests or professional advice.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var productSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(outcome.product.title.isEmpty ? "Untitled product"
                 : outcome.product.title)
                .font(.headline)
            HStack(spacing: 12) {
                if let brand = outcome.product.brand {
                    Label(brand, systemImage: "tag")
                }
                if let price = outcome.product.price {
                    Label(price.formatted(.currency(
                        code: outcome.product.currency ?? "USD")),
                          systemImage: "dollarsign")
                }
                if let rating = outcome.product.rating {
                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Label(outcome.category.displayName, systemImage: outcome.category.symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ReasonsSection: View {
    let breakdown: ScoreBreakdown
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Why this verdict").font(.headline)
            ForEach(breakdown.positiveReasons + breakdown.negativeReasons) { r in
                ReasonRow(reason: r)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
