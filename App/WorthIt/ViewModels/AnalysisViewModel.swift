import SwiftUI
import SwiftData
import Observation
import WorthItKit

@Observable
@MainActor
final class AnalysisViewModel {
    enum State: Equatable {
        case idle
        case fetching
        case reading
        case scoring
        case done(AnalysisOutcome)
        case failed(String, canRetryManually: Bool)
    }

    private(set) var state: State = .idle

    private let coordinator = AnalysisCoordinator(
        parser: ProductParser(extractor: SwiftSoupHTMLExtractor()))

    func run(url: URL, sharedText: String?, context: ModelContext) async {
        state = .fetching
        do {
            try await Task.sleep(for: .milliseconds(150))
            state = .reading
            let outcome = try await coordinator.analyze(
                url: url, sharedPageText: sharedText)
            state = .scoring
            try? await Task.sleep(for: .milliseconds(150))
            persist(outcome, context: context)
            state = .done(outcome)
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
            state = .failed(msg, canRetryManually: true)
        }
    }

    func runManual(_ product: ProductData, context: ModelContext) {
        let outcome = coordinator.analyze(product: product)
        persist(outcome, context: context)
        state = .done(outcome)
    }

    private func persist(_ outcome: AnalysisOutcome, context: ModelContext) {
        context.insert(CheckRecord(outcome: outcome))
        try? context.save()
    }
}
