import SwiftUI
import SwiftData

@main
struct HypeCheckApp: App {
    @State private var router = AppRouter()
    @State private var purchaseManager = PurchaseManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([CheckRecord.self])
        let config = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppGroup.identifier))
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(purchaseManager)
                .onOpenURL { url in router.handleDeepLink(url) }
                .task {
                    AdManager.shared.start()
                    // ATT must be requested while the app is active.
                    try? await Task.sleep(for: .seconds(1))
                    AdManager.shared.requestTrackingAuthorizationIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
