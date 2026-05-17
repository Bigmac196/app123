import SwiftUI
import SwiftData
import HypeCheckKit

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PurchaseManager.self) private var store
    @Query(sort: \CheckRecord.createdAt, order: .reverse)
    private var records: [CheckRecord]
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                VStack(alignment: .leading, spacing: 12) {
                    Label("Share a product to check it", systemImage: "square.and.arrow.up")
                        .font(.headline)
                    Text("In Safari or any shopping app, tap **Share → HypeCheck**. "
                         + "We read the page on your device and give a verdict. "
                         + "Nothing leaves your iPhone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                Button {
                    router.path.append(.manualEntry)
                } label: {
                    Label("Check a link manually", systemImage: "link")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if !store.isPremium {
                    Button {
                        showPaywall = true
                    } label: {
                        Label("Remove ads", systemImage: "nosign")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                if !records.isEmpty {
                    recentSection
                }
            }
            .padding()
        }
        .navigationTitle("HypeCheck")
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.path.append(.history) } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
            if !store.isPremium {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showPaywall = true } label: {
                        Image(systemName: "crown")
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
            Text("Is it worth it, or just hype?")
                .font(.title2).bold()
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent checks").font(.headline)
                Spacer()
                Button("See all") { router.path.append(.history) }
                    .font(.subheadline)
            }
            ForEach(records.prefix(3)) { record in
                Button {
                    router.path.append(.historyDetail(record.id))
                } label: {
                    HistoryRow(record: record)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
