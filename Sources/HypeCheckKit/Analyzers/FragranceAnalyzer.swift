import Foundation

public struct FragranceAnalyzer: ProductAnalyzer {
    public let category: ProductCategory = .fragrance
    public init() {}

    public func analyze(_ product: ProductData) -> AnalyzerResult {
        let text = product.searchableText
        var metrics: [Metric] = []
        var explanations: [String] = []
        var delta = 0.0
        var signalCount = 0

        // Concentration → longevity / projection -------------------------
        let (longevity, projection, sillage, concNote): (String, String, String, String)
        if HeuristicKit.contains(text, any: ["parfum extrait", "extrait de parfum", "pure parfum"]) {
            longevity = "Very long (8h+)"; projection = "Moderate"; sillage = "Intimate–moderate"
            concNote = "Extrait concentration"; signalCount += 1; delta += 0.15
        } else if HeuristicKit.contains(text, any: ["eau de parfum", "edp"]) {
            longevity = "Long (6–8h)"; projection = "Moderate–strong"; sillage = "Moderate"
            concNote = "Eau de Parfum"; signalCount += 1; delta += 0.1
        } else if HeuristicKit.contains(text, any: ["eau de toilette", "edt"]) {
            longevity = "Medium (3–5h)"; projection = "Soft–moderate"; sillage = "Soft"
            concNote = "Eau de Toilette"; signalCount += 1
        } else if HeuristicKit.contains(text, any: ["eau de cologne", "eau fraiche", "cologne"]) {
            longevity = "Short (2–3h)"; projection = "Soft"; sillage = "Skin-scent"
            concNote = "Cologne / light concentration"; signalCount += 1
        } else {
            longevity = "Unknown"; projection = "Unknown"; sillage = "Unknown"
            concNote = "Concentration not stated"
        }
        metrics.append(Metric(label: "Longevity", value: longevity,
            rating: longevity.contains("Long") ? .good : (longevity == "Unknown" ? .neutral : .fair),
            note: concNote))
        metrics.append(Metric(label: "Projection", value: projection,
            rating: projection == "Unknown" ? .neutral : .neutral))
        metrics.append(Metric(label: "Sillage", value: sillage, rating: .neutral))

        // Note / family inference ---------------------------------------
        let families: [(String, [String])] = [
            ("Woody / Oriental", ["oud", "sandalwood", "cedar", "patchouli", "leather", "amber"]),
            ("Fresh / Citrus", ["bergamot", "citrus", "lemon", "neroli", "aquatic", "marine", "mint"]),
            ("Gourmand", ["vanilla", "tonka", "caramel", "chocolate", "praline", "honey"]),
            ("Floral", ["rose", "jasmine", "iris", "tuberose", "peony", "lily"]),
            ("Spicy", ["cardamom", "cinnamon", "pepper", "saffron", "clove"])
        ]
        let scored = families.map { ($0.0, HeuristicKit.count(text, occurrencesOfAny: $0.1)) }
        if let top = scored.max(by: { $0.1 < $1.1 }), top.1 > 0 {
            metrics.append(Metric(label: "Fragrance Family", value: top.0,
                rating: .neutral, note: "Inferred from listed notes"))
            signalCount += 1
            let season: String
            switch top.0 {
            case "Fresh / Citrus": season = "Summer / warm weather"
            case "Woody / Oriental", "Gourmand", "Spicy": season = "Fall / winter"
            default: season = "All-season"
            }
            metrics.append(Metric(label: "Seasonality", value: season, rating: .neutral))
            metrics.append(Metric(label: "Scent Profile", value: top.0,
                rating: .neutral))
        } else {
            explanations.append("No note breakdown found — scent profile could not be inferred.")
        }

        // Longevity boosters
        if HeuristicKit.contains(text, any: ["musk", "amber", "oud", "vanilla", "resin"]) {
            explanations.append("Heavy base notes (musk/amber/oud) typically extend longevity and sillage.")
            delta += 0.05
        }

        if signalCount == 0 {
            explanations.append("Listing lacks fragrance-specific detail; treat insights as low confidence.")
        } else {
            explanations.append("Insights estimated from concentration and note structure in the listing.")
        }

        let confidence = min(0.85, 0.3 + Double(signalCount) * 0.2)
        return AnalyzerResult(category: .fragrance, metrics: metrics,
            explanations: explanations, confidence: confidence,
            categoryScoreDelta: max(-1, min(1, delta)))
    }
}
