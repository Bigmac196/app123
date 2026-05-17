import SwiftUI
import SwiftData
import WorthItKit

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PurchaseManager.self) private var store
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
                                let id = latestID(outcome)
                                // Ad on every check unless premium; navigation
                                // proceeds after the ad (or immediately).
                                AdManager.shared.maybeShowInterstitial(
                                    isPremium: store.isPremium) {
                                    router.screen = .home
                                    router.path.append(.historyDetail(id))
                                }
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
