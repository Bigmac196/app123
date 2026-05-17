import Foundation

public enum AnalysisError: Error, LocalizedError {
    case fetch(FetchError)
    case unparseable

    public var errorDescription: String? {
        switch self {
        case .fetch(let e): return e.errorDescription
        case .unparseable:
            return "Couldn't read product details from this page. Try entering them manually."
        }
    }
}

/// Orchestrates the full pipeline:
/// fetch → parse → classify → analyze → score → outcome.
public struct AnalysisCoordinator: Sendable {
    private let fetcher: PageFetcher
    private let parser: ProductParser
    private let classifier: CategoryClassifier
    private let registry: AnalyzerRegistry
    private let engine: ScoringEngine

    public init(fetcher: PageFetcher = PageFetcher(),
                parser: ProductParser = ProductParser(),
                classifier: CategoryClassifier = CategoryClassifier(),
                registry: AnalyzerRegistry = AnalyzerRegistry(),
                engine: ScoringEngine = ScoringEngine()) {
        self.fetcher = fetcher
        self.parser = parser
        self.classifier = classifier
        self.registry = registry
        self.engine = engine
    }

    /// Full run from a URL (downloads the page).
    public func analyze(url: URL, sharedPageText: String? = nil) async throws -> AnalysisOutcome {
        let html: String
        do {
            html = try await fetcher.fetchHTML(from: url)
        } catch let e as FetchError {
            // Fall back to shared page text if the fetch was blocked.
            if let shared = sharedPageText, !shared.isEmpty {
                return analyze(product: parser.parse(
                    html: "", url: url, sharedPageText: shared))
            }
            throw AnalysisError.fetch(e)
        }
        let product = parser.parse(html: html, url: url,
                                   sharedPageText: sharedPageText)
        guard !product.title.isEmpty || product.price != nil else {
            throw AnalysisError.unparseable
        }
        return analyze(product: product)
    }

    /// Score an already-parsed (or manually-entered) product.
    public func analyze(product: ProductData) -> AnalysisOutcome {
        let (category, classifierConfidence) = classifier.classify(product)
        let analyzer = registry.analyzer(for: category).analyze(product)
        let parseQuality = ParseQuality(product: product)
        let breakdown = engine.score(
            product: product, category: category, analyzer: analyzer,
            parseQuality: parseQuality, classifierConfidence: classifierConfidence)
        return AnalysisOutcome(product: product, category: category,
                               analyzer: analyzer, breakdown: breakdown)
    }
}
