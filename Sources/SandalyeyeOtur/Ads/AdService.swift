import CoreGraphics
import os.log

/// Reklam soyutlamasi.
///
/// SDK gameplay koduna GOMULMEZ. Oynanis yalnizca bu protokolu bilir.
/// Gercek uygulama `AdMobAdService`dir; oyun tarafinda tek satir degismez.
/// (bkz. AdService.kt)
protocol AdService: AnyObject {
    func initialize()
    func isRewardedReady() -> Bool
    func showRewarded(placement: String, onResult: @escaping (AdServiceRewardResult) -> Void)
    func maybeShowInterstitial(placement: String, onClosed: @escaping () -> Void)
    /// Sıklık sayacini besler.
    func onLevelCompleted()
    func destroy()
}

/// Swift protokolleri somut nested tip tanimlayamadigi icin (Kotlin'deki
/// `interface AdService { enum class RewardResult }` karsiligi) ust duzeyde
/// ayri bir tip olarak tanimlanir.
enum AdServiceRewardResult { case earned, dismissed, failed, notReady }

/// Yerlesim kimlikleri - MONETIZATION.md bolum 2.
enum AdPlacement {
    static let failContinue = "fail_continue"
    static let levelDouble = "level_double"
    static let dailyBoost = "daily_boost"
}

/// Interstitial sıklık kurallari - MONETIZATION.md bolum 2.
///
/// Ayri bir sinif olmasinin sebebi: bu kurallar en cok degisen seydir
/// (A/B testi, magaza puani dususu vs). Tek dosyada durur, gameplay'e sizmaz.
///
/// **iOS'a ozel sapma (kullanicinin acikca istedigi kural):** Android'de
/// yalnizca `remove_ads` urunu gecis reklamini kapatir; iOS'ta HERHANGI bir
/// satin alma (`save.data.hasAnyPurchase`) yeterlidir — bkz. SaveData.swift.
final class InterstitialPolicy {
    private let save: SaveRepository

    init(save: SaveRepository) { self.save = save }

    private var levelsSinceAd = 0
    private var secondsSinceAd: CGFloat = 999
    private var levelsPlayedTotal = 0
    private var justShowedRewarded = false

    func tick(_ dt: CGFloat) {
        secondsSinceAd += dt
    }

    func onLevelCompleted() {
        levelsSinceAd += 1
        levelsPlayedTotal += 1
    }

    func onRewardedShown() {
        justShowedRewarded = true
    }

    func onInterstitialShown() {
        levelsSinceAd = 0
        secondsSinceAd = 0
        justShowedRewarded = false
    }

    /// Kosullarin HEPSI saglanmadan reklam gosterilmez.
    func canShow() -> Bool {
        if save.data.hasAnyPurchase { return false }             // iOS'a ozel kural
        if levelsPlayedTotal < Self.firstSessionGrace { return false }
        if levelsSinceAd < Self.minLevels { return false }
        if secondsSinceAd < Self.minSeconds { return false }
        if justShowedRewarded { return false }
        return true
    }

    static let minLevels = 3
    static let minSeconds: CGFloat = 120
    static let firstSessionGrace = 5
}

/// Reklam yokken kullanilan uygulama: internet yok, SDK hatasi, test.
/// Her sey basarisiz doner ama HICBIR SEY COKMEZ ve oyun akmaya devam eder.
final class NoOpAdService: AdService {
    private static let logger = Logger(subsystem: "com.miktat55.sitdown", category: "NoOpAdService")

    func initialize() {
        Self.logger.info("Reklam servisi kapali (NoOp)")
    }

    func isRewardedReady() -> Bool { false }

    func showRewarded(placement: String, onResult: @escaping (AdServiceRewardResult) -> Void) {
        onResult(.notReady)
    }

    func maybeShowInterstitial(placement: String, onClosed: @escaping () -> Void) {
        onClosed()
    }

    func onLevelCompleted() {}
    func destroy() {}
}
