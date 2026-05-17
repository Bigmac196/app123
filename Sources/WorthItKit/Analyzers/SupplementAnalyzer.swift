import Foundation

public struct SupplementAnalyzer: ProductAnalyzer {
    public let category: ProductCategory = .supplement
    public init() {}

    public func analyze(_ product: ProductData) -> AnalyzerResult {
        let text = product.searchableText
        var metrics: [Metric] = []
        var explanations: [String] = []
        var delta = 0.0
        var signals = 0

        if HeuristicKit.contains(text, any: ["proprietary blend", "proprietary formula"]) {
            metrics.append(Metric(label: "Dosage Transparency", value: "Hidden (proprietary blend)",
                rating: .warning, note: "Per-ingredient amounts not disclosed"))
            delta -= 0.15; signals += 1
            explanations.append("Proprietary blends hide actual doses — a value/efficacy red flag.")
        } else if HeuristicKit.contains(text, any: ["per serving", "mg", "mcg", "iu"]) {
            metrics.append(Metric(label: "Dosage Transparency", value: "Disclosed",
                rating: .good)); delta += 0.08; signals += 1
        }

        if HeuristicKit.contains(text, any: ["nsf certified", "informed sport", "informed choice",
                                             "third-party tested", "usp verified"]) {
            metrics.append(Metric(label: "Third-Party Testing", value: "Certified",
                rating: .good, note: "NSF / Informed Sport / USP")); delta += 0.12; signals += 1
        } else {
            metrics.append(Metric(label: "Third-Party Testing", value: "Not stated",
                rating: .fair))
        }

        let hype = HeuristicKit.count(text, occurrencesOfAny:
            ["miracle", "detox", "clinically proven", "doctor recommended",
             "guaranteed results", "burn fat", "cure"])
        if hype >= 2 {
            metrics.append(Metric(label: "Marketing Claims", value: "Overhyped",
                rating: .warning, note: "Multiple unsubstantiated claims"))
            delta -= 0.12
            explanations.append("Heavy unsubstantiated claims (\(hype)) — typical of low-quality supplements.")
            signals += 1
        }

        if let price = HeuristicKit.double(product.price),
           let servings = HeuristicKit.number(in: text, near: ["servings", "capsules", "count", "doses"]),
           servings > 0 {
            let perServing = price / servings
            metrics.append(Metric(label: "Value", value: String(format: "$%.2f / serving", perServing),
                rating: perServing <= 1 ? .good : (perServing <= 2.5 ? .fair : .warning)))
            signals += 1
        }

        explanations.append("Not medical advice — consult a healthcare professional before use.")
        let confidence = min(0.78, 0.25 + Double(signals) * 0.15)
        return AnalyzerResult(category: .supplement, metrics: metrics,
            explanations: explanations, confidence: confidence,
            categoryScoreDelta: max(-1, min(1, delta)))
    }
}
