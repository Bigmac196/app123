import Foundation

public struct LEDLightingAnalyzer: ProductAnalyzer {
    public let category: ProductCategory = .ledLighting
    public init() {}

    public func analyze(_ product: ProductData) -> AnalyzerResult {
        let text = product.searchableText
        var metrics: [Metric] = []
        var explanations: [String] = []
        var delta = 0.0
        var signals = 0

        if let lumens = HeuristicKit.number(in: text, near: ["lumen"]) {
            metrics.append(Metric(label: "Brightness", value: "\(Int(lumens)) lm",
                rating: lumens >= 800 ? .good : (lumens >= 300 ? .fair : .warning),
                note: "True lumens stated"))
            if lumens >= 800 { delta += 0.08 }
            signals += 1
        } else if HeuristicKit.contains(text, any: ["super bright", "brightest", "1000000 lumens"]) {
            metrics.append(Metric(label: "Brightness", value: "Vague / exaggerated claim",
                rating: .warning, note: "No real lumen figure — classic viral-junk signal"))
            delta -= 0.12
            explanations.append("Brightness described in hype terms with no lumen rating.")
        }

        if let cri = HeuristicKit.number(in: text, near: ["cri", "color rendering"]) {
            metrics.append(Metric(label: "Color Accuracy", value: "CRI \(Int(cri))",
                rating: cri >= 90 ? .good : (cri >= 80 ? .fair : .warning)))
            if cri >= 90 { delta += 0.06 }
            signals += 1
        }

        if HeuristicKit.contains(text, any: ["app control", "music sync", "rgbic", "smart"]) {
            metrics.append(Metric(label: "Features", value: "App / music sync / RGBIC",
                rating: .good)); delta += 0.04; signals += 1
        }

        if HeuristicKit.contains(text, any: ["weak adhesive", "falls off", "tape", "3m adhesive"]) {
            let r: MetricRating = HeuristicKit.contains(text, any: ["3m adhesive"]) ? .fair : .warning
            metrics.append(Metric(label: "Mounting", value: "Adhesive-backed",
                rating: r, note: "Adhesive longevity is the top complaint for LED strips"))
            if r == .warning { delta -= 0.05 }
            signals += 1
        }

        explanations.append(signals > 0
            ? "Quality inferred from lumen rating, CRI, features and mounting."
            : "No lighting specs — insights are low confidence. LED strips are a high-junk category.")

        let confidence = min(0.75, 0.25 + Double(signals) * 0.15)
        return AnalyzerResult(category: .ledLighting, metrics: metrics,
            explanations: explanations, confidence: confidence,
            categoryScoreDelta: max(-1, min(1, delta)))
    }
}
