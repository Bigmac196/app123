import Foundation

public struct SkincareAnalyzer: ProductAnalyzer {
    public let category: ProductCategory = .skincare
    public init() {}

    public func analyze(_ product: ProductData) -> AnalyzerResult {
        let text = product.searchableText
        var metrics: [Metric] = []
        var explanations: [String] = []
        var delta = 0.0
        var signals = 0

        // Irritation risk
        let irritants = ["fragrance", "parfum", "denatured alcohol", "alcohol denat",
                         "essential oil", "menthol", "witch hazel"]
        let irritantHits = HeuristicKit.count(text, occurrencesOfAny: irritants)
        let strongActive = HeuristicKit.contains(text, any:
            ["retinol", "glycolic acid", "salicylic acid", "aha", "bha", "tretinoin"])
        let risk: (String, MetricRating)
        switch (irritantHits, strongActive) {
        case (let n, true) where n >= 1: risk = ("Elevated", .warning); delta -= 0.12
        case (_, true): risk = ("Moderate (active ingredients)", .fair)
        case (let n, _) where n >= 2: risk = ("Moderate (fragrance/alcohol)", .fair); delta -= 0.06
        default: risk = ("Low", .good); delta += 0.06
        }
        metrics.append(Metric(label: "Irritation Risk", value: risk.0, rating: risk.1))
        signals += 1

        // Beneficial actives
        let good = ["niacinamide", "ceramide", "hyaluronic acid", "peptide",
                    "panthenol", "squalane", "centella", "vitamin c", "spf"]
        let goodHits = HeuristicKit.count(text, occurrencesOfAny: good)
        if goodHits > 0 {
            metrics.append(Metric(label: "Ingredient Quality",
                value: "\(goodHits) proven active(s)", rating: goodHits >= 2 ? .good : .fair,
                note: "Niacinamide / ceramide / HA / peptide etc."))
            delta += min(0.12, Double(goodHits) * 0.04); signals += 1
        } else {
            metrics.append(Metric(label: "Ingredient Quality",
                value: "No headline actives found", rating: .fair))
        }

        // Skin-type suitability
        let suitability: String
        if HeuristicKit.contains(text, any: ["oily", "acne", "mattifying", "oil control"]) {
            suitability = "Oily / acne-prone"
        } else if HeuristicKit.contains(text, any: ["dry", "rich", "nourishing", "barrier repair"]) {
            suitability = "Dry / dehydrated"
        } else if HeuristicKit.contains(text, any: ["sensitive", "fragrance-free", "gentle", "soothing"]) {
            suitability = "Sensitive"
        } else {
            suitability = "All / normal skin"
        }
        metrics.append(Metric(label: "Skin Type", value: suitability, rating: .neutral))

        // Value per oz
        if let price = HeuristicKit.double(product.price),
           let oz = HeuristicKit.fluidOunces(in: text), oz > 0 {
            let perOz = price / oz
            let r: MetricRating = perOz <= 8 ? .good : (perOz <= 25 ? .fair : .warning)
            metrics.append(Metric(label: "Value", value: String(format: "$%.2f / fl oz", perOz),
                rating: r))
            if perOz > 40 { delta -= 0.08
                explanations.append("Premium price per ounce — common with hyped 'viral' skincare.") }
            signals += 1
        }

        explanations.append(signals > 1
            ? "Irritation risk and quality inferred from listed ingredients."
            : "Ingredient list not detailed — insights are low confidence.")
        explanations.append("Not medical advice — patch test and consult a dermatologist for skin concerns.")

        let confidence = min(0.8, 0.25 + Double(signals) * 0.16)
        return AnalyzerResult(category: .skincare, metrics: metrics,
            explanations: explanations, confidence: confidence,
            categoryScoreDelta: max(-1, min(1, delta)))
    }
}
