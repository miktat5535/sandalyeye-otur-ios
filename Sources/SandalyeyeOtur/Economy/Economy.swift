import Foundation

/// Coin, yildiz ve odul matematigi. Tamamen saf - test edilebilir. (bkz. Economy.kt)
enum Economy {

    /// Yildiz kosullari (GAME_DESIGN.md bolum 7):
    ///   1 yildiz  bolumu tamamla
    ///   2 yildiz  ipucu kullanmadan tamamla
    ///   3 yildiz  ILK denemede tamamla
    static func starsFor(attempts: Int, usedHint: Bool) -> Int {
        if attempts <= 1 && !usedHint { return 3 }
        if !usedHint { return 2 }
        return 1
    }

    /// Bolum sonu coin odulu.
    static func levelReward(baseReward: Int, stars: Int, firstTry: Bool) -> Int {
        var total = baseReward
        if stars >= 3 { total += GameConstants.coinThreeStarBonus }
        if firstTry { total += GameConstants.coinFirstTryBonus }
        return total
    }

    /// Combo kademesi -> coin carpani.
    static func comboMultiplier(_ combo: Int) -> Double {
        switch combo {
        case 10...: return 3.0
        case 5..<10: return 2.0
        case 4: return 1.6
        case 3: return 1.4
        case 2: return 1.2
        default: return 1
        }
    }

    /// Oyuncunun ulastigi combo kademesi (gosterim icin). 0 = kademe yok.
    static func comboTier(_ combo: Int) -> Int {
        var tier = 0
        for t in GameConstants.comboTiers where combo >= t { tier = t }
        return tier
    }

    /// Endless modunda bir oturusun puani.
    static func endlessPoints(combo: Int, perfect: Bool) -> Int {
        let base = perfect ? 15.0 : 10.0
        return Int(base * comboMultiplier(combo))
    }
}

/// Cuzdan. Coin degisikligi TEK bir yerden gecer; boylece kaydetme ve
/// analytics tetiklemeyi unutmak mumkun olmaz.
final class Wallet {
    private let save: SaveRepository

    init(save: SaveRepository) { self.save = save }

    var coins: Int { save.data.coins }

    @discardableResult
    func add(_ amount: Int) -> Int {
        guard amount > 0 else { return coins }
        save.data.coins += amount
        save.markDirty()
        return coins
    }

    func canAfford(_ price: Int) -> Bool { save.data.coins >= price }

    /// @return true = odeme yapildi. Yetersiz bakiyede hicbir sey degismez.
    @discardableResult
    func spend(_ price: Int) -> Bool {
        if price <= 0 { return true }
        if save.data.coins < price { return false }
        save.data.coins -= price
        save.markDirty()
        return true
    }
}
