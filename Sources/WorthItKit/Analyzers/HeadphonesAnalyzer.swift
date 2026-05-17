import Foundation

public struct HeadphonesAnalyzer: ProductAnalyzer {
    public let category: ProductCategory = .headphones
    public init() {}

    public func analyze(_ product: ProductData) -> AnalyzerResult {
        let text = product.searchableText
        var metrics: [Metric] = []
        var explanations: [String] = []
        var delta = 0.0
        var signals = 0

        // ANC
        if HeuristicKit.contains(text, any: ["hybrid anc", "adaptive anc", "adaptive noise"]) {
            metrics.append(Metric(label: "ANC Quality", value: "Strong (hybrid/adaptive)",
                rating: .good)); delta += 0.12; signals += 1
        } else if HeuristicKit.contains(text, any: ["active noise", "anc", "noise cancelling", "noise canceling"]) {
            metrics.append(Metric(label: "ANC Quality", value: "Basic ANC",
                rating: .fair)); signals += 1
        } else if HeuristicKit.contains(text, any: ["noise isolation", "passive isolation"]) {
            metrics.append(Metric(label: "ANC Quality", value: "Passive only",
                rating: .fair, note: "No active cancellation")); signals += 1
        }

        // Sound profile via codec / driver
        if HeuristicKit.contains(text, any: ["ldac", "aptx adaptive", "aptx hd", "hi-res"]) {
            metrics.append(Metric(label: "Sound Profile", value: "Hi-res capable",
                rating: .good, note: "LDAC/aptX-HD/Hi-Res support")); delta += 0.08; signals += 1
        } else if let d = HeuristicKit.number(in: text, near: ["mm driver", "driver"]) {
            metrics.append(Metric(label: "Sound Profile",
                value: "\(Int(d))mm dynamic driver",
                rating: d >= 40 ? .good : .fair)); signals += 1
        }

        // Battery
        if let hrs = HeuristicKit.number(in: text, near: ["hours", "hrs", "hour playtime", "playback"]) {
            let r: MetricRating = hrs >= 30 ? .good : (hrs >= 15 ? .fair : .warning)
            metrics.append(Metric(label: "Battery Life", value: "\(Int(hrs)) h",
                rating: r))
            if hrs >= 30 { delta += 0.06 } else if hrs < 8 { delta -= 0.05 }
            signals += 1
        }

        // Comfort & build
        if HeuristicKit.contains(text, any: ["memory foam", "protein leather", "plush ear"]) {
            metrics.append(Metric(label: "Comfort", value: "Plush padding",
                rating: .good)); delta += 0.05; signals += 1
        }
        if HeuristicKit.contains(text, any: ["aluminum", "metal frame", "stainless"]) {
            metrics.append(Metric(label: "Build Quality", value: "Metal components",
                rating: .good)); delta += 0.04
        } else if HeuristicKit.contains(text, any: ["all plastic", "plastic build"]) {
            metrics.append(Metric(label: "Build Quality", value: "Plastic",
                rating: .fair))
        }

        explanations.append(signals > 1
            ? "ANC, sound and battery inferred from codec, driver and stated specs."
            : "Limited audio specs — insights are low confidence.")

        let confidence = min(0.82, 0.25 + Double(signals) * 0.16)
        return AnalyzerResult(category: .headphones, metrics: metrics,
            explanations: explanations, confidence: confidence,
            categoryScoreDelta: max(-1, min(1, delta)))
    }
}
