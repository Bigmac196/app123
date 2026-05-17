import Foundation

public struct KitchenApplianceAnalyzer: ProductAnalyzer {
    public let category: ProductCategory = .kitchenAppliance
    public init() {}

    public func analyze(_ product: ProductData) -> AnalyzerResult {
        let text = product.searchableText
        var metrics: [Metric] = []
        var explanations: [String] = []
        var delta = 0.0
        var signals = 0

        if let w = HeuristicKit.number(in: text, near: ["watt", "w power", "wattage"]) {
            metrics.append(Metric(label: "Power", value: "\(Int(w))W",
                rating: w >= 1200 ? .good : (w >= 700 ? .fair : .warning),
                note: w >= 1200 ? "Strong heating/motor performance" : "Lower power — slower results"))
            if w >= 1200 { delta += 0.08 }
            signals += 1
        }
        if let cap = HeuristicKit.number(in: text, near: ["quart", "litre", "liter", "qt", "cup capacity"]) {
            metrics.append(Metric(label: "Capacity", value: "\(cap.clean) units",
                rating: .neutral)); signals += 1
        }

        if HeuristicKit.contains(text, any: ["stainless steel", "die-cast", "metal housing"]) {
            metrics.append(Metric(label: "Build", value: "Stainless / metal",
                rating: .good)); delta += 0.08; signals += 1
        } else if HeuristicKit.contains(text, any: ["all plastic", "plastic basket", "plastic body"]) {
            metrics.append(Metric(label: "Build", value: "Plastic",
                rating: .fair, note: "Plastic-heavy build wears faster")); signals += 1
        }

        if let yrs = HeuristicKit.warrantyYears(in: text) {
            metrics.append(Metric(label: "Warranty",
                value: yrs >= 10 ? "Lifetime" : "\(Int(yrs)) yr",
                rating: yrs >= 2 ? .good : .fair))
            if yrs >= 2 { delta += 0.05 }
            signals += 1
        }

        if HeuristicKit.contains(text, any: ["as seen on tiktok", "viral", "tiktok made me buy",
                                             "as seen on social"]) {
            metrics.append(Metric(label: "Hype Flag", value: "Marketed as 'viral'",
                rating: .warning, note: "Virality ≠ quality — judge on specs"))
            delta -= 0.05
        }

        explanations.append(signals > 0
            ? "Performance and durability inferred from wattage, capacity, build and warranty."
            : "Few appliance specs — insights are low confidence.")

        let confidence = min(0.78, 0.25 + Double(signals) * 0.15)
        return AnalyzerResult(category: .kitchenAppliance, metrics: metrics,
            explanations: explanations, confidence: confidence,
            categoryScoreDelta: max(-1, min(1, delta)))
    }
}

private extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(self)) : String(format: "%.1f", self)
    }
}
