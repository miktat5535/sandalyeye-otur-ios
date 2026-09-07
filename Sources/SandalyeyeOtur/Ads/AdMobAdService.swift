import GoogleMobileAds
import UIKit
import os.log

/// Gercek AdMob uygulamasi.
///
/// TASARIM KURALLARI (MONETIZATION.md bolum 2 + Apple politikasi):
///
///  1. ODULLU reklam OPT-IN'dir. Oyuncu kendisi "izle" der, sonuna kadar izler,
///     odulu ancak kazanim geri caGrisi tetiklendiginde alir.
///  2. GECIS reklaminin kapatma dugmesini Google'in kendi render'i koyar; biz
///     sureye karisamayiz ve karismamaliyiz.
///  3. Reklam gosterilirken oyun DURUR, kapaninca kaldigi yerden devam eder.
///  4. Her sey basarisiz olabilir: internet yok, envanter yok, SDK hata verdi.
///     Hicbirinde oyun COKMEZ; geri cagri her durumda tam olarak BIR KEZ calisir.
///
/// (bkz. AdMobAdService.kt)
final class AdMobAdService: NSObject, AdService {

    private static let logger = Logger(subsystem: "com.miktat55.sitdown", category: "AdMobAdService")
    /// Bu kadar ust uste basarisizliktan sonra yuklemeyi birak.
    private static let maxFailures = 3

    private let rewardedAdUnitID: String
    private let interstitialAdUnitID: String

    private var rewardedAd: RewardedAd?
    private var interstitialAd: InterstitialAd?

    private var initialized = false
    private var rewardedLoading = false
    private var interstitialLoading = false
    private var rewardedFailures = 0
    private var interstitialFailures = 0

    private var pendingRewardResult: ((AdServiceRewardResult) -> Void)?
    private var earnedThisShow = false
    private var pendingInterstitialClosed: (() -> Void)?

    init(rewardedAdUnitID: String, interstitialAdUnitID: String) {
        self.rewardedAdUnitID = rewardedAdUnitID
        self.interstitialAdUnitID = interstitialAdUnitID
    }

    func initialize() {
        MobileAds.shared.start { [weak self] _ in
            guard let self else { return }
            self.initialized = true
            Self.logger.info("AdMob hazir")
            self.preload()
        }
    }

    private func request() -> Request { Request() }

    private func preload() {
        loadRewarded()
        loadInterstitial()
    }

    // ------------------------------------------------------------- odullu

    private func loadRewarded() {
        guard initialized, !rewardedLoading, rewardedAd == nil else { return }
        guard rewardedFailures < Self.maxFailures else { return }
        guard !rewardedAdUnitID.isEmpty else { return }

        rewardedLoading = true
        RewardedAd.load(with: rewardedAdUnitID, request: request()) { [weak self] ad, error in
            guard let self else { return }
            self.rewardedLoading = false
            if let error {
                self.rewardedAd = nil
                self.rewardedFailures += 1
                Self.logger.warning("Odullu yuklenemedi: \(error.localizedDescription, privacy: .public)")
                return
            }
            ad?.fullScreenContentDelegate = self
            self.rewardedAd = ad
            self.rewardedFailures = 0
        }
    }

    func isRewardedReady() -> Bool { rewardedAd != nil }

    func showRewarded(placement: String, onResult: @escaping (AdServiceRewardResult) -> Void) {
        guard let presenter = Services.shared.presenter, let ad = rewardedAd else {
            loadRewarded()
            onResult(.notReady)
            return
        }

        // Odul YALNIZCA kazanim geri cagrisiyla verilir. Reklam kapatilirsa,
        // hata verirse veya yarida birakilirsa odul YOKTUR.
        earnedThisShow = false
        pendingRewardResult = onResult
        ad.present(from: presenter) { [weak self] in
            self?.earnedThisShow = true
        }
    }

    // -------------------------------------------------------------- gecis

    private func loadInterstitial() {
        guard initialized, !interstitialLoading, interstitialAd == nil else { return }
        guard interstitialFailures < Self.maxFailures else { return }
        guard !interstitialAdUnitID.isEmpty else { return }

        interstitialLoading = true
        InterstitialAd.load(with: interstitialAdUnitID, request: request()) { [weak self] ad, error in
            guard let self else { return }
            self.interstitialLoading = false
            if let error {
                self.interstitialAd = nil
                self.interstitialFailures += 1
                Self.logger.warning("Gecis yuklenemedi: \(error.localizedDescription, privacy: .public)")
                return
            }
            ad?.fullScreenContentDelegate = self
            self.interstitialAd = ad
            self.interstitialFailures = 0
        }
    }

    /// Sıklık kurallarini [InterstitialPolicy] uygular; bu metot yalnizca
    /// "gosterebiliyorsam goster" der. Hazir degilse ANINDA devam eder -
    /// oyuncu reklam yuklenmesini beklemez.
    func maybeShowInterstitial(placement: String, onClosed: @escaping () -> Void) {
        guard let presenter = Services.shared.presenter, let ad = interstitialAd else {
            loadInterstitial()
            onClosed()
            return
        }
        pendingInterstitialClosed = onClosed
        ad.present(from: presenter)
    }

    func onLevelCompleted() {
        // Bir sonraki gosterim icin stok tazele.
        loadRewarded()
        loadInterstitial()
    }

    func destroy() {
        rewardedAd = nil
        interstitialAd = nil
        pendingRewardResult = nil
        pendingInterstitialClosed = nil
    }
}

extension AdMobAdService: FullScreenContentDelegate {
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Self.logger.warning("Tam ekran gosterilemedi: \(error.localizedDescription, privacy: .public)")
        if ad === rewardedAd {
            rewardedAd = nil
            loadRewarded()
            let cb = pendingRewardResult
            pendingRewardResult = nil
            cb?(.failed)
        } else if ad === interstitialAd {
            interstitialAd = nil
            loadInterstitial()
            let cb = pendingInterstitialClosed
            pendingInterstitialClosed = nil
            cb?()
        }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if ad === rewardedAd {
            rewardedAd = nil
            loadRewarded()
            let cb = pendingRewardResult
            pendingRewardResult = nil
            cb?(earnedThisShow ? .earned : .dismissed)
        } else if ad === interstitialAd {
            interstitialAd = nil
            loadInterstitial()
            let cb = pendingInterstitialClosed
            pendingInterstitialClosed = nil
            cb?()
        }
    }
}
