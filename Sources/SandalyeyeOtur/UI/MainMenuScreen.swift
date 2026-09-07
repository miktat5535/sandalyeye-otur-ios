import CoreGraphics

/// Ana menu.
///
/// **GECICI/MINIMAL DURUM:** Android'deki MainMenuScreen.kt henuz TAM
/// portlanmadi (karakter/sandalye secimi, ayarlar, gunluk odul, magaza
/// kisayollari eksik). Bu surum yalnizca oyun dongusunun uctan uca
/// CALISTIGINI dogrulamak icin: baslik, coin rozeti ve tek bir OYNA butonu.
/// Sonraki asamada LevelSelectScreen/ShopScreen/DailyScreen/SettingsScreen
/// ile birlikte tam parite saglanacak.
final class MainMenuScreen: Screen {
    private let services: Services
    var next: Screen?

    private var totalTime: CGFloat = 0
    private var playPressed = false
    private var pendingPlay = false

    init(services: Services) {
        self.services = services
    }

    func onEnter(_ vp: Viewport) {
        services.daily.refreshIfNeeded()
    }

    func update(_ dt: CGFloat, _ vp: Viewport) {
        totalTime += dt
        services.tick(dt)
        lastW = vp.uiWidth
        lastCx = vp.centerX
        lastCy = vp.designHeight * 0.56
        if pendingPlay {
            pendingPlay = false
            let level = services.save.data.unlockedLevel
            next = GameplayScreen(services: services, levelNumber: level)
        }
    }

    func draw(_ c: CGContext, _ vp: Viewport) {
        SceneArtist.draw(c, vp: vp, scroll: totalTime * 12, time: totalTime, theme: .defaultTheme)

        TextArtist.title(
            c, "SANDALYEYE OTUR", x: vp.centerX, y: vp.designHeight * 0.30,
            size: vp.uiWidth * 0.11, color: Palette.cream, outlineColor: Palette.ink
        )

        UiArtist.coinBadge(c, cx: vp.centerX - vp.uiWidth * 0.30, cy: vp.safeTop + vp.designHeight * 0.045,
                            h: vp.uiWidth * 0.082, amount: services.wallet.coins)

        let label = "BÖLÜM \(services.save.data.unlockedLevel)"
        TextArtist.label(c, label, x: vp.centerX, y: vp.designHeight * 0.40, size: vp.uiWidth * 0.05, color: Palette.uiTextDark)

        UiArtist.button(
            c, cx: vp.centerX, cy: vp.designHeight * 0.56, w: vp.uiWidth * 0.55, h: vp.uiWidth * 0.16,
            label: "OYNA", pressed: playPressed, color: Palette.orange, shade: Palette.orangeDark
        )
    }

    @discardableResult
    func onTouch(x: CGFloat, y: CGFloat, down: Bool) -> Bool {
        let cx = lastCx, cy = lastCy
        let w = lastW * 0.55, h = lastW * 0.16
        let hit = UiArtist.hit(x, y, cx, cy, w, h)
        if down {
            playPressed = hit
        } else {
            if playPressed && hit {
                services.sound.play(.button)
                services.haptics.tap()
                pendingPlay = true
            }
            playPressed = false
        }
        return true
    }

    private var lastW: CGFloat = 1080
    private var lastCx: CGFloat = 540
    private var lastCy: CGFloat = 1075

    func onBack() -> Bool { false }
    func onExit() {}
}
