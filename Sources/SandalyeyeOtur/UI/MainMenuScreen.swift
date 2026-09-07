import UIKit

/// Ana menu (GAME_DESIGN.md bolum 17).
///
/// Menu de oyunun icinde gecer - liste degil, SAHNE. Miko orada durur, nefes
/// alir, goz kirpar; secili sandalyesi yaninda bekler. Oyuncu ilk saniyede
/// "uygulama" degil "oyun" gordugunu anlar. (bkz. MainMenuScreen.kt)
final class MainMenuScreen: BaseScreen {
    private let services: Services

    private let animator = MikoAnimator()
    private var t: CGFloat = 0
    private var pressed = -1
    private var pending = -1

    init(services: Services) {
        self.services = services
        super.init()
    }

    override func onEnter(_ vp: Viewport) {
        animator.reset()
        animator.setState(.idle)
        t = 0
        services.daily.refreshIfNeeded()
    }

    override func onUpdate(_ dt: CGFloat, _ vp: Viewport) {
        t += dt
        animator.update(dt)
        services.tick(dt)

        switch pending {
        case Self.bPlay: next = LevelSelectScreen(services: services)
        case Self.bCharacter: next = ShopScreen(services: services, tab: .characters)
        case Self.bChair: next = ShopScreen(services: services, tab: .chairs)
        case Self.bDaily: next = DailyScreen(services: services)
        case Self.bShop: next = ShopScreen(services: services, tab: .coins)
        case Self.bSettings: next = SettingsScreen(services: services)
        case Self.bEndless: next = GameplayScreen(services: services, levelNumber: 1, endless: true)
        default: break
        }
        pending = -1
    }

    override func draw(_ c: CGContext, _ vp: Viewport) {
        let w = vp.uiWidth // arayuz OLCUSU (genis ekranda sinirli)
        let h = vp.designHeight
        SceneArtist.draw(c, vp: vp, scroll: t * 12, time: t, theme: .defaultTheme)

        // --- Sahne: Miko ve secili sandalye ---
        // Menude zemin cizgisi oynanistakinden YUKARIDA: alt yariyi butonlar
        // kapliyor, sahne ortadaki bos alani doldurmali. Zemin cizgisi OYNA
        // butonunun uzerinde kalmali.
        let menuGround = min(h * Self.menuGroundR, playY(h) - w * Self.playHR * 0.5 - w * 0.115)
        let mikoH = h * 0.200
        let chairH = ChairArtist.heightForSeatY(groundY: menuGround, seatY: MikoArtist.seatedHipY(groundY: menuGround, height: mikoH))
        ChairArtist.draw(
            c, x: vp.playX(0.665), groundY: menuGround, height: chairH,
            style: ChairCatalog.style(services.save.data.selectedChair),
            turn: sin(t * 0.6) * 0.10
        )
        MikoArtist.draw(
            c, x: vp.playX(0.345), groundY: menuGround, height: mikoH, pose: animator.pose,
            skin: CharacterCatalog.skin(services.save.data.selectedCharacter)
        )

        // --- Logo ---
        let titleSize = w * 0.104
        let ty = vp.safeTop + w * 0.082 * 1.95 + titleSize * 0.55
        TextArtist.title(c, "SANDALYEYE", x: vp.centerX, y: ty, size: titleSize, color: Palette.cream, outlineColor: Palette.ink)
        TextArtist.title(c, "OTUR", x: vp.centerX, y: ty + titleSize * 0.98, size: titleSize * 1.30, color: Palette.orange, outlineColor: Palette.ink)

        // --- Ust bar ---
        let badgeH = w * 0.082
        let topY = vp.safeTop + h * 0.026 + badgeH * 0.5
        UiArtist.coinBadge(c, cx: vp.centerX - w * 0.36, cy: topY, h: badgeH, amount: services.wallet.coins)
        UiArtist.iconButton(c, cx: vp.centerX + w * 0.5 - badgeH * 0.78, cy: topY, r: badgeH * 0.52, kind: .gear, pressed: pressed == Self.bSettings)

        // --- OYNA ---
        let pY = playY(h)
        TextArtist.label(
            c, "Bölüm \(services.save.data.unlockedLevel) / \(services.levels.count)    ★ \(services.save.data.totalStars)",
            x: vp.centerX, y: pY - w * Self.playHR * 0.5 - w * 0.030, size: w * 0.042, color: Palette.cream
        )
        UiArtist.button(
            c, cx: vp.centerX, cy: pY, w: w * Self.playWR, h: w * Self.playHR,
            label: services.save.data.unlockedLevel > 1 ? "DEVAM ET" : "OYNA",
            pressed: pressed == Self.bPlay, color: Palette.orange, shade: Palette.orangeDark, depth: 18
        )

        // --- SONSUZ ---
        let eY = endlessY(h)
        UiArtist.button(
            c, cx: vp.centerX, cy: eY, w: w * Self.endWR, h: w * Self.endHR, label: "SONSUZ",
            pressed: pressed == Self.bEndless, color: Palette.hint, shade: UIColor(hex: "#5A4CD1"), depth: 12
        )
        if services.save.data.endlessHighScore > 0 {
            TextArtist.label(
                c, "Rekor: \(services.save.data.endlessHighScore)",
                x: vp.centerX, y: eY + w * Self.endHR * 0.95, size: w * 0.038, color: Palette.ink
            )
        }

        // --- Alt sekmeler ---
        let ty2 = tabY(h)
        let r = w * Self.tabR
        let gap = w * Self.tabGap
        UiArtist.iconButton(c, cx: vp.centerX - gap * 1.5, cy: ty2, r: r, kind: .character, pressed: pressed == Self.bCharacter)
        UiArtist.iconButton(c, cx: vp.centerX - gap * 0.5, cy: ty2, r: r, kind: .chair, pressed: pressed == Self.bChair)
        UiArtist.iconButton(c, cx: vp.centerX + gap * 0.5, cy: ty2, r: r, kind: .daily, pressed: pressed == Self.bDaily)
        UiArtist.iconButton(c, cx: vp.centerX + gap * 1.5, cy: ty2, r: r, kind: .shop, pressed: pressed == Self.bShop)

        if services.daily.hasClaimable() {
            c.setFillColor(Palette.fail.cgColor)
            c.fillEllipse(cx: vp.centerX + gap * 0.5 + r * 0.72, cy: ty2 - r * 0.72, rx: r * 0.26, ry: r * 0.26)
        }
    }

    // Konum hesaplari tek yerde: cizim ve dokunma ayni formulu kullanir.
    //
    // Alt yigin TABANDAN YUKARI dizilir ve aralar sabit bosluklardir.
    private func tabY(_ h: CGFloat) -> CGFloat { h - safeBottom - vw * Self.tabR - vw * 0.030 }
    private func endlessY(_ h: CGFloat) -> CGFloat { tabY(h) - vw * Self.tabR - vw * Self.endHR * 0.5 - vw * 0.030 }
    private func playY(_ h: CGFloat) -> CGFloat { endlessY(h) - vw * Self.endHR * 0.5 - vw * Self.playHR * 0.5 - vw * 0.028 }

    @discardableResult
    override func onTouch(x: CGFloat, y: CGFloat, down: Bool) -> Bool {
        let w = vw
        let h = vh
        let badgeH = w * 0.082
        let topY = safeTop + h * 0.026 + badgeH * 0.5
        let r = w * Self.tabR
        let gap = w * Self.tabGap
        let ty2 = tabY(h)

        let hit: Int
        if UiArtist.hit(x, y, cx, playY(h), w * Self.playWR, w * Self.playHR) {
            hit = Self.bPlay
        } else if UiArtist.hit(x, y, cx, endlessY(h), w * Self.endWR, w * Self.endHR) {
            hit = Self.bEndless
        } else if UiArtist.hit(x, y, cx + w * 0.5 - badgeH * 0.78, topY, badgeH, badgeH) {
            hit = Self.bSettings
        } else if UiArtist.hit(x, y, cx - gap * 1.5, ty2, r * 2, r * 2) {
            hit = Self.bCharacter
        } else if UiArtist.hit(x, y, cx - gap * 0.5, ty2, r * 2, r * 2) {
            hit = Self.bChair
        } else if UiArtist.hit(x, y, cx + gap * 0.5, ty2, r * 2, r * 2) {
            hit = Self.bDaily
        } else if UiArtist.hit(x, y, cx + gap * 1.5, ty2, r * 2, r * 2) {
            hit = Self.bShop
        } else {
            hit = -1
        }

        if down {
            pressed = hit
        } else {
            if pressed >= 0 && pressed == hit {
                services.sound.play(.menu)
                services.haptics.tap()
                pending = pressed
            }
            pressed = -1
        }
        return true
    }

    private static let bPlay = 0
    private static let bCharacter = 1
    private static let bChair = 2
    private static let bDaily = 3
    private static let bShop = 4
    private static let bSettings = 5
    private static let bEndless = 6

    private static let playWR: CGFloat = 0.68
    private static let playHR: CGFloat = 0.185
    private static let endWR: CGFloat = 0.44
    private static let endHR: CGFloat = 0.115
    private static let tabR: CGFloat = 0.068
    private static let tabGap: CGFloat = 0.20
    /// Menu sahnesinin zemin cizgisi (ekran yuksekliginin orani).
    private static let menuGroundR: CGFloat = 0.615
}
