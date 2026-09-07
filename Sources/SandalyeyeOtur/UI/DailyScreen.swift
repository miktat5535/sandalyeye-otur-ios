import UIKit

/// Gunluk gorevler + 7 gunluk giris odulu. (bkz. DailyScreen.kt)
final class DailyScreen: BaseScreen {
    private let services: Services

    private var t: CGFloat = 0
    private var pressed = -1
    private var pendingBack = false
    private var message = ""
    private var messageTime: CGFloat = 0

    init(services: Services) {
        self.services = services
        super.init()
    }

    override func onEnter(_ vp: Viewport) {
        services.daily.refreshIfNeeded()
    }

    override func onUpdate(_ dt: CGFloat, _ vp: Viewport) {
        t += dt
        services.tick(dt)
        if messageTime > 0 { messageTime -= dt }
        if pendingBack {
            pendingBack = false
            next = MainMenuScreen(services: services)
        }
    }

    // Dikey yerlesim tek yerde.
    private func barY(_ h: CGFloat) -> CGFloat { safeTop + h * 0.055 }
    private func titleY(_ h: CGFloat) -> CGFloat { safeTop + h * 0.130 }
    private func loginY(_ h: CGFloat) -> CGFloat { safeTop + h * 0.285 }
    private func daysY(_ h: CGFloat) -> CGFloat { loginY(h) - h * 0.020 }
    private func claimY(_ h: CGFloat) -> CGFloat { loginY(h) + h * 0.068 }
    private func tasksHeaderY(_ h: CGFloat) -> CGFloat { safeTop + h * 0.425 }
    private func taskY(_ i: Int, _ h: CGFloat) -> CGFloat { safeTop + h * 0.495 + CGFloat(i) * (h * 0.095) }

    override func draw(_ c: CGContext, _ vp: Viewport) {
        let w = vp.uiWidth
        let h = vp.designHeight
        SceneArtist.draw(c, vp: vp, scroll: 0, time: t, theme: .meadow)
        UiArtist.scrim(c, w: vp.designWidth, h: h, alpha: 0.36)

        // Ust bar: geri + coin. Baslik AYRI satirda.
        UiArtist.iconButton(c, cx: vp.centerX - w * 0.39, cy: barY(h), r: w * 0.052, kind: .back, pressed: pressed == 200)
        UiArtist.coinBadge(c, cx: vp.centerX + w * 0.30, cy: barY(h), h: w * 0.078, amount: services.wallet.coins)
        TextArtist.title(c, "GÜNLÜK", x: vp.centerX, y: titleY(h), size: w * 0.085, color: Palette.cream, outlineColor: Palette.ink)

        // --- 7 gunluk giris ---
        UiArtist.panel(c, cx: vp.centerX, cy: loginY(h), w: w * 0.90, h: h * 0.205)
        TextArtist.label(
            c, "Giriş ödülü - \(services.daily.loginStreak). gün",
            x: vp.centerX, y: loginY(h) - h * 0.070, size: w * 0.046, color: Palette.uiTextDark
        )
        let streak = services.daily.loginStreak
        let claimed = services.daily.isLoginClaimed()
        let bw = w * 0.108
        for i in 0..<7 {
            let x = vp.centerX + CGFloat(i - 3) * bw * 1.14
            let y = daysY(h)
            let done = (i + 1) < streak || ((i + 1) == streak && claimed)
            let today = (i + 1) == streak
            c.setFillColor((done ? Palette.success : (today ? Palette.coin : Palette.uiPanelShade)).cgColor)
            c.fillRoundRect(cx: x, cy: y, w: bw, h: bw * 1.15, r: bw * 0.26)
            c.setStrokeColor(Palette.uiOutline.cgColor)
            c.strokeRoundRect(cx: x, cy: y, w: bw, h: bw * 1.15, r: bw * 0.26, lineWidth: bw * 0.09)
            TextArtist.label(c, "\(i + 1)", x: x, y: y - bw * 0.16, size: bw * 0.34, color: (done || today) ? Palette.uiTextLight : Palette.uiTextDark)
            TextArtist.label(
                c, UiArtist.formatNumber(services.daily.loginRewards[i]),
                x: x, y: y + bw * 0.36, size: bw * 0.24, color: (done || today) ? Palette.uiTextLight : Palette.uiTextDark
            )
        }
        if !claimed {
            UiArtist.button(
                c, cx: vp.centerX, cy: claimY(h), w: w * 0.36, h: w * 0.10, label: "AL",
                pressed: pressed == 100, color: Palette.coin, shade: Palette.coinDark, textColor: Palette.uiTextDark, depth: 8
            )
        }

        // --- Gorevler ---
        TextArtist.label(c, "Bugünün görevleri", x: vp.centerX, y: tasksHeaderY(h), size: w * 0.050, color: Palette.cream)
        for (i, type) in services.daily.tasks.enumerated() {
            drawTask(c, vp, i: i, type: type)
        }

        if messageTime > 0 {
            let a = min(messageTime / 0.4, 1)
            UiArtist.panel(c, cx: vp.centerX, cy: h * 0.84, w: w * 0.76, h: w * 0.14, alpha: a * 0.95)
            TextArtist.label(c, message, x: vp.centerX, y: h * 0.84 + w * 0.016, size: w * 0.046, color: Palette.uiTextDark, alpha: a)
        }
    }

    private func drawTask(_ c: CGContext, _ vp: Viewport, i: Int, type: Daily.TaskType) {
        let w = vp.uiWidth
        let y = taskY(i, vp.designHeight)
        let ph = vp.designHeight * 0.082
        UiArtist.panel(c, cx: vp.centerX, cy: y, w: w * 0.90, h: ph)

        let progress = services.daily.progress(type)
        let done = services.daily.isDone(type)
        let claimed = services.daily.isClaimed(type)

        let title: String
        switch type {
        case .playLevels: title = "\(type.target) bölüm tamamla"
        case .threeStars: title = "3 yıldızlı \(type.target) bölüm bitir"
        case .earnCoins: title = "\(type.target) coin kazan"
        case .perfectSits: title = "\(type.target) kez tam isabet"
        case .comboReach: title = "\(type.target)x kombo yap"
        }

        TextArtist.label(c, title, x: vp.centerX - w * 0.40, y: y - ph * 0.16, size: w * 0.042, color: Palette.uiTextDark, align: .left)
        UiArtist.progressBar(
            c, cx: vp.centerX - w * 0.16, cy: y + ph * 0.20, w: w * 0.46, h: ph * 0.24,
            p: CGFloat(progress) / CGFloat(type.target), color: done ? Palette.success : Palette.hint
        )
        TextArtist.label(c, "\(progress)/\(type.target)", x: vp.centerX + w * 0.11, y: y + ph * 0.28, size: w * 0.034, color: Palette.uiTextDark, align: .left)

        let bw = w * 0.20
        let bh = ph * 0.50
        if claimed {
            UiArtist.button(c, cx: vp.centerX + w * 0.32, cy: y, w: bw, h: bh, label: "ALINDI", pressed: false,
                             color: Palette.uiPanelShade, shade: Palette.uiPanelShade, textColor: Palette.uiTextDark, depth: 0, enabled: false)
        } else if done {
            UiArtist.button(c, cx: vp.centerX + w * 0.32, cy: y, w: bw, h: bh, label: UiArtist.formatNumber(type.reward), pressed: pressed == i,
                             color: Palette.coin, shade: Palette.coinDark, textColor: Palette.uiTextDark, depth: 7)
        } else {
            UiArtist.button(c, cx: vp.centerX + w * 0.32, cy: y, w: bw, h: bh, label: "...", pressed: false,
                             color: Palette.uiPanelShade, shade: Palette.uiPanelShade, textColor: Palette.uiTextDark, depth: 0, enabled: false)
        }
    }

    @discardableResult
    override func onTouch(x: CGFloat, y: CGFloat, down: Bool) -> Bool {
        let w = vw
        let h = vh

        let hit: Int
        if UiArtist.hit(x, y, cx - w * 0.39, barY(h), w * 0.104, w * 0.104) {
            hit = 200
        } else if !services.daily.isLoginClaimed() && UiArtist.hit(x, y, cx, claimY(h), w * 0.36, w * 0.10) {
            hit = 100
        } else if let idx = services.daily.tasks.indices.first(where: { UiArtist.hit(x, y, cx + w * 0.32, taskY($0, h), w * 0.20, h * 0.041) }) {
            hit = idx
        } else {
            hit = -1
        }

        if down {
            pressed = hit
        } else {
            if pressed >= 0 && pressed == hit {
                services.haptics.tap()
                switch pressed {
                case 200:
                    services.sound.play(.menu)
                    pendingBack = true
                case 100:
                    let got = services.daily.claimLogin()
                    if got > 0 {
                        services.sound.play(.levelComplete)
                        toast("+\(got) coin")
                        services.analytics.event(AnalyticsEvent.dailyRewardClaimed, ["type": "login", "day": services.daily.loginStreak, "amount": got])
                    }
                default:
                    if let type = services.daily.tasks[safe: pressed] {
                        let got = services.daily.claim(type)
                        if got > 0 {
                            services.sound.play(.levelComplete)
                            toast("+\(got) coin")
                            services.analytics.event(AnalyticsEvent.dailyRewardClaimed, ["type": type.id, "amount": got])
                        }
                    }
                }
            }
            pressed = -1
        }
        return true
    }

    private func toast(_ text: String) {
        message = text
        messageTime = 1.6
    }

    override func onBack() -> Bool {
        pendingBack = true
        return true
    }
}

extension Array {
    /// Kotlin'deki `getOrNull` karsiligi - siniri disina cikarsa cokmez.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
