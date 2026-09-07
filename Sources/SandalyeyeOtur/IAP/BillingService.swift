import os.log

/// Satin alma soyutlamasi (MONETIZATION.md bolum 3).
///
/// Fiyatlar KODA YAZILMAZ - StoreKit'ten `displayPrice` olarak gelir ve oyle
/// gosterilir. Boylece para birimi ve yerellestirme App Store'un isi olur.
/// (bkz. BillingService.kt)
protocol BillingService: AnyObject {
    func initialize(onReady: @escaping () -> Void)
    func products() -> [BillingProduct]
    func purchase(productId: String, onResult: @escaping (BillingStatus) -> Void)
    /// Acilista cagrilir: kalici urunleri geri yukler, yarim kalanlari tamamlar.
    func restore(onDone: @escaping () -> Void)
    func destroy()
}

enum BillingStatus { case ok, cancelled, error, unavailable, alreadyOwned }

struct BillingProduct {
    let id: String
    let displayName: String
    /// StoreKit'ten gelen bicimlenmis fiyat. Bos ise magaza "-" gosterir.
    let formattedPrice: String
    let consumable: Bool
    var owned: Bool = false
}

/// Urun kimlikleri ve sabit meta veri (MONETIZATION.md).
///
/// **iOS'a ozel kural (kullanicinin acikca istedigi):** coin paketlerinin
/// fiyatlari Android'den DUSUK tutulur ki insanlar daha kolay alabilsin —
/// App Store Connect'teki gercek fiyat kademeleri bu dosyada degil, App
/// Store Connect'te ayarlanir; burada yalnizca urun kimlikleri ve coin
/// miktarlari tanimlanir (fiyat App Store'dan `displayPrice` olarak gelir).
enum IapProduct {
    static let coin1000 = "coin_1000"
    static let coin5000 = "coin_5000"
    static let coin15000 = "coin_15000"
    static let coin50000 = "coin_50000"
    static let premiumSkin01 = "premium_skin_01"
    static let premiumSkin02 = "premium_skin_02"
    static let removeAds = "remove_ads"
    static let starterPack = "starter_pack"

    static let all = [
        coin1000, coin5000, coin15000, coin50000,
        premiumSkin01, premiumSkin02, removeAds, starterPack
    ]

    /// Urun -> verilecek coin. Kalici urunler icin yok.
    static let coinAmount: [String: Int] = [
        coin1000: 1000, coin5000: 5000, coin15000: 15000, coin50000: 50000,
        starterPack: 5000
    ]
}

/// Odul verme mantigi. Magaza katmanindan AYRI tutulur cunku asil risk
/// burada: ayni odulun iki kez verilmesi. (bkz. PurchaseGranter)
final class PurchaseGranter {
    private let save: SaveRepository
    private let wallet: Wallet
    private static let logger = Logger(subsystem: "com.miktat55.sitdown", category: "PurchaseGranter")

    init(save: SaveRepository, wallet: Wallet) {
        self.save = save
        self.wallet = wallet
    }

    /// - Parameter orderId: App Store'un islem kimligi. Ayni kimlik ikinci kez
    ///   gelirse odul TEKRAR VERILMEZ.
    /// - Returns: odul gercekten verildiyse true
    @discardableResult
    func grant(productId: String, orderId: String) -> Bool {
        if !orderId.isEmpty && save.data.grantedOrders.contains(orderId) {
            Self.logger.info("Siparis zaten odullendirildi: \(orderId, privacy: .public)")
            return false
        }

        if let amount = IapProduct.coinAmount[productId] { wallet.add(amount) }

        switch productId {
        case IapProduct.removeAds:
            save.data.removeAdsPurchased = true
        case IapProduct.premiumSkin01:
            save.data.unlockedCharacters.insert("alien")
        case IapProduct.premiumSkin02:
            save.data.unlockedCharacters.insert("businessman")
        case IapProduct.starterPack:
            save.data.unlockedChairs.insert("chair_gold")
            save.data.unlockedCharacters.insert("robot")
        default:
            break
        }

        if !orderId.isEmpty { save.data.grantedOrders.insert(orderId) }
        save.markDirty()
        save.flush()
        return true
    }
}

/// App Store baglantisi yokken. Magaza acilir ama satin alma "kullanilamiyor" der.
final class NoOpBillingService: BillingService {
    func initialize(onReady: @escaping () -> Void) { onReady() }

    func products() -> [BillingProduct] {
        IapProduct.all.map { BillingProduct(id: $0, displayName: $0, formattedPrice: "", consumable: IapProduct.coinAmount[$0] != nil) }
    }

    func purchase(productId: String, onResult: @escaping (BillingStatus) -> Void) {
        onResult(.unavailable)
    }

    func restore(onDone: @escaping () -> Void) { onDone() }
    func destroy() {}
}
