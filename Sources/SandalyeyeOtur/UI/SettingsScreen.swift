import UIKit

/// Ayarlar: ses, muzik, titresim ve kolaylik modu.
///
/// "Kolay mod" bilincli bir karar: zamanlama oyunlari bir kismi oyuncuyu
/// disarida birakir ve bu magaza puanina yansir. Toleransi %35 genisletmek
/// oyunu bozmaz ama kimseyi disarida birakmaz. (bkz. SettingsScreen.kt)
final class SettingsScreen: BaseScreen {
    private let services: Services

    private var t: CGFloat = 0
    private var pressed = -1
    private var pendingBack = false

    init(services: Services) {
        self.services = services
        super.init()
    }

    override func onUpdate(_ dt: CGFloat, _ vp: Viewport) {
        t += dt
        services.tick(dt)
        if pendingBack {
            pendingBack = false
            services.save.flush()
            next = MainMenuScreen(services: services)
        }
    }

    private func rowY(_ i: Int, _ h: CGFloat) -> CGFloat { safeTop + h * 0.26 + CGFloat(i) * (h * 0.085) }

    override func draw(_ c: CGContext, _ vp: Viewport) {
        let w = vp.uiWidth
        let h = vp.designHeight
        SceneArtist.draw(c, vp: vp, scroll: 0, time: t, theme: .defaultTheme)
        UiArtist.scrim(c, w: vp.designWidth, h: h, alpha: 0.40)

        UiArtist.panel(c, cx: vp.centerX, cy: h * 0.44, w: w * 0.88, h: h * 0.52)

        TextArtist.title(c, "AYARLAR", x: vp.centerX, y: safeTop + h * 0.215, size: w * 0.075, color: Palette.orange, outlineColor: Palette.ink)

        let d = services.save.data
        toggleRow(c, vp, 0, "Ses efektleri", d.soundEnabled, .sound)
        toggleRow(c, vp, 1, "Müzik", d.musicEnabled, .sound)
        toggleRow(c, vp, 2, "Titreşim", d.hapticEnabled, .vibrate)
        toggleRow(c, vp, 3, "Kolay mod", d.easyMode, .play)

        // Bilgi
        TextArtist.label(c, "Kolay modda oturma toleransı genişler.", x: vp.centerX, y: rowY(4, h) + h * 0.01, size: w * 0.036, color: Palette.uiTextDark)
        TextArtist.label(
            c, "Toplam oturuş: \(d.totalSits)   En iyi kombo: \(d.bestCombo)",
            x: vp.centerX, y: rowY(4, h) + h * 0.045, size: w * 0.036, color: Palette.uiTextDark
        )
        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
        TextArtist.label(c, "Sürüm \(version)", x: vp.centerX, y: h * 0.66, size: w * 0.032, color: Palette.uiTextDark)

        // Kapat
        let by = h * 0.72
        UiArtist.button(c, cx: vp.centerX, cy: by, w: w * 0.48, h: w * 0.14, label: "KAPAT", pressed: pressed == 100, color: Palette.orange, shade: Palette.orangeDark)
    }

    private func toggleRow(_ c: CGContext, _ vp: Viewport, _ i: Int, _ label: String, _ on: Bool, _ icon: UiArtist.Icon) {
        let w = vp.uiWidth
        let y = rowY(i, vp.designHeight)
        let left = vp.centerX - w * 0.36

        UiArtist.icon(c, cx: left, cy: y, r: w * 0.038, kind: icon, color: Palette.uiTextDark)
        TextArtist.label(c, label, x: left + w * 0.075, y: y + w * 0.017, size: w * 0.050, color: Palette.uiTextDark, align: .left)
        toggleSwitch(c, cx: vp.centerX + w * 0.30, cy: y, w: w * 0.14, h: w * 0.068, on: on, pressed: pressed == i)
    }

    /// Ac/kapa anahtari - sistem UISwitch'i degil, oyunun kendi dili.
    private func toggleSwitch(_ c: CGContext, cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat, on: Bool, pressed: Bool) {
        c.setFillColor((on ? Palette.success : Palette.uiPanelShade).cgColor)
        c.fillRoundRect(cx: cx, cy: cy, w: w, h: h, r: h * 0.5)
        c.setStrokeColor(Palette.uiOutline.cgColor)
        c.strokeRoundRect(cx: cx, cy: cy, w: w, h: h, r: h * 0.5, lineWidth: h * 0.14)

        let knobX = cx + (on ? 1 : -1) * (w * 0.5 - h * 0.5)
        let knobY = cy + (pressed ? 2 : 0)
        c.setFillColor(Palette.uiPanel.cgColor)
        c.fillEllipse(cx: knobX, cy: knobY, rx: h * 0.40, ry: h * 0.40)
        c.setStrokeColor(Palette.uiOutline.cgColor)
        c.strokeEllipse(cx: knobX, cy: knobY, rx: h * 0.40, ry: h * 0.40, lineWidth: h * 0.12)
    }

    @discardableResult
    override func onTouch(x: CGFloat, y: CGFloat, down: Bool) -> Bool {
        let w = vw
        let h = vh

        let hit: Int
        if UiArtist.hit(x, y, cx, h * 0.72, w * 0.48, w * 0.14) {
            hit = 100
        } else if let idx = (0..<4).first(where: { UiArtist.hit(x, y, cx, rowY($0, h), w * 0.76, h * 0.070) }) {
            hit = idx
        } else {
            hit = -1
        }

        if down {
            pressed = hit
        } else {
            if pressed >= 0 && pressed == hit {
                services.haptics.tap()
                let d = services.save.data
                switch pressed {
                case 0: d.soundEnabled.toggle()
                case 1:
                    d.musicEnabled.toggle()
                    services.music.syncWithSettings()
                case 2: d.hapticEnabled.toggle()
                case 3: d.easyMode.toggle()
                case 100: pendingBack = true
                default: break
                }
                services.save.markDirty()
                services.sound.play(.button)
            }
            pressed = -1
        }
        return true
    }

    override func onBack() -> Bool {
        pendingBack = true
        return true
    }
}
