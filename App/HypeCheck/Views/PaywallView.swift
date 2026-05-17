import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PurchaseManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.isPremium {
                    premiumActive
                } else {
                    offers
                }
            }
            .navigationTitle("Remove Ads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Restore") { Task { await store.restore() } }
                }
            }
        }
    }

    private var premiumActive: some View {
        ContentUnavailableView {
            Label("You're Premium", systemImage: "checkmark.seal.fill")
        } description: {
            Text("Ads are off. Thanks for supporting HypeCheck!")
        }
    }

    private var offers: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Image(systemName: "nosign")
                        .font(.system(size: 44)).foregroundStyle(.tint)
                    Text("Go ad-free")
                        .font(.title2.bold())
                    Text("Every check currently shows an ad. Upgrade to skip them. "
                         + "Analysis always stays 100% on your device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                if store.isLoading {
                    ProgressView().padding()
                }

                if let lifetime = store.lifetimeProduct {
                    productCard(lifetime,
                                tagline: "One-time purchase · yours forever",
                                highlighted: true)
                }

                if !store.subscriptionProducts.isEmpty {
                    Text("Or subscribe").font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(store.subscriptionProducts, id: \.id) { p in
                        productCard(p, tagline: subscriptionTagline(p),
                                    highlighted: false)
                    }
                }

                if let err = store.lastError {
                    Text(err).font(.caption).foregroundStyle(.red)
                }

                Text("Subscriptions auto-renew until cancelled in Settings. "
                     + "The one-time unlock never expires.")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    private func productCard(_ product: Product,
                             tagline: String,
                             highlighted: Bool) -> some View {
        Button {
            Task { await store.purchase(product) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.displayName).font(.headline)
                    Text(tagline).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline.monospacedDigit())
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(highlighted ? AnyShapeStyle(.tint.opacity(0.15))
                                      : AnyShapeStyle(.ultraThinMaterial)))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.tint, lineWidth: highlighted ? 1.5 : 0))
        }
        .buttonStyle(.plain)
    }

    private func subscriptionTagline(_ p: Product) -> String {
        guard let period = p.subscription?.subscriptionPeriod else {
            return "Auto-renewing"
        }
        switch period.unit {
        case .year: return "Billed yearly · best value"
        case .month: return "Billed monthly"
        case .week: return "Billed weekly"
        case .day: return "Billed daily"
        @unknown default: return "Auto-renewing"
        }
    }
}
