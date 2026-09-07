import Foundation

/// Oyuncunun kalici tum verisi. Tek bir duz nesne - serilestirmesi kolay,
/// bulut kaydina tasinmasi kolay. (bkz. SaveData.kt — alanlar birebir ayni.)
final class SaveData {
    var coins: Int = 0
    /// Acilmis en yuksek bolum (1 tabanli).
    var unlockedLevel: Int = 1
    /// bolumNo -> yildiz (0..3)
    var stars: [Int: Int] = [:]
    /// bolumNo -> o bolumde yapilan deneme sayisi (yildiz kosulu icin)
    var attempts: [Int: Int] = [:]

    var unlockedCharacters: Set<String> = ["miko"]
    var unlockedChairs: Set<String> = ["chair_plastic"]
    var selectedCharacter: String = "miko"
    var selectedChair: String = "chair_plastic"

    var soundEnabled: Bool = true
    var musicEnabled: Bool = true
    var hapticEnabled: Bool = true
    /// Kolaylik modu: tolerans %35 genisler.
    var easyMode: Bool = false

    var endlessHighScore: Int = 0
    var totalSits: Int = 0
    var bestCombo: Int = 0

    /// Gunluk gorev ilerlemesi: gorevKimligi -> ilerleme
    var dailyProgress: [String: Int] = [:]
    /// Gunluk gorevlerin uretildigi gun (epoch gun sayisi).
    var dailyDay: Int64 = 0
    /// Alinmis gunluk odul gunleri.
    var dailyClaimed: Set<String> = []
    /// 7 gunluk giris serisi.
    var loginStreak: Int = 0
    var lastLoginDay: Int64 = 0

    /// IAP: odulu verilmis siparisler - ayni odul iki kez verilmesin.
    var grantedOrders: Set<String> = []
    var removeAdsPurchased: Bool = false

    var totalStars: Int { stars.values.reduce(0, +) }

    func starsFor(_ level: Int) -> Int { stars[level] ?? 0 }

    /// Yildizi yalnizca ARTIRIR - kotu bir tekrar oynama ilerlemeyi silmez.
    func recordStars(level: Int, value: Int) {
        let cur = stars[level] ?? 0
        if value > cur { stars[level] = value }
    }

    /// iOS'a ozel kural: KIBLE'deki gibi tek bir "reklamlari kaldir" urunu
    /// degil, HERHANGI bir satin alma yapilmissa gecis reklami kapanir
    /// (kullanicinin acikca istedigi davranis — bkz. InterstitialPolicy).
    var hasAnyPurchase: Bool { !grantedOrders.isEmpty }
}
