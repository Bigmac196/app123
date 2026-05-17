import SwiftUI
import Observation

@Observable
final class AppRouter {
    enum Screen: Equatable {
        case home
        case analyzing(url: URL, sharedText: String?)
        case result(AnalysisOutcomeID)
    }

    var screen: Screen = .home
    var path: [Route] = []

    enum Route: Hashable {
        case history
        case historyDetail(UUID)
        case manualEntry
    }

    /// hypecheck://analyze?id=<uuid>  (pending record written by the extension)
    /// hypecheck://analyze?url=<encoded url>
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "hypecheck",
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return }
        let items = comps.queryItems ?? []
        if let urlStr = items.first(where: { $0.name == "url" })?.value,
           let target = URL(string: urlStr) {
            screen = .analyzing(url: target, sharedText: nil)
        } else if let idStr = items.first(where: { $0.name == "id" })?.value,
                  let id = UUID(uuidString: idStr),
                  let pending = SharedStore.shared.takePending(id: id) {
            screen = .analyzing(url: pending.url, sharedText: pending.pageText)
        }
    }
}

/// Wrapper so an outcome can ride in navigation state.
struct AnalysisOutcomeID: Equatable, Hashable {
    let id: UUID
}
