import StoreKit

/// Gercek StoreKit 2 uygulamasi.
///
/// En buyuk risk burada: AYNI ODULUN IKI KEZ VERILMESI. Buna karsi:
///
///  1. [PurchaseGranter] her islem kimligini (`transaction.id`) kaydeder;
///     ayni islem ikinci kez odul vermez (kalici, kayit dosyasinda).
///  2. Yalnizca `.verified` (App Store'un imzasini dogrulanmis) islemler
///     islenir - `.unverified` islemler icin odul VERILMEZ.
///  3. Her islem `transaction.finish()` ile kapatilir - kapatilmayan bir
///     islem uygulama her acildiginda `Transaction.updates`'ten TEKRAR
///     gelir (StoreKit'in kendi "onaylanmamis satin alma" mekanizmasi,
///     Play'deki `acknowledge` zorunlulugunun StoreKit 2 karsiligi).
///
/// Fiyatlar koda YAZILMAZ; App Store'dan `displayPrice` olarak gelir.
/// (bkz. PlayBillingService.kt)
final class StoreKit2BillingService: BillingService {
    private let granter: PurchaseGranter

    private var storeProducts: [String: Product] = [:]
    private var owned: Set<String> = []
    private var updatesTask: Task<Void, Never>?

    init(granter: PurchaseGranter) {
        self.granter = granter
    }

    func initialize(onReady: @escaping () -> Void) {
        // Uygulama acikken gelen (orn. "Ask to Buy" onayi gecikmis) islemleri
        // dinler - kural 40: bu dinleyici kurulamasa da oyun COKMEZ, yalnizca
        // o tur islemler bir sonraki restore'a kadar bekler.
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { [weak self] in
            await self?.loadProducts()
            await self?.restoreEntitlements()
            onReady()
        }
    }

    private func loadProducts() async {
        do {
            let products = try await Product.products(for: IapProduct.all)
            var map: [String: Product] = [:]
            for p in products { map[p.id] = p }
            storeProducts = map
        } catch {
            // Urunler alinamadi (aglantisiz, App Store Connect'te henuz
            // olusturulmamis, vs.) - magaza ekrani "-" fiyat gosterir.
        }
    }

    func products() -> [BillingProduct] {
        IapProduct.all.map { id in
            let p = storeProducts[id]
            return BillingProduct(
                id: id,
                displayName: p?.displayName ?? id,
                formattedPrice: p?.displayPrice ?? "",
                consumable: IapProduct.coinAmount[id] != nil,
                owned: owned.contains(id)
            )
        }
    }

    func purchase(productId: String, onResult: @escaping (BillingStatus) -> Void) {
        guard let product = storeProducts[productId] else {
            onResult(.unavailable)
            return
        }
        if IapProduct.coinAmount[productId] == nil && owned.contains(productId) {
            onResult(.alreadyOwned)
            return
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    await self.handle(verification)
                    onResult(.ok)
                case .userCancelled:
                    onResult(.cancelled)
                case .pending:
                    // Ebeveyn onayi (Ask to Buy) gibi - odul YALNIZCA
                    // Transaction.updates'ten onay gelince verilir.
                    onResult(.cancelled)
                @unknown default:
                    onResult(.error)
                }
            } catch {
                onResult(.error)
            }
        }
    }

    /// Odulu verir, sonra islemi kapatir. Yalnizca DOGRULANMIS islemler islenir.
    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }

        // Cift odul korumasi burada (islem kimligi kalici olarak kaydedilir).
        granter.grant(productId: transaction.productID, orderId: String(transaction.id))
        if IapProduct.coinAmount[transaction.productID] == nil {
            owned.insert(transaction.productID)
        }
        await transaction.finish()
    }

    private func restoreEntitlements() async {
        for await result in Transaction.currentEntitlements {
            await handle(result)
        }
    }

    /// Acilista: kalici urunleri geri yukler, yarim kalanlari tamamlar.
    func restore(onDone: @escaping () -> Void) {
        Task { [weak self] in
            await self?.restoreEntitlements()
            onDone()
        }
    }

    func destroy() {
        updatesTask?.cancel()
        updatesTask = nil
    }
}
