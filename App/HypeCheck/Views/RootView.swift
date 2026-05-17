import SwiftUI
import SwiftData
import HypeCheckKit

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @State private var vm = AnalysisViewModel()

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            Group {
                switch router.screen {
                case .home:
                    HomeView()
                case .analyzing(let url, let text):
                    LoadingView(state: vm.state)
                        .task(id: url) {
                            await vm.run(url: url, sharedText: text, context: context)
                        }
                        .onChange(of: vm.state) { _, new in
                            if case .done(let outcome) = new {
                                router.screen = .home
                                router.path.append(.historyDetail(latestID(outcome)))
                            }
                        }
                case .result:
                    HomeView()
                }
            }
            .navigationDestination(for: AppRouter.Route.self) { route in
                switch route {
                case .history: HistoryView()
                case .historyDetail(let id): HistoryDetailView(recordID: id)
                case .manualEntry: ManualEntryView(vm: vm)
                }
            }
        }
    }

    private func latestID(_ outcome: AnalysisOutcome) -> UUID {
        let desc = FetchDescriptor<CheckRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(desc))?.first?.id ?? UUID()
    }
}
