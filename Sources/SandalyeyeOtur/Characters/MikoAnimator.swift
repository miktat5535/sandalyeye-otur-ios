import CoreGraphics

/// Karakter animasyon durum makinesi.
///
/// Tek isi: zamanla [pose] alanlarini degistirmek. Cizim (MikoArtist) durumsuz,
/// oynanis (GameplayScreen) animasyonun ic detayindan habersiz kalir.
/// (bkz. MikoAnimator.kt)
final class MikoAnimator {

    enum State { case idle, walk, sit, fall, celebrate, confused, surprised }

    /// GAME_DESIGN.md bolum 9'daki 8 fail varyasyonu.
    enum FailStyle: CaseIterable {
        case buttDrop      // 1 poposu ustu duser
        case slipOff       // 2 kenardan kayar
        case bounceBack    // 3 carpip geriye savrulur
        case coyote        // 4 havada kalir, sonra duser
        case somersault    // 5 takla atar
        case pulledUnder   // 6 sandalye altindan cekilir, sirt ustu
        case tipOver       // 7 sandalyeyle devrilir
        case dizzySpin     // 8 sersemler
    }

    var pose = Pose()

    private(set) var state: State = .idle
    private(set) var failStyle: FailStyle = .buttDrop

    /// Durum icindeki gecen sure.
    private(set) var stateTime: CGFloat = 0

    /// Animasyonun "bitti" sayildigi an gecildi mi.
    private(set) var finished = false

    /// FALL sirasinda karakterin ekstra yatay/dikey kaymasi (ekran tarafinda uygulanir).
    private(set) var offsetX: CGFloat = 0
    private(set) var offsetY: CGFloat = 0

    private var blinkTimer: CGFloat = 1.5
    private var lastFailIndex = -1

    func reset() {
        state = .idle
        stateTime = 0
        finished = false
        offsetX = 0
        offsetY = 0
        pose.lean = 0; pose.hipDrop = 0; pose.stepPhase = 0; pose.bob = 0
        pose.squash = 1; pose.headTilt = 0; pose.bodyRotation = 0
        pose.armRaise = -0.85; pose.face = .neutral; pose.blink = 0; pose.lookX = 0
    }

    func setState(_ s: State) {
        if state == s { return }
        state = s
        stateTime = 0
        finished = false
        if s != .fall {
            offsetX = 0
            offsetY = 0
            pose.bodyRotation = 0
        }
    }

    /// Fail durumuna gecerken hangi varyasyonun oynayacagini secer.
    func startFail(_ style: FailStyle) {
        failStyle = style
        setState(.fall)
    }

    /// Ayni fail'i ust uste gostermemek icin sirali-rastgele secim.
    func pickFailStyle() -> FailStyle {
        let values = FailStyle.allCases
        var i = Int.random(in: 0..<values.count)
        if i == lastFailIndex { i = (i + 1) % values.count }
        lastFailIndex = i
        return values[i]
    }

    func update(_ dt: CGFloat) {
        stateTime += dt
        updateBlink(dt)

        switch state {
        case .idle:
            pose.stepPhase = decayTo(pose.stepPhase, 0, dt * 6)
            pose.lean = decayTo(pose.lean, 0, dt * 6)
            pose.hipDrop = decayTo(pose.hipDrop, 0, dt * 8)
            pose.bob = sin(stateTime * 2.4) * Self.breath
            pose.armRaise = decayTo(pose.armRaise, -0.85, dt * 5)
            pose.squash = decayTo(pose.squash, 1, dt * 8)

        case .walk:
            pose.stepPhase = (pose.stepPhase + dt / GameConstants.mikoStepPeriod).truncatingRemainder(dividingBy: 1)
            pose.lean = decayTo(pose.lean, 5, dt * 6)
            pose.hipDrop = decayTo(pose.hipDrop, 0, dt * 8)
            // Adim basina hafif dikey zipzip - yuruyusun butun komikligi burada
            pose.bob = -abs(sin(pose.stepPhase * 6.2832)) * Self.walkBob
            pose.armRaise = decayTo(pose.armRaise, -0.85, dt * 5)
            pose.face = .determined

        case .sit:
            let p = (stateTime / Self.sitDuration).clamped(0, 1)
            // Once one atilir, sonra oturur: lean once artar sonra sifirlanir.
            pose.lean = 14 * sin(p * 3.1416)
            pose.hipDrop = easeOutBack(p)
            pose.stepPhase = decayTo(pose.stepPhase, 0, dt * 10)
            pose.bob = 0
            pose.armRaise = decayTo(pose.armRaise, -0.55, dt * 6)
            // Oturma anindaki ezilme
            pose.squash = p > 0.75 ? 1 - (1 - abs(1 - (p - 0.75) / 0.25)) * 0.10 : 1
            pose.face = p > 0.8 ? .happy : .surprised
            if p >= 1 { finished = true }

        case .celebrate:
            pose.hipDrop = 1
            pose.face = .happy
            pose.armRaise = decayTo(pose.armRaise, 0.9, dt * 7)
            // Oturarak iki kez zipla
            let hop = sin(stateTime * 9)
            pose.bob = stateTime < 0.75 ? -abs(hop) * Self.hop : 0
            pose.squash = 1 + hop * 0.05
            pose.headTilt = sin(stateTime * 6) * 5
            if stateTime > 1.1 { finished = true }

        case .fall:
            updateFall(dt)

        case .confused:
            pose.face = .confused
            pose.headTilt = sin(stateTime * 3.2) * 8
            pose.stepPhase = decayTo(pose.stepPhase, 0, dt * 6)
            pose.lean = decayTo(pose.lean, 0, dt * 5)
            pose.bob = sin(stateTime * 2.4) * Self.breath
            if stateTime > 1.0 { finished = true }

        case .surprised:
            pose.face = .surprised
            pose.headTilt = sin(stateTime * 5.5) * 6 * damp(stateTime, 0.8)
            pose.lookX = decayTo(pose.lookX, 0, dt * 5)
            pose.lean = decayTo(pose.lean, -4, dt * 6)
            pose.stepPhase = decayTo(pose.stepPhase, 0, dt * 8)
            pose.bob = sin(stateTime * 2.4) * Self.breath
            if stateTime > 0.9 { finished = true }
        }
    }

    // --------------------------------------------------------------- dusme
    private func updateFall(_ dt: CGFloat) {
        let t = stateTime
        pose.stepPhase = decayTo(pose.stepPhase, 0, dt * 12)
        pose.armRaise = decayTo(pose.armRaise, 0.35, dt * 8) // kollar savrulur

        switch failStyle {
        case .buttDrop:
            pose.hipDrop = (t / 0.22).clamped(0, 1)
            pose.lean = -18 * (t / 0.22).clamped(0, 1)
            pose.face = .surprised
            offsetY = bounceDown(t, 0.22, Self.drop)
            pose.squash = squashOnLand(t, 0.22)

        case .slipOff:
            pose.hipDrop = 1
            pose.bodyRotation = -34 * ease(t, 0.30)
            offsetX = -Self.slide * ease(t, 0.35)
            offsetY = bounceDown(t, 0.30, Self.drop * 0.8)
            pose.face = .surprised

        case .bounceBack:
            // Once ileri carpar, sonra geri savrulur
            let k = ease(t, 0.35)
            offsetX = -Self.slide * 1.5 * k
            pose.bodyRotation = -55 * k
            offsetY = bounceDown(t, 0.35, Self.drop)
            pose.face = t < 0.12 ? .surprised : .dizzy

        case .coyote:
            // Koyot efekti: once havada bekler, sonra duser
            if t < 0.45 {
                pose.hipDrop = 1
                pose.face = .confused
                pose.bob = sin(t * 18) * 3
                offsetY = 0
            } else {
                let k = ease(t - 0.45, 0.28)
                pose.face = .surprised
                offsetY = Self.drop * 1.6 * k * k
                pose.bodyRotation = 12 * k
            }

        case .somersault:
            let k = ease(t, 0.55)
            pose.bodyRotation = -360 * k
            offsetX = -Self.slide * 1.2 * k
            offsetY = -Self.drop * 1.4 * sin(k * 3.1416) + Self.drop * k
            pose.face = .dizzy
            pose.hipDrop = 0.5

        case .pulledUnder:
            pose.hipDrop = 1
            pose.bodyRotation = -78 * ease(t, 0.26)
            offsetY = bounceDown(t, 0.26, Self.drop * 1.1)
            pose.face = .surprised

        case .tipOver:
            let k = ease(t, 0.42)
            pose.hipDrop = 1
            pose.bodyRotation = -95 * k
            offsetX = -Self.slide * 0.8 * k
            offsetY = Self.drop * 0.9 * k
            pose.face = .dizzy

        case .dizzySpin:
            pose.hipDrop = (t / 0.25).clamped(0, 1)
            pose.bodyRotation = sin(t * 11) * 16 * damp(t, 1.0)
            pose.headTilt = sin(t * 13) * 14 * damp(t, 1.0)
            pose.face = .dizzy
            offsetY = bounceDown(t, 0.25, Self.drop * 0.6)
        }

        if t > Self.failDuration { finished = true }
    }

    private func updateBlink(_ dt: CGFloat) {
        blinkTimer -= dt
        if blinkTimer > 0 {
            pose.blink = 0
        } else if blinkTimer > -0.09 {
            pose.blink = 1
        } else {
            pose.blink = 0
            blinkTimer = 1.3 + CGFloat.random(in: 0..<1) * 1.8
        }
    }

    // ---------------------------------------------------------- yardimcilar
    private func decayTo(_ current: CGFloat, _ target: CGFloat, _ k: CGFloat) -> CGFloat {
        current + (target - current) * k.clamped(0, 1)
    }

    private func ease(_ t: CGFloat, _ dur: CGFloat) -> CGFloat {
        let p = (t / dur).clamped(0, 1)
        return 1 - (1 - p) * (1 - p)
    }

    private func damp(_ t: CGFloat, _ dur: CGFloat) -> CGFloat { (1 - (t / dur)).clamped(0, 1) }

    /// Yere duser ve tek sekme yapar.
    private func bounceDown(_ t: CGFloat, _ dur: CGFloat, _ dist: CGFloat) -> CGFloat {
        let p = (t / dur).clamped(0, 1)
        let fall = dist * p * p
        if t <= dur { return fall }
        let b = ((t - dur) / 0.18).clamped(0, 1)
        return dist - dist * 0.14 * sin(b * 3.1416)
    }

    /// Yere degme aninda ezilme.
    private func squashOnLand(_ t: CGFloat, _ landAt: CGFloat) -> CGFloat {
        if t < landAt { return 1 }
        let b = ((t - landAt) / 0.16).clamped(0, 1)
        return 1 - 0.16 * sin(b * 3.1416)
    }

    private func easeOutBack(_ p: CGFloat) -> CGFloat {
        let c1: CGFloat = 1.70158
        let c3 = c1 + 1
        let x = p - 1
        return (1 + c3 * x * x * x + c1 * x * x).clamped(0, 1.12)
    }

    static let sitDuration: CGFloat = 0.28
    static let failDuration: CGFloat = 0.95
    private static let breath: CGFloat = 3.5
    private static let walkBob: CGFloat = 7
    private static let hop: CGFloat = 16
    private static let drop: CGFloat = 46
    private static let slide: CGFloat = 70
}
