import Foundation

public protocol ProductAnalyzer: Sendable {
    var category: ProductCategory { get }
    func analyze(_ product: ProductData) -> AnalyzerResult
}

/// Resolves a category to its analyzer, falling back to `GenericAnalyzer`.
public struct AnalyzerRegistry: Sendable {
    private let analyzers: [ProductCategory: any ProductAnalyzer]
    private let fallback: any ProductAnalyzer

    public init(analyzers: [any ProductAnalyzer] = AnalyzerRegistry.defaultAnalyzers,
                fallback: any ProductAnalyzer = GenericAnalyzer()) {
        var map: [ProductCategory: any ProductAnalyzer] = [:]
        for a in analyzers { map[a.category] = a }
        self.analyzers = map
        self.fallback = fallback
    }

    public func analyzer(for category: ProductCategory) -> any ProductAnalyzer {
        analyzers[category] ?? fallback
    }

    public static let defaultAnalyzers: [any ProductAnalyzer] = [
        FragranceAnalyzer(),
        DeskAnalyzer(),
        ChairAnalyzer(),
        HeadphonesAnalyzer(),
        SkincareAnalyzer(),
        ClothingAnalyzer(),
        SupplementAnalyzer(),
        PowerBankAnalyzer(),
        KitchenApplianceAnalyzer(),
        LEDLightingAnalyzer()
    ]
}
