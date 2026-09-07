import Foundation
import os.log

/// Kayit soyutlamasi. Oyun kodu yalnizca bunu bilir.
/// Ileride bulut kaydi eklenirse `SaveStore` protokolune ikinci bir uygulama
/// yazilir; oyun tarafinda tek satir degismez. (bkz. SaveRepository.kt)
protocol SaveStore {
    func read() -> String?
    func write(_ json: String)
}

/// UserDefaults uzerinde tek bir JSON metni tutar (Android'deki
/// SharedPreferences karsiligi).
final class LocalSaveStore: SaveStore {
    /// Android AndroidManifest'teki yedekleme kurallariyla ayni isim.
    static let suiteFile = "sitdown_save"
    private static let key = "data"

    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: Self.suiteFile) ?? .standard
    }

    func read() -> String? { defaults.string(forKey: Self.key) }

    func write(_ json: String) {
        defaults.set(json, forKey: Self.key)
    }
}

final class SaveRepository {

    private let store: SaveStore
    private static let logger = Logger(subsystem: "com.miktat55.sitdown", category: "SaveRepository")
    private static let writeInterval: TimeInterval = 1.0

    private(set) var data = SaveData()
    /// Kayit bozuksa true olur; oyun yeni kayitla devam eder.
    private(set) var wasCorrupt = false

    private var dirty = false
    private var sinceLastWrite: TimeInterval = 0

    init(store: SaveStore) {
        self.store = store
    }

    func load() {
        guard let text = store.read(), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            data = SaveData()
            return
        }
        do {
            guard let json = try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any] else {
                throw NSError(domain: "SaveRepository", code: 1)
            }
            data = Self.fromJSON(json)
        } catch {
            // Kural 40: bozuk kayit dosyasi uygulamayi COKERTMEZ.
            Self.logger.error("Kayit bozuk, sifirlaniyor: \(error.localizedDescription, privacy: .public)")
            wasCorrupt = true
            data = SaveData()
        }
    }

    func markDirty() { dirty = true }

    /// Her karede degil, en fazla saniyede bir diske yazar.
    func tick(_ dt: TimeInterval) {
        guard dirty else { return }
        sinceLastWrite += dt
        if sinceLastWrite >= Self.writeInterval { flush() }
    }

    func flush() {
        guard dirty else { return }
        do {
            let json = try Self.toJSON(data)
            let bytes = try JSONSerialization.data(withJSONObject: json)
            guard let text = String(data: bytes, encoding: .utf8) else { return }
            store.write(text)
            dirty = false
            sinceLastWrite = 0
        } catch {
            Self.logger.error("Kayit yazilamadi: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - JSON

    private static func toJSON(_ d: SaveData) -> [String: Any] {
        var stars: [String: Int] = [:]
        for (k, v) in d.stars { stars[String(k)] = v }
        var attempts: [String: Int] = [:]
        for (k, v) in d.attempts { attempts[String(k)] = v }

        return [
            "coins": d.coins,
            "unlockedLevel": d.unlockedLevel,
            "stars": stars,
            "attempts": attempts,
            "unlockedCharacters": Array(d.unlockedCharacters),
            "unlockedChairs": Array(d.unlockedChairs),
            "selectedCharacter": d.selectedCharacter,
            "selectedChair": d.selectedChair,
            "soundEnabled": d.soundEnabled,
            "musicEnabled": d.musicEnabled,
            "hapticEnabled": d.hapticEnabled,
            "easyMode": d.easyMode,
            "endlessHighScore": d.endlessHighScore,
            "totalSits": d.totalSits,
            "bestCombo": d.bestCombo,
            "dailyProgress": d.dailyProgress,
            "dailyDay": d.dailyDay,
            "dailyClaimed": Array(d.dailyClaimed),
            "loginStreak": d.loginStreak,
            "lastLoginDay": d.lastLoginDay,
            "grantedOrders": Array(d.grantedOrders),
            "removeAdsPurchased": d.removeAdsPurchased
        ]
    }

    private static func fromJSON(_ o: [String: Any]) -> SaveData {
        let d = SaveData()
        d.coins = max((o["coins"] as? Int) ?? 0, 0)
        d.unlockedLevel = max((o["unlockedLevel"] as? Int) ?? 1, 1)

        if let starsDict = o["stars"] as? [String: Any] {
            for (k, v) in starsDict {
                if let n = Int(k), let iv = v as? Int { d.stars[n] = iv }
            }
        }
        if let attemptsDict = o["attempts"] as? [String: Any] {
            for (k, v) in attemptsDict {
                if let n = Int(k), let iv = v as? Int { d.attempts[n] = iv }
            }
        }
        if let arr = o["unlockedCharacters"] as? [String] { d.unlockedCharacters.formUnion(arr) }
        if let arr = o["unlockedChairs"] as? [String] { d.unlockedChairs.formUnion(arr) }
        d.unlockedCharacters.insert("miko")
        d.unlockedChairs.insert("chair_plastic")

        d.selectedCharacter = (o["selectedCharacter"] as? String) ?? "miko"
        d.selectedChair = (o["selectedChair"] as? String) ?? "chair_plastic"
        d.soundEnabled = (o["soundEnabled"] as? Bool) ?? true
        d.musicEnabled = (o["musicEnabled"] as? Bool) ?? true
        d.hapticEnabled = (o["hapticEnabled"] as? Bool) ?? true
        d.easyMode = (o["easyMode"] as? Bool) ?? false
        d.endlessHighScore = (o["endlessHighScore"] as? Int) ?? 0
        d.totalSits = (o["totalSits"] as? Int) ?? 0
        d.bestCombo = (o["bestCombo"] as? Int) ?? 0

        if let dp = o["dailyProgress"] as? [String: Int] { d.dailyProgress = dp }
        d.dailyDay = (o["dailyDay"] as? Int64) ?? Int64((o["dailyDay"] as? Int) ?? 0)
        if let arr = o["dailyClaimed"] as? [String] { d.dailyClaimed.formUnion(arr) }
        d.loginStreak = (o["loginStreak"] as? Int) ?? 0
        d.lastLoginDay = (o["lastLoginDay"] as? Int64) ?? Int64((o["lastLoginDay"] as? Int) ?? 0)
        if let arr = o["grantedOrders"] as? [String] { d.grantedOrders.formUnion(arr) }
        d.removeAdsPurchased = (o["removeAdsPurchased"] as? Bool) ?? false

        // Secili oge kilitliyse varsayilana don (bozuk veri korumasi)
        if !d.unlockedCharacters.contains(d.selectedCharacter) { d.selectedCharacter = "miko" }
        if !d.unlockedChairs.contains(d.selectedChair) { d.selectedChair = "chair_plastic" }

        return d
    }
}
