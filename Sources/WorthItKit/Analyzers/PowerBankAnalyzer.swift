import Foundation

public struct PowerBankAnalyzer: ProductAnalyzer {
    public let category: ProductCategory = .powerBank
    public init() {}

    public func analyze(_ product: ProductData) -> AnalyzerResult {
        let text = product.searchableText
        var metrics: [Metric] = []
        var explanations: [String] = []
        var delta = 0.0
        var signals = 0

        if let mah = HeuristicKit.number(in: text, near: ["mah", "milliamp"]) {
            // Cell→usable efficiency ~62% (3.7V cells → 5V output + conversion loss)
            let usable = Int(mah * 0.62)
            metrics.append(Metric(label: "Real Usable Capacity",
                value: "≈\(usable) mAh @5V",
                rating: mah >= 10000 ? .good : .fair,
                note: "Rated \(Int(mah)) mAh — real output is ~62% after conversion"))
            if mah > 50000 {
                metrics.append(Metric(label: "Capacity Claim", value: "Implausibly high",
                    rating: .warning, note: "Very large mAh on a small pack is a fake-spec red flag"))
                delta -= 0.2
                explanations.append("Stated \(Int(mah)) mAh is implausible for the size — likely inflated.")
            }
            signals += 1
        }

        if let w = HeuristicKit.number(in: text, near: ["watt", "w pd", "w output", "power delivery"]) {
            metrics.append(Metric(label: "Output Power", value: "\(Int(w))W",
                rating: w >= 30 ? .good : (w >= 18 ? .fair : .warning),
                note: w >= 30 ? "Can fast-charge laptops/phones" : "Phone-only speeds"))
            if w >= 30 { delta += 0.1 }
            signals += 1
        }
        if HeuristicKit.contains(text, any: ["pd 3.0", "power delivery", "pps", "quick charge"]) {
            metrics.append(Metric(label: "Fast Charge", value: "PD / PPS / QC",
                rating: .good)); delta += 0.06; signals += 1
        }

        explanations.append(signals > 0
            ? "Real capacity and charging speed inferred from rated mAh and wattage."
            : "No battery specs found — insights are low confidence.")

        let confidence = min(0.8, 0.25 + Double(signals) * 0.17)
        return AnalyzerResult(category: .powerBank, metrics: metrics,
            explanations: explanations, confidence: confidence,
            categoryScoreDelta: max(-1, min(1, delta)))
    }
}
