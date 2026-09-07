import Foundation

/// Gunluk gorevler ve 7 gunluk giris odulu (GAME_DESIGN.md bolum 12).
///
/// Gun hesabi cihaz saatine dayanir. Saati geri almak istismari mumkun kilar
/// ama oduller yalnizca coin - yani kozmetik - oldugu icin risk kabul edilebilir.
/// Ileride sunucu zamani eklenirse yalnizca [today] degisir. (bkz. Daily.kt)
final class Daily {
    private let save: SaveRepository
    private let wallet: Wallet

    init(save: SaveRepository, wallet: Wallet) {
        self.save = save
        self.wallet = wallet
    }

    enum TaskType: Int, CaseIterable {
        case playLevels, threeStars, earnCoins, perfectSits, comboReach

        var id: String {
            switch self {
            case .playLevels: return "play_levels"
            case .threeStars: return "three_stars"
            case .earnCoins: return "earn_coins"
            case .perfectSits: return "perfect_sits"
            case .comboReach: return "combo_reach"
            }
        }
        var target: Int {
            switch self {
            case .playLevels: return 5
            case .threeStars: return 2
            case .earnCoins: return 1000
            case .perfectSits: return 3
            case .comboReach: return 5
            }
        }
        var reward: Int {
            switch self {
            case .playLevels: return 500
            case .threeStars: return 1200
            case .earnCoins: return 800
            case .perfectSits: return 900
            case .comboReach: return 2000
            }
        }
    }

    /// Gunun 3 gorevi. Gun degisince yenilenir.
    private(set) var tasks: [TaskType] = []

    private func today() -> Int64 { Int64(Date().timeIntervalSince1970 / 86400) }

    func refreshIfNeeded() {
        let d = today()
        if save.data.dailyDay != d {
            save.data.dailyDay = d
            save.data.dailyProgress.removeAll()
            save.data.dailyClaimed.removeAll()
            // Gunun tohumu tarihten turer -> ayni gun ayni gorevler
            var rng = SeededGenerator(seed: UInt64(bitPattern: d))
            tasks = Array(TaskType.allCases.shuffled(using: &rng).prefix(3))
            for (i, t) in tasks.enumerated() {
                save.data.dailyProgress["_task\(i)"] = t.rawValue
            }
            updateLoginStreak(d)
            save.markDirty()
        } else if tasks.isEmpty {
            // Ayni gun icinde yeniden acilis: kaydedilmis gorevleri geri yukle
            var restored: [TaskType] = []
            for i in 0..<3 {
                guard let ord = save.data.dailyProgress["_task\(i)"], let t = TaskType(rawValue: ord) else { continue }
                restored.append(t)
            }
            tasks = restored.count == 3 ? restored : Array(TaskType.allCases.prefix(3))
        }
    }

    private func updateLoginStreak(_ d: Int64) {
        let last = save.data.lastLoginDay
        if last == 0 {
            save.data.loginStreak = 1
        } else if d - last == 1 {
            save.data.loginStreak = min(save.data.loginStreak + 1, 7)
        } else if d - last > 1 {
            save.data.loginStreak = 1
        }
        save.data.lastLoginDay = d
    }

    func progress(_ type: TaskType) -> Int { save.data.dailyProgress[type.id] ?? 0 }

    func isClaimed(_ type: TaskType) -> Bool { save.data.dailyClaimed.contains(type.id) }

    func isDone(_ type: TaskType) -> Bool { progress(type) >= type.target }

    /// Ilerleme kaydeder. Gorev bugunku listede degilse yok sayilir.
    func advance(_ type: TaskType, amount: Int = 1) {
        guard tasks.contains(type) else { return }
        if isClaimed(type) { return }
        let cur = progress(type)
        if cur >= type.target { return }
        save.data.dailyProgress[type.id] = min(cur + amount, type.target)
        save.markDirty()
    }

    /// @return verilen coin, 0 = verilmedi
    @discardableResult
    func claim(_ type: TaskType) -> Int {
        guard tasks.contains(type), isDone(type), !isClaimed(type) else { return 0 }
        save.data.dailyClaimed.insert(type.id)
        wallet.add(type.reward)
        save.markDirty()
        save.flush()
        return type.reward
    }

    // ------------------------------------------------------- giris odulu

    /// 7 gunluk giris odul tablosu.
    let loginRewards = [300, 500, 800, 1200, 1600, 2200, 3000]

    var loginStreak: Int { min(max(save.data.loginStreak, 1), 7) }

    func isLoginClaimed() -> Bool { save.data.dailyClaimed.contains(Self.loginKey) }

    @discardableResult
    func claimLogin() -> Int {
        if isLoginClaimed() { return 0 }
        let amount = loginRewards[min(max(loginStreak - 1, 0), 6)]
        save.data.dailyClaimed.insert(Self.loginKey)
        wallet.add(amount)
        save.markDirty()
        save.flush()
        return amount
    }

    /// Alinmayi bekleyen bir odul var mi? Menude nokta gostermek icin.
    func hasClaimable() -> Bool {
        !isLoginClaimed() || tasks.contains { isDone($0) && !isClaimed($0) }
    }

    private static let loginKey = "_login"
}

/// Kotlin `Random(seed)` ile birebir ayni degil, ama AYNI GUN AYNI CIHAZDA
/// ayni sonucu ureten deterministik bir PRNG - Daily.kt'nin niyeti
/// ("gunun tohumu tarihten turer") icin yeterli (sunucu senkronu yok, her
/// cihaz kendi gunluk gorevini kendi hesaplar).
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545F4914F6CDD1D
    }
}
