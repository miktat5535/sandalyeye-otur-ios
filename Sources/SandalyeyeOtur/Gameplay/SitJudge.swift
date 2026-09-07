import CoreGraphics

/// Oyunun TEK gercek sorusu: bu oturus tutmus mu?
///
/// Tamamen saf (pure) bir yapidir - CGContext, zaman bilmez. Bu sayede birim
/// testleriyle dogrulanabilir. (bkz. SitJudge.kt)
enum SitJudge {

    enum Result {
        case perfect      // tam ortasina
        case good         // tolerans icinde
        case miss         // isabetsiz
        case notSittable  // sandalye havada / kapali
        case fakeChair    // sahte sandalyeye oturdu
        case noChair      // sandalye yok olmus
    }

    final class Verdict {
        var result: Result = .miss
        /// Kalca ile oturma yuzeyi merkezi arasindaki yatay mesafe.
        var distance: CGFloat = 0
        /// O anki efektif tolerans.
        var tolerance: CGFloat = 0
        /// Hangi sandalyeye oturuldu (nil = hicbiri).
        weak var chair: ChairActor?

        var success: Bool { result == .perfect || result == .good }

        /// 0 = kenar, 1 = tam merkez. Yildiz/puan hesabinda kullanilir.
        var accuracy: CGFloat {
            tolerance <= 0 ? 0 : (1 - (distance / tolerance)).clamped(0, 1)
        }
    }

    private static let verdict = Verdict()

    /// - Parameters:
    ///   - playerX: oturma hamlesinin BITTIGI andaki karakter merkezi
    ///   - chairs: sahnedeki sandalyeler
    ///   - baseTolerance: bolum verisinden gelen temel tolerans
    static func judge(playerX: CGFloat, chairs: [ChairActor], baseTolerance: CGFloat) -> Verdict {
        verdict.chair = nil
        verdict.distance = .greatestFiniteMagnitude
        verdict.tolerance = baseTolerance
        verdict.result = .miss

        // En yakin sandalyeyi bul (yok olmuslar haric)
        var best: ChairActor?
        var bestDist: CGFloat = .greatestFiniteMagnitude
        for ch in chairs where !ch.gone {
            let d = abs(playerX - ch.x)
            if d < bestDist {
                bestDist = d
                best = ch
            }
        }

        guard let bestChair = best else {
            verdict.result = .noChair
            verdict.distance = 0
            return verdict
        }

        let tol = baseTolerance * bestChair.toleranceScale
        verdict.chair = bestChair
        verdict.distance = bestDist
        verdict.tolerance = tol

        if bestDist > tol {
            verdict.result = .miss
        } else if !bestChair.sittable {
            verdict.result = .notSittable
        } else if bestChair.fake {
            verdict.result = .fakeChair
        } else if bestDist <= GameConstants.sitPerfect {
            verdict.result = .perfect
        } else {
            verdict.result = .good
        }
        return verdict
    }

    /// Sonuca gore uygun fail animasyonunu secer.
    /// Ayni hatanin hep ayni animasyonla anlatilmasi oyunu monotonlastirir;
    /// bu yuzden yalnizca BELIRLEYICI durumlar sabittir, gerisi rastgele.
    static func failStyleFor(
        result: Result, distance: CGFloat, tolerance: CGFloat,
        random: () -> MikoAnimator.FailStyle
    ) -> MikoAnimator.FailStyle {
        switch result {
        case .fakeChair, .noChair: return .coyote
        case .notSittable: return .pulledUnder
        default:
            // Kil payi iskalamada "kenardan kayma" en okunakli anlatim.
            return distance < tolerance * 1.35 ? .slipOff : random()
        }
    }
}
