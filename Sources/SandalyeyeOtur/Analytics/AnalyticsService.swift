import os.log

/// Analytics soyutlamasi.
///
/// Saglayici gameplay koduna BAGLANMAZ. Oyun yalnizca bu protokolu cagirir;
/// Firebase/baska bir saglayici eklenirse tek bir uygulama sinifi yazilir,
/// oynanis kodu degismez. (bkz. AnalyticsService.kt)
protocol AnalyticsService {
    func event(_ name: String, _ params: [String: Any])
}

extension AnalyticsService {
    func event(_ name: String) { event(name, [:]) }
}

enum AnalyticsEvent {
    // GAME_DESIGN + brief bolum 26'daki event listesi
    static let levelStarted = "level_started"
    static let levelCompleted = "level_completed"
    static let levelFailed = "level_failed"
    static let rewardedAdStarted = "rewarded_ad_started"
    static let rewardedAdCompleted = "rewarded_ad_completed"
    static let shopOpened = "shop_opened"
    static let purchaseStarted = "purchase_started"
    static let purchaseCompleted = "purchase_completed"
    static let skinUnlocked = "skin_unlocked"
    static let dailyRewardClaimed = "daily_reward_claimed"
    static let endlessStarted = "endless_started"
    static let endlessFinished = "endless_finished"
}

/// Gelistirme sirasinda: unified log'a yazar.
final class LogAnalyticsService: AnalyticsService {
    private static let logger = Logger(subsystem: "com.miktat55.sitdown", category: "Analytics")
    func event(_ name: String, _ params: [String: Any]) {
        if params.isEmpty {
            Self.logger.debug("\(name, privacy: .public)")
        } else {
            Self.logger.debug("\(name, privacy: .public)  \(String(describing: params), privacy: .public)")
        }
    }
}

/// Saglayici yokken / kullanici izni yokken.
final class NoOpAnalyticsService: AnalyticsService {
    func event(_ name: String, _ params: [String: Any]) {}
}
