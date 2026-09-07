import UIKit

/// Oyunun tum servislerini tutan tek nokta.
///
/// Ekranlar buradan alir; kimse kendi basina bir servis kurmaz. Bu sayede
/// bir servisin somut uygulamasini degistirmek (NoOp -> AdMob/StoreKit) TEK
/// satirdir. (bkz. Services.kt)
///
/// **Gecici durum:** `ads`/`billing` su an NoOp — gercek AdMob/StoreKit 2
/// entegrasyonu ayri bir asamada eklenecek (Android'deki NoOpAdService'in
/// PHASE 9'da AdMobAdService'e degismesiyle ayni desen). Oynanis kodu bu
/// degisiklikten ETKILENMEZ, sadece bu dosyadaki iki satir degisir.
final class Services {
    static let shared = Services()

    let save: SaveRepository
    let levels: LevelRepository
    let wallet: Wallet
    let sound: SoundBank
    let music: Music
    let haptics: Haptics
    let daily: Daily

    private(set) var ads: AdService = NoOpAdService()
    private(set) var billing: BillingService = NoOpBillingService()
    let adPolicy: InterstitialPolicy
    let granter: PurchaseGranter
    #if DEBUG
    let analytics: AnalyticsService = LogAnalyticsService()
    #else
    let analytics: AnalyticsService = NoOpAnalyticsService()
    #endif

    private init() {
        let save = SaveRepository(store: LocalSaveStore())
        save.load()
        self.save = save

        let levels = LevelRepository()
        levels.load()
        self.levels = levels

        wallet = Wallet(save: save)
        sound = SoundBank(save: save)
        music = Music(save: save)
        haptics = Haptics(save: save)
        adPolicy = InterstitialPolicy(save: save)
        granter = PurchaseGranter(save: save, wallet: wallet)
        daily = Daily(save: save, wallet: wallet)
        daily.refreshIfNeeded()
    }

    /// Magaza ve odullu reklam icin gecerli bir sunum denetleyicisi gerekir.
    private(set) weak var presenter: UIViewController?

    func onAppLaunched(presenter: UIViewController) {
        self.presenter = presenter
        ads.initialize()
        billing.initialize { [weak self] in self?.billing.restore {} }
        music.start()
    }

    /// Gecis reklami: sıklık kurallari saglaniyorsa goster, degilse aninda devam.
    func maybeShowInterstitial(placement: String, onClosed: @escaping () -> Void) {
        guard adPolicy.canShow() else { onClosed(); return }
        adPolicy.onInterstitialShown()
        ads.maybeShowInterstitial(placement: placement, onClosed: onClosed)
    }

    /// Odullu reklam: odul YALNIZCA earned sonucunda verilir.
    func showRewarded(placement: String, onResult: @escaping (AdServiceRewardResult) -> Void) {
        adPolicy.onRewardedShown()
        analytics.event(AnalyticsEvent.rewardedAdStarted, ["placement": placement])
        ads.showRewarded(placement: placement) { [weak self] result in
            if result == .earned {
                self?.analytics.event(AnalyticsEvent.rewardedAdCompleted, ["placement": placement])
            }
            onResult(result)
        }
    }

    func onAppForeground() {
        music.syncWithSettings()
    }

    func tick(_ dt: CGFloat) {
        save.tick(TimeInterval(dt))
        adPolicy.tick(dt)
    }

    func onAppBackground() {
        save.flush()
        music.pause()
    }
}
