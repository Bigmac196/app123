import Foundation

public struct ChairAnalyzer: ProductAnalyzer {
    public let category: ProductCategory = .officeChair
    public init() {}

    public func analyze(_ product: ProductData) -> AnalyzerResult {
        let text = product.searchableText
        var metrics: [Metric] = []
        var explanations: [String] = []
        var delta = 0.0
        var signals = 0

        // Breathability
        if HeuristicKit.contains(text, any: ["mesh back", "breathable mesh", "full mesh"]) {
            metrics.append(Metric(label: "Breathability", value: "Good",
                rating: .good, note: "Mesh back")); delta += 0.08; signals += 1
        } else if HeuristicKit.contains(text, any: ["pu leather", "faux leather", "bonded leather"]) {
            metrics.append(Metric(label: "Breathability", value: "Low",
                rating: .fair, note: "PU/faux leather traps heat")); signals += 1
        }

        // Lumbar
        if HeuristicKit.contains(text, any: ["adjustable lumbar", "dynamic lumbar", "adaptive lumbar"]) {
            metrics.append(Metric(label: "Lumbar Support", value: "Adjustable",
                rating: .good)); delta += 0.12; signals += 1
        } else if HeuristicKit.contains(text, any: ["lumbar"]) {
            metrics.append(Metric(label: "Lumbar Support", value: "Fixed",
                rating: .fair, note: "Non-adjustable lumbar fits a narrow height range")); signals += 1
        } else {
            metrics.append(Metric(label: "Lumbar Support", value: "Not mentioned",
                rating: .warning)); delta -= 0.05
        }

        // Long-session comfort
        let adjusters = HeuristicKit.count(text, occurrencesOfAny:
            ["seat depth", "recline lock", "tilt tension", "4d armrest", "3d armrest",
             "headrest", "adjustable armrest"])
        let comfort: (String, MetricRating)
        switch adjusters {
        case 3...: comfort = ("Good for long sessions", .good); delta += 0.1
        case 1...2: comfort = ("OK for medium sessions", .fair)
        default: comfort = ("Best for short sessions", .warning)
        }
        metrics.append(Metric(label: "Comfort", value: comfort.0, rating: comfort.1,
            note: "\(adjusters) ergonomic adjustment(s) found")); signals += 1

        // Durability — gas lift class & weight rating
        if HeuristicKit.contains(text, any: ["class 4 gas", "class 4 cylinder", "bifma"]) {
            metrics.append(Metric(label: "Durability", value: "Commercial-grade",
                rating: .good, note: "Class-4 cylinder / BIFMA tested")); delta += 0.08; signals += 1
        }
        if let cap = HeuristicKit.weightCapacityLbs(in: text) {
            metrics.append(Metric(label: "Supported Weight", value: "\(Int(cap)) lb",
                rating: cap >= 250 ? .good : .fair))
        }

        explanations.append(signals > 1
            ? "Comfort, support and durability inferred from material, lumbar type and adjustment count."
            : "Sparse ergonomic detail — insights are low confidence.")

        let confidence = min(0.8, 0.25 + Double(signals) * 0.16)
        return AnalyzerResult(category: .officeChair, metrics: metrics,
            explanations: explanations, confidence: confidence,
            categoryScoreDelta: max(-1, min(1, delta)))
    }
}
