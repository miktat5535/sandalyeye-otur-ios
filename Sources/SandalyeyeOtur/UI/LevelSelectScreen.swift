import UIKit

/// Bolum secim ekrani: 100 bolum, 4 sutunlu kaydirilabilir izgara.
///
/// Her kart bolumun TEMA rengini tasir -> oyuncu ilerledikce sayfanin
/// renginin degistigini gorur. Kilitli bolumler soluk ve kilitli.
/// (bkz. LevelSelectScreen.kt)
final class LevelSelectScreen: BaseScreen {
    private let services: Services

    private var scroll: CGFloat = 0
    private var scrollVel: CGFloat = 0
    private var dragging = false
    private var dragStartY: CGFloat = 0
    private var dragStartScroll: CGFloat = 0
    private var lastDragY: CGFloat = 0
    private var movedDistance: CGFloat = 0
    private var pressedLevel = -1
    private var pendingLevel = -1
    private var pendingBack = false
    private var t: CGFloat = 0

    private let cols = 4

    init(services: Services) {
        self.services = services
        super.init()
    }

    override func onEnter(_ vp: Viewport) {
        // Acilista oyuncunun kaldigi bolume kaydir
        let row = (services.save.data.unlockedLevel - 1) / cols
        scroll = max(CGFloat(row) * rowHeight(vp.uiWidth) - vp.designHeight * 0.35, 0)
    }

    private func cardSize(_ w: CGFloat) -> CGFloat { w * 0.185 }
    private func rowHeight(_ w: CGFloat) -> CGFloat { cardSize(w) * 1.30 }
    private func gridTop(_ h: CGFloat) -> CGFloat { safeTop + h * 0.135 }

    override func onUpdate(_ dt: CGFloat, _ vp: Viewport) {
        t += dt
        services.tick(dt)

        if !dragging {
            // Atalet + kenarda geri yaylanma
            scroll += scrollVel * dt
            scrollVel *= pow(0.06, dt)
            if abs(scrollVel) < 4 { scrollVel = 0 }
            let maxS = maxScroll(vp)
            if scroll < 0 {
                scroll += (0 - scroll) * (dt * 12)
                scrollVel = 0
            } else if scroll > maxS {
                scroll += (maxS - scroll) * (dt * 12)
                scrollVel = 0
            }
        }

        if pendingLevel > 0 {
            next = GameplayScreen(services: services, levelNumber: pendingLevel)
            pendingLevel = -1
        }
        if pendingBack {
            pendingBack = false
            next = MainMenuScreen(services: services)
        }
    }

    private func maxScroll(_ vp: Viewport) -> CGFloat {
        let rows = (services.levels.count + cols - 1) / cols
        let contentH = CGFloat(rows) * rowHeight(vp.uiWidth)
        let viewH = vp.designHeight - gridTop(vp.designHeight) - safeBottom - vp.designHeight * 0.04
        return max(contentH - viewH, 0)
    }

    override func draw(_ c: CGContext, _ vp: Viewport) {
        let w = vp.uiWidth
        let h = vp.designHeight
        SceneArtist.draw(c, vp: vp, scroll: 0, time: t, theme: .defaultTheme)

        // Sahneyi hafif karart ki kartlar okunsun
        UiArtist.scrim(c, w: vp.designWidth, h: h, alpha: 0.30)

        let size = cardSize(w)
        let rowH = rowHeight(w)
        let top = gridTop(h)
        let gridW = CGFloat(cols) * size + CGFloat(cols - 1) * (size * 0.22)
        let startX = vp.centerX - gridW / 2 + size / 2
        let stepX = size + size * 0.22

        let clipTop = top - size * 0.6
        let clipBottom = h - safeBottom - h * 0.02
        c.saveGState()
        c.clip(to: CGRect(x: 0, y: clipTop, width: vp.designWidth, height: clipBottom - clipTop))

        let unlocked = services.save.data.unlockedLevel
        let total = services.levels.count
        let firstRow = max(Int((scroll - size) / rowH), 0)
        let lastRow = Int((scroll + (clipBottom - clipTop) + size) / rowH) + 1

        for row in firstRow...max(lastRow, firstRow) {
            for col in 0..<cols {
                let n = row * cols + col + 1
                if n > total { continue }
                let x = startX + CGFloat(col) * stepX
                let y = top + CGFloat(row) * rowH - scroll + size / 2
                drawCard(c, x: x, y: y, size: size, n: n, unlocked: n <= unlocked, pressed: pressedLevel == n)
            }
        }
        c.restoreGState()

        // Ust baslik + geri
        UiArtist.panel(c, cx: vp.centerX, cy: safeTop + h * 0.062, w: vp.designWidth * 1.3, h: h * 0.10, color: Palette.uiPanel)
        TextArtist.title(
            c, "BÖLÜMLER", x: vp.centerX, y: safeTop + h * 0.072, size: w * 0.070,
            color: Palette.orange, outlineColor: Palette.ink
        )
        UiArtist.iconButton(c, cx: vp.centerX - w * 0.39, cy: safeTop + h * 0.062, r: w * 0.052, kind: .back, pressed: false)
    }

    private func drawCard(_ c: CGContext, x: CGFloat, y: CGFloat, size: CGFloat, n: Int, unlocked: Bool, pressed: Bool) {
        let theme = Theme.forLevel(n)
        let sink: CGFloat = pressed ? 5 : 0
        let r = size * 0.26

        // Taban
        c.setFillColor(Palette.uiOutline.cgColor)
        c.fillRoundRect(cx: x, cy: y + size * 0.06, w: size, h: size, r: r)

        c.setFillColor((unlocked ? theme.hillNear : Palette.uiPanelShade).cgColor)
        c.fillRoundRect(cx: x, cy: y + sink, w: size, h: size, r: r)
        // Ust parlaklik
        c.setFillColor(UIColor.white.withAlphaComponent(CGFloat(0x2B) / 255).cgColor)
        c.fillRoundRect(cx: x, cy: y + sink - size * 0.28, w: size * 0.84, h: size * 0.30, r: size * 0.15)

        c.setStrokeColor(Palette.uiOutline.cgColor)
        c.strokeRoundRect(cx: x, cy: y + sink, w: size, h: size, r: r, lineWidth: size * 0.058)

        if unlocked {
            TextArtist.title(
                c, "\(n)", x: x, y: y + sink + size * 0.10, size: size * 0.42,
                color: Palette.cream, outlineColor: Palette.ink
            )
            let stars = services.save.data.starsFor(n)
            let sr = size * 0.11
            for i in 0..<3 {
                UiArtist.star(c, cx: x + CGFloat(i - 1) * sr * 2.3, cy: y + sink + size * 0.36, r: sr, filled: i < stars)
            }
        } else {
            UiArtist.icon(c, cx: x, cy: y + sink, r: size * 0.28, kind: .lock, color: Palette.ink)
        }

        // Ozel bolum isareti
        if n % 10 == 0 && unlocked {
            c.setFillColor(Palette.coin.cgColor)
            c.fillEllipse(cx: x + size * 0.38, cy: y + sink - size * 0.38, rx: size * 0.11, ry: size * 0.11)
            c.setStrokeColor(Palette.uiOutline.cgColor)
            c.strokeEllipse(cx: x + size * 0.38, cy: y + sink - size * 0.38, rx: size * 0.11, ry: size * 0.11, lineWidth: size * 0.04)
        }
    }

    @discardableResult
    override func onTouch(x: CGFloat, y: CGFloat, down: Bool) -> Bool {
        let w = vw
        let h = vh

        if down {
            // Geri butonu
            if UiArtist.hit(x, y, cx - w * 0.39, safeTop + h * 0.062, w * 0.104, w * 0.104) {
                pressedLevel = -2
                return true
            }
            dragging = true
            dragStartY = y
            lastDragY = y
            dragStartScroll = scroll
            movedDistance = 0
            scrollVel = 0
            pressedLevel = levelAt(x, y)
        } else {
            if pressedLevel == -2 {
                if UiArtist.hit(x, y, cx - w * 0.39, safeTop + h * 0.062, w * 0.104, w * 0.104) {
                    services.sound.play(.menu)
                    pendingBack = true
                }
                pressedLevel = -1
                return true
            }
            dragging = false
            // Kaydirma degil dokunma ise bolumu ac
            if movedDistance < w * 0.03 && pressedLevel > 0 && pressedLevel <= services.save.data.unlockedLevel {
                services.sound.play(.button)
                services.haptics.tap()
                pendingLevel = pressedLevel
            }
            pressedLevel = -1
        }
        return true
    }

    override func onTouchMoved(x: CGFloat, y: CGFloat) {
        guard dragging else { return }
        let dy = y - lastDragY
        lastDragY = y
        movedDistance += abs(dy)
        scroll = dragStartScroll - (y - dragStartY)
        // Kaydirma basladiysa kart secimi iptal
        if movedDistance > vw * 0.03 { pressedLevel = -1 }
        scrollVel = -dy * 14
    }

    override func onTouchCancelled() {
        dragging = false
        pressedLevel = -1
    }

    private func levelAt(_ x: CGFloat, _ y: CGFloat) -> Int {
        let w = vw
        let size = cardSize(w)
        let rowH = rowHeight(w)
        let top = gridTop(vh)
        let gridW = CGFloat(cols) * size + CGFloat(cols - 1) * (size * 0.22)
        let startX = cx - gridW / 2 + size / 2
        let stepX = size + size * 0.22

        let col = Int((x - startX + size / 2) / stepX)
        if col < 0 || col >= cols { return -1 }
        let row = Int((y + scroll - top) / rowH)
        if row < 0 { return -1 }
        let n = row * cols + col + 1
        if n < 1 || n > services.levels.count { return -1 }

        let cxx = startX + CGFloat(col) * stepX
        let cyy = top + CGFloat(row) * rowH - scroll + size / 2
        if abs(x - cxx) > size * 0.6 || abs(y - cyy) > size * 0.6 { return -1 }
        return n
    }

    override func onBack() -> Bool {
        pendingBack = true
        return true
    }
}
