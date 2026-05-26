import Foundation
import StoreKit
import SwiftUI

@MainActor
final class StoreKitManager: ObservableObject {

    // MARK: - Published state

    @Published private(set) var proMonthly: Product?
    @Published private(set) var proYearly: Product?
    @Published private(set) var currentTier: AppTier = .free
    @Published private(set) var isLoading = false
    @Published private(set) var purchaseError: String?

    // MARK: - Product identifiers

    /// Update these to match your App Store Connect product IDs.
    static let monthlyID = "com.capy.interfaceforge.pro.monthly"
    static let yearlyID  = "com.capy.interfaceforge.pro.yearly"

    private static let productIDs: Set<String> = [monthlyID, yearlyID]

    private var transactionListener: Task<Void, Never>?

    // MARK: - Lifecycle

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts(); await refreshEntitlement() }
    }

    deinit { transactionListener?.cancel() }

    // MARK: - Load products

    func loadProducts() async {
        do {
            let products = try await Product.products(for: Self.productIDs)
            for product in products {
                switch product.id {
                case Self.monthlyID: proMonthly = product
                case Self.yearlyID:  proYearly = product
                default: break
                }
            }
        } catch {
            purchaseError = "Couldn't load subscription options: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isLoading = true
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlement()
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        purchaseError = nil
        try? await AppStore.sync()
        await refreshEntitlement()
        if currentTier == .free {
            purchaseError = "No active subscription found."
        }
        isLoading = false
    }

    // MARK: - Entitlement

    var isPro: Bool { currentTier == .pro }

    func refreshEntitlement() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               Self.productIDs.contains(transaction.productID) {
                entitled = true
                break
            }
        }
        currentTier = entitled ? .pro : .free
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let safe):       return safe
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    await self?.refreshEntitlement()
                }
            }
        }
    }
}
