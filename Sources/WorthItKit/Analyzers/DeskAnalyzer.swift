import Foundation

public struct DeskAnalyzer: ProductAnalyzer {
    public let category: ProductCategory = .standingDesk
    public init() {}

    public func analyze(_ product: ProductData) -> AnalyzerResult {
        let text = product.searchableText
        var metrics: [Metric] = []
        var explanations: [String] = []
        var delta = 0.0
        var signals = 0

        // Motor → stability / wobble ------------------------------------
        if HeuristicKit.contains(text, any: ["dual motor", "double motor", "2 motor"]) {
            metrics.append(Metric(label: "Stability", value: "High",
                rating: .good, note: "Dual-motor frame"))
            metrics.append(Metric(label: "Wobble Risk", value: "Low", rating: .good))
            delta += 0.2; signals += 1
        } else if HeuristicKit.contains(text, any: ["single motor", "1 motor"]) {
            metrics.append(Metric(label: "Stability", value: "Moderate",
                rating: .fair, note: "Single-motor — more wobble at full height"))
            metrics.append(Metric(label: "Wobble Risk", value: "Moderate", rating: .fair))
            signals += 1
        } else {
            metrics.append(Metric(label: "Stability", value: "Unknown",
                rating: .neutral, note: "Motor configuration not stated"))
        }

        // Weight capacity ----------------------------------------------
        if let cap = HeuristicKit.weightCapacityLbs(in: text) {
            let r: MetricRating
            let note: String
            switch cap {
            case 220...: r = .excellent; note = "Headroom for heavy multi-monitor setups"; delta += 0.1
            case 150..<220: r = .good; note = "Comfortable for typical setups"
            default: r = .warning; note = "Tight for dual-monitor / accessories"; delta -= 0.1
            }
            metrics.append(Metric(label: "Weight Capacity",
                value: "\(Int(cap)) lb", rating: r, note: note))
            metrics.append(Metric(label: "Monitor Suitability",
                value: cap >= 220 ? "Dual / ultrawide" : (cap >= 150 ? "Single–dual" : "Single only"),
                rating: cap >= 150 ? .good : .fair))
            signals += 1
        }

        // Frame material ------------------------------------------------
        if HeuristicKit.contains(text, any: ["steel frame", "solid steel", "carbon steel"]) {
            metrics.append(Metric(label: "Frame", value: "Steel",
                rating: .good, note: "Steel frames resist sway")); delta += 0.05; signals += 1
        } else if HeuristicKit.contains(text, any: ["alloy", "aluminum frame"]) {
            metrics.append(Metric(label: "Frame", value: "Alloy/Aluminum", rating: .fair))
        }

        // Warranty ------------------------------------------------------
        if let yrs = HeuristicKit.warrantyYears(in: text) {
            let r: MetricRating = yrs >= 5 ? .good : (yrs <= 1 ? .warning : .fair)
            metrics.append(Metric(label: "Warranty",
                value: yrs >= 10 ? "Lifetime" : "\(Int(yrs)) yr", rating: r))
            if yrs >= 5 { delta += 0.05 } else if yrs <= 1 {
                explanations.append("Short warranty (\(Int(yrs)) yr) is a durability red flag for motorized desks.")
                delta -= 0.05
            }
            signals += 1
        }

        explanations.append(signals > 0
            ? "Stability and durability inferred from motor count, capacity, frame and warranty."
            : "Listing lacks desk-specific specs; insights are low confidence.")

        let confidence = min(0.85, 0.25 + Double(signals) * 0.18)
        return AnalyzerResult(category: .standingDesk, metrics: metrics,
            explanations: explanations, confidence: confidence,
            categoryScoreDelta: max(-1, min(1, delta)))
    }
}
