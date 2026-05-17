import Foundation
import StoreKit
import Observation

/// On-device entitlement manager (StoreKit 2 — no backend, no receipt server).
/// Premium = an active subscription OR the one-time lifetime unlock. Either
/// removes all ads.
@Observable
@MainActor
final class PurchaseManager {

    enum ProductID {
        static let lifetime = "com.hypecheck.app.adfree.lifetime"   // non-consumable
        static let yearly   = "com.hypecheck.app.adfree.yearly"     // auto-renewable
        static let monthly  = "com.hypecheck.app.adfree.monthly"    // auto-renewable
        static let all: Set<String> = [lifetime, yearly, monthly]
    }

    private(set) var products: [Product] = []
    private(set) var isPremium = false
    private(set) var isLoading = false
    var lastError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit { updatesTask?.cancel() }

    var lifetimeProduct: Product? { products.first { $0.id == ProductID.lifetime } }
    var subscriptionProducts: [Product] {
        products
            .filter { $0.id == ProductID.yearly || $0.id == ProductID.monthly }
            .sorted { $0.price < $1.price }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: ProductID.all)
        } catch {
            lastError = "Couldn't load products: \(error.localizedDescription)"
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = "Restore failed: \(error.localizedDescription)"
        }
    }

    /// `Transaction.currentEntitlements` already excludes expired/refunded
    /// items, so simply checking membership is sufficient — no expiry math.
    func refreshEntitlements() async {
        var premium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               ProductID.all.contains(transaction.productID),
               transaction.revocationDate == nil {
                premium = true
            }
        }
        isPremium = premium
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}
