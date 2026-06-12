import Foundation
import StoreKit

@MainActor
@Observable
final class StoreManager {
    static let supportProductID = "com.family.catchme.support"

    private(set) var supportProduct: Product?
    private(set) var isLoadingProducts = false
    private(set) var purchaseInProgress = false
    var thankYouMessage: String?
    var errorMessage: String?

    private nonisolated(unsafe) var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            await self?.listenForTransactions()
        }
        Task { [weak self] in
            await self?.loadProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: [Self.supportProductID])
            supportProduct = products.first
        } catch {
            errorMessage = L10n.supportLoadFailed
        }
    }

    func purchaseSupport() async {
        guard let product = supportProduct else {
            errorMessage = L10n.supportProductUnavailable
            return
        }

        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                thankYouMessage = L10n.supportThankYou
            case .userCancelled:
                break
            case .pending:
                thankYouMessage = L10n.supportPending
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearThankYou() {
        thankYouMessage = nil
    }

    func clearError() {
        errorMessage = nil
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard let transaction = try? checkVerified(result) else { continue }
            await transaction.finish()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

private enum StoreError: Error {
    case failedVerification
}
