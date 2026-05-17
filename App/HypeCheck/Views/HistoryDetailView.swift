import SwiftUI
import SwiftData
import HypeCheckKit

struct HistoryDetailView: View {
    let recordID: UUID
    @Environment(\.modelContext) private var context

    var body: some View {
        if let outcome = fetch()?.outcome {
            ResultView(outcome: outcome)
        } else {
            ContentUnavailableView("Couldn't load this check",
                systemImage: "questionmark.folder")
        }
    }

    private func fetch() -> CheckRecord? {
        let id = recordID
        let desc = FetchDescriptor<CheckRecord>(
            predicate: #Predicate { $0.id == id })
        return try? context.fetch(desc).first
    }
}
