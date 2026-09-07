import UIKit

/// Acilis ekrani:
///
///   Miko yurur  ->  sandalye kacar  ->  Miko ekrana bakar
///
/// (bkz. SplashScreen.kt)
final class SplashScreen: Screen {
    private let services: Services
    var next: Screen?

    init(services: Services) { self.services = services }

    /// Dokunma niyeti; gecis dongude yapilir.
    private var goToMenu = false

    private var t: CGFloat = 0
    private var pose = Pose()

    // Zaman cizelgesi (saniye)
    private let walkStart: CGFloat = 0.25
    private let walkEnd: CGFloat = 1.45
    private let chairFlee: CGFloat = 1.05
    private let chairGone: CGFloat = 1.95
    private let lookAt: CGFloat = 1.70
    private let logoIn: CGFloat = 0.45
    private let hintIn: CGFloat = 2.60

    private var mikoX: CGFloat = 0
    private var chairX: CGFloat = 0
    private var blinkTimer: CGFloat = 1.4

    func onEnter(_ vp: Viewport) {
        reset(vp)
    }

    private func reset(_ vp: Viewport) {
        t = 0
        mikoX = vp.playX(-0.18)
        chairX = vp.playX(0.66)
        blinkTimer = 1.4
        pose.face = .neutral
        pose.lookX = 1
        pose.blink = 0
        pose.armRaise = -0.75
    }

    func update(_ dt: CGFloat, _ vp: Viewport) {
        t += dt

        let targetX = vp.playX(0.40)

        // --- YURUYUS ---
        if t >= walkStart && t <= walkEnd {
            let p = ((t - walkStart) / (walkEnd - walkStart)).clamped(0, 1)
            mikoX = vp.playX(-0.18) + (targetX + vp.designWidth * 0.18) * easeOut(p)
            pose.stepPhase = (pose.stepPhase + dt / GameConstants.mikoStepPeriod).truncatingRemainder(dividingBy: 1)
            pose.bob = sin(pose.stepPhase * 12.566) * (vp.designHeight * 0.0035)
            pose.lean = 5
        } else if t > walkEnd {
            // durus: adim fazi 0'a yumusak iner
            pose.stepPhase *= max(1 - dt * 6, 0)
            pose.lean += (0 - pose.lean) * (dt * 6)
            pose.bob = sin(t * 2.4) * (vp.designHeight * 0.0016) // nefes
        }

        // --- SANDALYE KACAR ---
        if t >= chairFlee && t <= chairGone {
            let p = ((t - chairFlee) / (chairGone - chairFlee)).clamped(0, 1)
            chairX = vp.playX(0.66) + vp.designWidth * 0.62 * easeIn(p)
        }

        // --- EKRANA BAKAR ---
        if t > lookAt {
            pose.face = .surprised
            pose.lookX += (0 - pose.lookX) * (dt * 5)
            pose.headTilt = sin((t - lookAt) * 3.2) * 4.5
            pose.armRaise += (-0.25 - pose.armRaise) * (dt * 4)
        }

        // --- goz kirpma ---
        blinkTimer -= dt
        if blinkTimer <= 0 {
            pose.blink = 1
            if blinkTimer < -0.10 {
                pose.blink = 0
                blinkTimer = 1.6 + t.truncatingRemainder(dividingBy: 1.3)
            }
        } else {
            pose.blink = 0
        }

        // Animasyon bitince veya dokununca menuye gec.
        if goToMenu || t > Self.autoAdvance {
            next = MainMenuScreen(services: services)
        }
    }

    private static let minSkip: CGFloat = 0.8
    private static let autoAdvance: CGFloat = 4.2

    func draw(_ c: CGContext, _ vp: Viewport) {
        SceneArtist.draw(c, vp: vp, scroll: t * 40, time: t)

        let ground = vp.groundY
        let h = vp.designHeight

        // Sandalye
        if chairX < vp.designWidth + vp.playWidth * 0.3 {
            ChairArtist.draw(c, x: chairX, groundY: ground, height: h * 0.135, style: .plastic,
                              turn: ((chairX - vp.playX(0.66)) / vp.playWidth) * 1.4)
        }

        // Miko
        MikoArtist.draw(c, x: mikoX, groundY: ground, height: h * 0.168, pose: pose, skin: .miko)

        // --- LOGO ---
        let logoAlpha = fadeIn(t, logoIn, 0.55)
        if logoAlpha > 0 {
            let pop = popScale(t, logoIn)
            let titleSize = vp.uiWidth * 0.118 * pop
            let cy = vp.safeTop + h * 0.155
            TextArtist.title(c, "SANDALYEYE", x: vp.centerX, y: cy, size: titleSize, color: Palette.cream, outlineColor: Palette.ink, alpha: logoAlpha)
            TextArtist.title(c, "OTUR", x: vp.centerX, y: cy + titleSize * 0.98, size: titleSize * 1.32, color: Palette.orange, outlineColor: Palette.ink, alpha: logoAlpha)
            TextArtist.label(
                c, "Bir kere otur, rahatla.", x: vp.centerX, y: cy + titleSize * 1.85,
                size: vp.uiWidth * 0.042, color: Palette.ink, alpha: logoAlpha * 0.85
            )
        }

        // --- DOKUNMA IPUCU ---
        let hintAlpha = fadeIn(t, hintIn, 0.5) * (0.55 + 0.45 * sin(t * 3.4) * 0.5 + 0.22)
        if hintAlpha > 0 {
            TextArtist.title(
                c, "DOKUN", x: vp.centerX, y: h - vp.safeBottom - h * 0.075,
                size: vp.uiWidth * 0.062, color: Palette.cream, outlineColor: Palette.ink, alpha: hintAlpha.clamped(0, 1)
            )
        }
    }

    @discardableResult
    func onTouch(x: CGFloat, y: CGFloat, down: Bool) -> Bool {
        if down && t > Self.minSkip {
            goToMenu = true
        }
        return true
    }

    // ------------------------------------------------------------ yardimcilar
    private func easeOut(_ p: CGFloat) -> CGFloat { 1 - (1 - p) * (1 - p) }
    private func easeIn(_ p: CGFloat) -> CGFloat { p * p * (3 - 2 * p) }

    private func fadeIn(_ now: CGFloat, _ start: CGFloat, _ dur: CGFloat) -> CGFloat {
        ((now - start) / dur).clamped(0, 1)
    }

    /// Kisa "zipla ve otur" olcek animasyonu - logoyu canli gosterir.
    private func popScale(_ now: CGFloat, _ start: CGFloat) -> CGFloat {
        let p = ((now - start) / 0.45).clamped(0, 1)
        return 0.82 + 0.18 * (1 - (1 - p) * (1 - p)) + sin(p * 3.1416) * 0.06
    }

    func onBack() -> Bool { false }
    func onExit() {}
}
