import SwiftUI
import SwiftData

@main
struct HypeCheckApp: App {
    @State private var router = AppRouter()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([CheckRecord.self])
        let config = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppGroup.identifier))
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .onOpenURL { url in router.handleDeepLink(url) }
        }
        .modelContainer(sharedModelContainer)
    }
}
