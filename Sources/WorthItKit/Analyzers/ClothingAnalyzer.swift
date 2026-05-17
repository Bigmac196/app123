import Foundation

public struct ClothingAnalyzer: ProductAnalyzer {
    public let category: ProductCategory = .clothing
    public init() {}

    public func analyze(_ product: ProductData) -> AnalyzerResult {
        let text = product.searchableText
        var metrics: [Metric] = []
        var explanations: [String] = []
        var delta = 0.0
        var signals = 0

        if HeuristicKit.contains(text, any: ["100% cotton", "merino", "linen", "organic cotton", "supima"]) {
            metrics.append(Metric(label: "Fabric", value: "Natural fibre",
                rating: .good, note: "Cotton/merino/linen — breathable, durable"))
            delta += 0.1; signals += 1
        } else if HeuristicKit.contains(text, any: ["100% polyester", "polyester blend", "spandex blend"]) {
            metrics.append(Metric(label: "Fabric", value: "Synthetic",
                rating: .fair, note: "Polyester-heavy — less breathable")); signals += 1
        }

        if let gsm = HeuristicKit.number(in: text, near: ["gsm"]) {
            metrics.append(Metric(label: "Fabric Weight", value: "\(Int(gsm)) GSM",
                rating: gsm >= 180 ? .good : .fair,
                note: gsm >= 180 ? "Substantial, not see-through" : "Lightweight/thin"))
            if gsm >= 180 { delta += 0.05 }
            signals += 1
        }

        if HeuristicKit.contains(text, any: ["double-stitched", "reinforced seam", "ykk zipper"]) {
            metrics.append(Metric(label: "Construction", value: "Reinforced",
                rating: .good)); delta += 0.06; signals += 1
        }

        let dropship = HeuristicKit.contains(text, any:
            ["ships from overseas", "10-25 days", "aliexpress", "free size"])
        if dropship {
            metrics.append(Metric(label: "Sourcing", value: "Likely dropshipped",
                rating: .warning, note: "Long ship times / 'free size' are dropship signals"))
            delta -= 0.15
            explanations.append("Listing shows classic dropship signals — quality/sizing risk.")
        }

        explanations.append(signals > 0
            ? "Quality inferred from fabric, weight and construction terms."
            : "Minimal garment detail — insights are low confidence.")

        let confidence = min(0.7, 0.25 + Double(signals) * 0.15)
        return AnalyzerResult(category: .clothing, metrics: metrics,
            explanations: explanations, confidence: confidence,
            categoryScoreDelta: max(-1, min(1, delta)))
    }
}
