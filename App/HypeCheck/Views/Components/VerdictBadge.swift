import SwiftUI

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self = Color(
            red: Double((v >> 16) & 0xff) / 255,
            green: Double((v >> 8) & 0xff) / 255,
            blue: Double(v & 0xff) / 255)
    }
}

struct VerdictBadge: View {
    let verdict: Verdict
    let score: Double

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: verdict.symbolName)
                .font(.system(size: 46, weight: .bold))
            Text(verdict.headline)
                .font(.title.bold())
            Text("Score \(Int(score)) / 100")
                .font(.subheadline.weight(.semibold))
                .opacity(0.9)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            LinearGradient(
                colors: [Color(hex: verdict.tintHex),
                         Color(hex: verdict.tintHex).opacity(0.75)],
                startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(verdict.headline), score \(Int(score)) out of 100")
    }
}

struct ConfidenceBar: View {
    let confidence: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Confidence").font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(confidence * 100))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule().fill(.tint)
                        .frame(width: geo.size.width * confidence)
                }
            }
            .frame(height: 8)
            Text("Based on how much data we could read from the listing.")
                .font(.caption2).foregroundStyle(.tertiary)
        }
    }
}
