import UIKit

/// Oynanis ekrani. Oyunun butun dongusu burada:
/// hazirlik -> yuruyus -> dokunma -> oturma hamlesi -> karar -> sonuc.
///
/// Ekran hicbir SDK bilmez; ihtiyaci olan her seyi [Services] uzerinden alir.
/// (bkz. GameplayScreen.kt)
final class GameplayScreen: Screen {

    private let services: Services
    private var levelNumber: Int
    /// Endless modda true: bolum yerine sonsuz akis.
    private let endless: Bool

    init(services: Services, levelNumber: Int, endless: Bool = false) {
        self.services = services
        self.levelNumber = levelNumber
        self.endless = endless
    }

    var next: Screen?

    private enum Phase { case intro, walk, sitting, success, failed }

    // --- sahne ---
    private let camera = Camera()
    private let fx = Fx()
    private let animator = MikoAnimator()
    private var rivalAnimators: [MikoAnimator] = []
    private var rivalX: [CGFloat] = []
    private var rivalSpeed: [CGFloat] = []
    private var rivalSat: [Bool] = []
    private var chairs: [ChairActor] = []
    private let ctx = ChairBehaviourCtx()

    private var spec: LevelSpec = .fallback
    private var theme: Theme = .defaultTheme

    // --- durum ---
    private var phase: Phase = .intro
    private var phaseTime: CGFloat = 0
    private var totalTime: CGFloat = 0
    private var mikoX: CGFloat = 0
    private var mikoH: CGFloat = 320
    private var chairH: CGFloat = 200
    private var walkSpeed: CGFloat = 260
    private var sitStartX: CGFloat = 0
    private var tolerance: CGFloat = 70
    private var attempts = 0
    private var usedHint = false
    private var verdictResult: SitJudge.Result = .miss
    private var verdictAccuracy: CGFloat = 0
    private var earnedCoins = 0
    private var earnedStars = 0
    private var failMessage = ""
    private var failMessageIndex = 0
    private var toastText = ""
    private var toastTime: CGFloat = 0

    // --- endless ---
    private var combo = 0
    private var score = 0
    private var endlessRound = 0

    // --- reklam ---
    /// Bu bolumde "reklam izle -> devam et" hakki kullanildi mi?
    private var reviveUsed = false
    /// Reklam gosterilirken oyun donar.
    private var adInProgress = false

    // --- ui ---
    private var pressedButton = -1
    private var hudCoinX: CGFloat = 0
    private var hudCoinY: CGFloat = 0

    private let failMessages = [
        "Az kaldı!", "Sandalyeyi kaçırdın!", "Oturacaktın!", "Popo hedefi kaçırdı!",
        "Bir daha dene!", "Sandalye senden hızlı!", "Bu sandalye seni istemedi.", "Neredeyse!"
    ]

    // ------------------------------------------------------------------ giris

    func onEnter(_ vp: Viewport) {
        loadLevel(vp)
    }

    private func loadLevel(_ vp: Viewport) {
        spec = endless ? endlessSpec() : services.levels.level(levelNumber)
        theme = endless ? Theme.forLevel(1 + (endlessRound / 5) % 10) : Theme.of(spec.theme)

        mikoH = vp.designHeight * 0.168
        // Sandalye boyu Miko'ya gore TURETILIR - popo yuzeye tam otursun.
        chairH = ChairArtist.heightForSeatY(groundY: vp.groundY, seatY: MikoArtist.seatedHipY(groundY: vp.groundY, height: mikoH))

        tolerance = spec.tolerance * (services.save.data.easyMode ? 1.35 : 1)
        walkSpeed = GameConstants.mikoWalkSpeed * spec.walkSpeed

        chairs.removeAll()
        // Oyuncunun magazadan sectigi/satin aldigi sandalye GERCEK (hedef)
        // sandalyeye uygulanir - "satin aldigin sandalye oyunda gorunmuyor"
        // sikayetinin duzeltmesi. Sahte (fake) sandalyeler bolum tasarimindaki
        // kendi gorunumunu korur (zaten gercekten farkli bir stille cizilir,
        // bu yuzden kamuflaj bozulmaz - bkz. levels.json).
        let equippedChair = ChairCatalog.style(services.save.data.selectedChair)
        for cs in spec.chairs {
            let actor = ChairActor()
            let params = ChairParams(speed: cs.speed, amplitude: cs.amplitude, triggerDistance: cs.triggerDistance, period: cs.period)
            actor.reset(
                style: cs.fake ? ChairCatalog.style(cs.style) : equippedChair,
                behaviour: ChairBehaviours.create(cs.behaviour, params),
                x: vp.playX(cs.xRatio),
                y: vp.groundY,
                height: chairH
            )
            actor.fake = cs.fake
            actor.isTarget = !cs.fake
            chairs.append(actor)
        }
        // SWAP davranisi es sandalyeye ihtiyac duyar
        if chairs.count >= 2 { ctx.partner = chairs[1] }

        // Rakipler
        rivalAnimators.removeAll(); rivalX.removeAll(); rivalSpeed.removeAll(); rivalSat.removeAll()
        for i in 0..<spec.rivals {
            let a = MikoAnimator()
            a.reset()
            a.setState(.walk)
            rivalAnimators.append(a)
            rivalX.append(vp.playX(-0.30 - CGFloat(i) * 0.18))
            // Rakip oyuncudan biraz yavas - ama bekleyeni cezalandiracak kadar hizli
            rivalSpeed.append(walkSpeed * (0.72 + CGFloat(i) * 0.06))
            rivalSat.append(false)
        }

        mikoX = vp.playX(-0.16)
        animator.reset()
        animator.setState(.walk)
        camera.reset(vp.centerX)
        fx.clear()
        phase = .intro
        phaseTime = 0
        totalTime = 0
        earnedCoins = 0
        earnedStars = 0
        toastTime = 0

        if !spec.hint.isEmpty && services.save.data.starsFor(levelNumber) == 0 {
            toast(spec.hint, 2.6)
        }

        services.analytics.event(AnalyticsEvent.levelStarted, ["level": levelNumber, "endless": endless])
    }

    /// Endless modda bolum verisi calisma zamaninda uretilir.
    private func endlessSpec() -> LevelSpec {
        let r = endlessRound
        let hard = min(CGFloat(r) / 3, 12)
        let behaviours = ["STATIC", "SLIDE", "SLIDE", "ROTATE", "JUMP", "RUN", "SWAP", "FAKE", "INVISIBLE", "ROCKET", "TRAP", "MAGNET"]
        let pickCount = max(min(behaviours.count, 2 + r / 2), 1)
        let pick = behaviours[(r * 7 + r / 2) % pickCount]
        let styles = ChairCatalog.all
        let style = styles[(r * 3) % styles.count].style.id
        var chairsList: [LevelSpec.ChairSpec] = [
            LevelSpec.ChairSpec(style: style, behaviour: pick, xRatio: 0.60,
                                 speed: 0.8 + hard * 0.08, amplitude: 120 + hard * 14,
                                 triggerDistance: 250, period: max(1.5 - hard * 0.05, 0.8), fake: false)
        ]
        if r >= 6 && r % 3 == 0 {
            chairsList.append(LevelSpec.ChairSpec(
                style: styles[(r * 5) % styles.count].style.id, behaviour: "STATIC",
                xRatio: 0.30, speed: 1, amplitude: 160, triggerDistance: 260, period: 1.2, fake: true
            ))
        }
        return LevelSpec(
            id: r + 1, difficulty: 1, chairs: chairsList,
            tolerance: max(74 - hard * 3.4, 28), walkSpeed: 1 + hard * 0.03,
            speedScale: 1 + hard * 0.05, timeLimit: 0, reward: 0, special: false,
            rivals: 0, theme: "default", hint: ""
        )
    }

    // ---------------------------------------------------------------- dongu

    func update(_ dt: CGFloat, _ vp: Viewport) {
        // Reklam tam ekranda: oyun DURUR, kapaninca kaldigi yerden devam eder.
        if adInProgress { return }
        totalTime += dt
        phaseTime += dt
        services.tick(dt)
        if toastTime > 0 { toastTime -= dt }

        ctx.playerX = mikoX
        ctx.groundY = vp.groundY
        ctx.sceneWidth = vp.centerX + vp.playWidth * 0.5
        ctx.speedScale = spec.speedScale
        ctx.playerCommitted = phase == .sitting

        // Sandalyeler her fazda yasar (basari/fail ekraninda da hareket eder)
        for ch in chairs {
            ch.behaviour.update(dt: dt, chair: ch, ctx: ctx)
        }

        switch phase {
        case .intro:
            mikoX += walkSpeed * dt
            animator.update(dt)
            if phaseTime > 0.25 { setPhase(.walk) }

        case .walk:
            mikoX += walkSpeed * dt
            // MAGNET karakteri ceker
            for ch in chairs {
                if let magnet = ch.behaviour as? MagnetBehaviour { mikoX += magnet.pullThisFrame }
            }
            animator.update(dt)
            updateRivals(dt, vp)

            // Sandalyeyi gecti mi?
            if let last = chairs.max(by: { $0.x < $1.x }) {
                if mikoX > last.x + tolerance + vp.playWidth * 0.10 {
                    fail(vp, .miss, .somersault)
                }
            }
            // Rakip oturduysa kaybettin
            if rivalSat.contains(true) {
                fail(vp, .noChair, .pulledUnder)
            }

        case .sitting:
            // Oturma hamlesi sirasinda ileri atilis: hiz sifira iner.
            let p = (phaseTime / MikoAnimator.sitDuration).clamped(0, 1)
            mikoX += walkSpeed * (1 - p) * dt
            animator.update(dt)
            updateRivals(dt, vp)
            if animator.finished { resolve(vp) }

        case .success:
            animator.update(dt)
            updateRivals(dt, vp)
            if phaseTime > Self.successHold { advance(vp) }

        case .failed:
            animator.update(dt)
            updateRivals(dt, vp)
        }

        camera.follow(clampCamera(vp))
        camera.update(dt)
        fx.update(dt)

        // Girdi baska bir katmandan gelebilir; niyetleri BURADA, dongunun
        // icinde tuketiyoruz. Boylece cizim ile durum degisimi carpismaz.
        lastW = vp.uiWidth
        lastH = vp.designHeight
        lastCx = vp.centerX
        consumeIntents(vp)
    }

    private func updateRivals(_ dt: CGFloat, _ vp: Viewport) {
        for i in rivalAnimators.indices {
            if rivalSat[i] {
                rivalAnimators[i].update(dt)
                continue
            }
            guard let target = chairs.first(where: { $0.isTarget && !$0.gone }) else { continue }
            rivalX[i] += rivalSpeed[i] * dt
            if rivalX[i] >= target.x - 6 && phase != .success {
                rivalX[i] = target.x
                rivalSat[i] = true
                rivalAnimators[i].setState(.sit)
            }
            rivalAnimators[i].update(dt)
        }
    }

    private func clampCamera(_ vp: Viewport) -> CGFloat {
        // Kamera Miko ile sandalye arasinda kalir, ama ekrandan tasmaz.
        let focus = (mikoX + (chairs.first?.x ?? mikoX)) * 0.5
        let limit = vp.playWidth * 0.14
        return focus.clamped(vp.centerX - limit, vp.centerX + limit)
    }

    private func setPhase(_ p: Phase) {
        phase = p
        phaseTime = 0
    }

    // ------------------------------------------------------------- karar

    private func commitSit() {
        guard phase == .walk else { return }
        sitStartX = mikoX
        attempts += 1
        setPhase(.sitting)
        animator.setState(.sit)
        services.sound.play(.whoosh, volume: 0.5)
    }

    private func resolve(_ vp: Viewport) {
        let v = SitJudge.judge(playerX: mikoX, chairs: chairs, baseTolerance: tolerance)
        verdictResult = v.result
        verdictAccuracy = v.accuracy

        if v.success {
            succeed(vp, v)
        } else {
            let style = SitJudge.failStyleFor(result: v.result, distance: v.distance, tolerance: v.tolerance) {
                animator.pickFailStyle()
            }
            fail(vp, v.result, style)
        }
    }

    private func succeed(_ vp: Viewport, _ v: SitJudge.Verdict) {
        setPhase(.success)
        animator.setState(.celebrate)

        let chair = v.chair
        let sx = chair?.x ?? mikoX
        let sy = chair?.seatY ?? vp.groundY

        combo += 1
        services.save.data.totalSits += 1
        if combo > services.save.data.bestCombo { services.save.data.bestCombo = combo }

        let perfect = v.result == .perfect
        fx.dust(sx, vp.groundY, scale: mikoH * 0.30, strength: 0.8)
        if perfect {
            fx.burst(sx, sy, scale: mikoH * 0.34, color: Palette.coin)
            camera.setZoom(1.045)
            services.sound.play(.sitPerfect)
        } else {
            services.sound.play(.sitSuccess)
        }
        services.haptics.success()

        if endless {
            let pts = Economy.endlessPoints(combo: combo, perfect: perfect)
            score += pts
            endlessRound += 1
            if score > services.save.data.endlessHighScore {
                services.save.data.endlessHighScore = score
                services.save.markDirty()
            }
        } else {
            let firstTry = attempts <= 1
            earnedStars = Economy.starsFor(attempts: attempts, usedHint: usedHint)
            let base = Economy.levelReward(baseReward: spec.reward, stars: earnedStars, firstTry: firstTry)
            earnedCoins = Int(Double(base) * Economy.comboMultiplier(combo))
            services.wallet.add(earnedCoins)
            services.save.data.recordStars(level: levelNumber, value: earnedStars)
            services.save.data.attempts[levelNumber] = attempts
            if levelNumber >= services.save.data.unlockedLevel {
                services.save.data.unlockedLevel = min(levelNumber + 1, services.levels.count)
            }
            services.save.markDirty()

            services.daily.advance(.playLevels)
            if earnedStars >= 3 { services.daily.advance(.threeStars) }
            if perfect { services.daily.advance(.perfectSits) }
            services.daily.advance(.earnCoins, amount: earnedCoins)
            if combo >= 5 { services.daily.advance(.comboReach, amount: combo) }

            fx.coins(from: sx, sy, to: hudCoinX, hudCoinY, count: 10, scale: mikoH * 0.22)
            services.sound.play(.levelComplete)
            services.adPolicy.onLevelCompleted()
            services.ads.onLevelCompleted()
            pendingInterstitial = true
        }

        if Economy.comboTier(combo) >= 2 {
            services.haptics.combo()
            services.sound.play(.combo, volume: 1, pitch: 1 + Float(combo) * 0.05)
        }

        services.analytics.event(AnalyticsEvent.levelCompleted, [
            "level": levelNumber, "stars": earnedStars, "attempts": attempts,
            "perfect": perfect, "combo": combo, "endless": endless
        ])
    }

    private func fail(_ vp: Viewport, _ result: SitJudge.Result, _ style: MikoAnimator.FailStyle) {
        if phase == .failed || phase == .success { return }
        setPhase(.failed)
        verdictResult = result
        attempts = max(attempts, 1)
        animator.startFail(style)

        combo = 0
        camera.shake(amount: mikoH * 0.055, duration: 0.32)
        fx.dust(mikoX, vp.groundY, scale: mikoH * 0.32, strength: 1.2)
        services.sound.play(.fail)
        services.haptics.fail()

        failMessageIndex = (failMessageIndex + 1) % failMessages.count
        switch result {
        case .fakeChair: failMessage = "Bu sandalye seni istemedi."
        case .notSittable: failMessage = "Sandalye hazır değildi!"
        case .noChair: failMessage = "Sandalyeyi kaptırdın!"
        default: failMessage = failMessages[failMessageIndex]
        }

        if endless {
            services.analytics.event(AnalyticsEvent.endlessFinished, ["score": score, "rounds": endlessRound])
            services.save.markDirty()
            services.save.flush()
        }

        services.analytics.event(AnalyticsEvent.levelFailed, [
            "level": levelNumber, "reason": "\(result)", "attempts": attempts
        ])
    }

    private var pendingInterstitial = false

    private func advance(_ vp: Viewport) {
        // Gecis reklami BOLUMLER ARASINDA, sonuc ekrani kapandiktan sonra.
        // Sıklık kurallarini Services.maybeShowInterstitial uygular; kosullar
        // saglanmiyorsa aninda devam eder, oyuncu bekletilmez.
        if pendingInterstitial {
            pendingInterstitial = false
            adInProgress = true
            services.maybeShowInterstitial(placement: AdPlacement.levelDouble) { [weak self] in
                self?.adInProgress = false
            }
        }
        if endless {
            loadLevel(vp)
            return
        }
        if levelNumber >= services.levels.count {
            next = MainMenuScreen(services: services)
            return
        }
        levelNumber += 1
        attempts = 0
        usedHint = false
        reviveUsed = false
        loadLevel(vp)
    }

    /// "Reklam izle -> devam et".
    ///
    /// Odul YALNIZCA reklam tamamlanirsa verilir. Kapatilir/basarisiz olursa
    /// oyuncu fail ekraninda kalir ve hicbir sey kaybetmez.
    /// Hak bolum basina BIR kez; boylece reklam yagmuru olmaz.
    private func startRevive(_ vp: Viewport) {
        if reviveUsed { return }
        adInProgress = true
        services.showRewarded(placement: AdPlacement.failContinue) { [weak self] result in
            guard let self else { return }
            self.adInProgress = false
            if result == .earned {
                self.reviveUsed = true
                // Deneme sayisi ARTMAZ: reklam izleyen oyuncu yildiz kaybetmesin.
                self.attempts = max(self.attempts - 1, 0)
                self.pendingRetry = true
            } else {
                let msg: String
                switch result {
                case .notReady: msg = "Reklam şu an hazır değil"
                case .dismissed: msg = "Reklam tamamlanmadı"
                default: msg = "Reklam yüklenemedi"
                }
                self.toast(msg, 1.8)
            }
        }
    }

    private func retry(_ vp: Viewport) {
        if endless {
            score = 0
            endlessRound = 0
            combo = 0
            services.analytics.event(AnalyticsEvent.endlessStarted)
        }
        loadLevel(vp)
    }

    private func toast(_ text: String, _ seconds: CGFloat) {
        toastText = text
        toastTime = seconds
    }

    // ---------------------------------------------------------------- cizim

    func draw(_ c: CGContext, _ vp: Viewport) {
        SceneArtist.draw(c, vp: vp, scroll: mikoX * 0.35, time: totalTime, theme: theme)

        camera.apply(c, viewCenterX: vp.centerX, viewCenterY: vp.groundY)

        // Cizim sirasi derinligi anlatir:
        //   sandalyenin ARKASI -> karakterler -> sandalyenin ON AYAKLARI
        // Boylece oturan karakter sandalyenin ICINDE gorunur, onunde degil.
        for ch in chairs where !ch.gone && ch.alpha > 0.02 {
            ChairArtist.draw(c, x: ch.x, groundY: ch.y, height: ch.height, style: ch.style,
                              turn: ch.turn, alpha: ch.alpha, part: .back)
        }

        // Rakipler
        for i in rivalAnimators.indices {
            let a = rivalAnimators[i]
            MikoArtist.draw(c, x: rivalX[i], groundY: vp.groundY + a.offsetY, height: mikoH * 0.96,
                             pose: a.pose, skin: CharacterCatalog.rival)
        }

        // Miko
        let skin = CharacterCatalog.skin(services.save.data.selectedCharacter)
        MikoArtist.draw(c, x: mikoX + animator.offsetX, groundY: vp.groundY + animator.offsetY, height: mikoH,
                         pose: animator.pose, skin: skin)

        for ch in chairs where !ch.gone && ch.alpha > 0.02 {
            ChairArtist.draw(c, x: ch.x, groundY: ch.y, height: ch.height, style: ch.style,
                              turn: ch.turn, drawShadow: false, alpha: ch.alpha, part: .front)
        }

        fx.draw(c)
        camera.restore(c)

        drawHud(c, vp)
        drawOverlay(c, vp)
    }

    private func drawHud(_ c: CGContext, _ vp: Viewport) {
        let top = vp.safeTop + vp.designHeight * 0.030
        let badgeH = vp.uiWidth * 0.082
        hudCoinX = vp.centerX - vp.uiWidth * 0.30
        hudCoinY = top + badgeH * 0.5

        UiArtist.coinBadge(c, cx: hudCoinX, cy: hudCoinY, h: badgeH, amount: services.wallet.coins)

        // Bolum / skor
        let label = endless ? "SKOR \(score)" : "BÖLÜM \(levelNumber)"
        TextArtist.title(
            c, label, x: vp.centerX + vp.uiWidth * 0.20, y: hudCoinY + badgeH * 0.20,
            size: vp.uiWidth * 0.055,
            color: theme.darkBackdrop ? Palette.cream : Palette.cream, outlineColor: Palette.ink
        )

        // Combo
        if combo >= 2 {
            let tier = Economy.comboTier(combo)
            let pulse = 1 + sin(totalTime * 9) * 0.05
            TextArtist.title(
                c, "\(tier)x KOMBO", x: vp.centerX, y: hudCoinY + badgeH * 1.5,
                size: vp.uiWidth * 0.058 * pulse, color: Palette.coin, outlineColor: Palette.ink
            )
        }

        // Ipucu / mesaj
        if toastTime > 0 && !toastText.isEmpty {
            let a = min(toastTime / 0.5, 1)
            let y = vp.designHeight * 0.30
            UiArtist.panel(c, cx: vp.centerX, cy: y, w: vp.uiWidth * 0.84, h: vp.uiWidth * 0.17, alpha: a * 0.95)
            let size = UiArtist.fitTextSize(toastText, maxW: vp.uiWidth * 0.74, preferred: vp.uiWidth * 0.052)
            TextArtist.label(c, toastText, x: vp.centerX, y: y + size * 0.35, size: size, color: Palette.uiTextDark, alpha: a)
        }
    }

    private func drawOverlay(_ c: CGContext, _ vp: Viewport) {
        switch phase {
        case .success: drawSuccess(c, vp)
        case .failed: drawFail(c, vp)
        default:
            // Ilk bolumde dokunma ipucu
            if levelNumber == 1 && !endless && phase == .walk {
                let a = 0.55 + 0.45 * sin(totalTime * 3.4)
                TextArtist.title(
                    c, "DOKUN", x: vp.centerX, y: vp.designHeight * 0.90,
                    size: vp.uiWidth * 0.070, color: Palette.cream, outlineColor: Palette.ink, alpha: a
                )
            }
        }
    }

    private func drawSuccess(_ c: CGContext, _ vp: Viewport) {
        let t = phaseTime
        let pop = popIn(t, 0.05)
        let y = vp.designHeight * 0.26

        TextArtist.title(
            c, verdictResult == .perfect ? "TAM İSABET!" : "OTURDUN!",
            x: vp.centerX, y: y, size: vp.uiWidth * 0.115 * pop,
            color: verdictResult == .perfect ? Palette.coin : Palette.success, outlineColor: Palette.ink
        )

        if !endless {
            let pop2 = popIn(t, 0.28)
            if pop2 > 0 {
                TextArtist.title(
                    c, "+\(earnedCoins) COIN", x: vp.centerX, y: y + vp.uiWidth * 0.13,
                    size: vp.uiWidth * 0.075 * pop2, color: Palette.cream, outlineColor: Palette.ink
                )
            }
            // Yildizlar sirayla dolar
            let scales = (0..<3).map { popIn(t, 0.45 + CGFloat($0) * 0.13) }
            if scales[0] > 0 {
                UiArtist.stars(c, cx: vp.centerX, cy: y + vp.uiWidth * 0.26, r: vp.uiWidth * 0.055, count: earnedStars, popScale: scales)
            }
        } else {
            TextArtist.title(
                c, "+\(Economy.endlessPoints(combo: combo, perfect: verdictResult == .perfect))",
                x: vp.centerX, y: y + vp.uiWidth * 0.12,
                size: vp.uiWidth * 0.070 * popIn(t, 0.20), color: Palette.cream, outlineColor: Palette.ink
            )
        }
    }

    private func drawFail(_ c: CGContext, _ vp: Viewport) {
        let t = phaseTime
        let a = ((t - 0.35) / 0.30).clamped(0, 1)
        if a <= 0 { return }

        UiArtist.scrim(c, w: vp.designWidth, h: vp.designHeight, alpha: a * 0.55)

        let cy = vp.designHeight * 0.42
        let pw = vp.uiWidth * 0.86
        let showRevive = canOfferRevive()
        let ph = vp.designHeight * (showRevive ? 0.38 : 0.30)
        UiArtist.panel(c, cx: vp.centerX, cy: cy, w: pw, h: ph, alpha: a)

        let size = UiArtist.fitTextSize(failMessage, maxW: pw * 0.80, preferred: vp.uiWidth * 0.066)
        TextArtist.label(c, failMessage, x: vp.centerX, y: cy - ph * 0.32, size: size, color: Palette.uiTextDark, alpha: a)

        if endless {
            TextArtist.label(
                c, "Skor: \(score)   Rekor: \(services.save.data.endlessHighScore)",
                x: vp.centerX, y: cy - ph * 0.18, size: vp.uiWidth * 0.048, color: Palette.uiTextDark, alpha: a
            )
        }

        // "Reklam izle -> devam et": OPT-IN. Oyuncu istemezse hicbir sey olmaz.
        if showRevive {
            UiArtist.button(
                c, cx: vp.centerX, cy: reviveY(vp), w: pw * 0.78, h: vp.uiWidth * 0.145,
                label: "REKLAM İZLE → DEVAM ET", pressed: pressedButton == 2,
                color: Palette.success, shade: UIColor(hex: "#33B76B")
            )
        }

        let bw = pw * 0.42
        let bh = vp.uiWidth * 0.145
        let by = failButtonsY(vp)
        UiArtist.button(c, cx: vp.centerX - bw * 0.56, cy: by, w: bw, h: bh, label: "TEKRAR",
                         pressed: pressedButton == 0, color: Palette.orange, shade: Palette.orangeDark)
        UiArtist.button(c, cx: vp.centerX + bw * 0.56, cy: by, w: bw, h: bh, label: "MENÜ",
                         pressed: pressedButton == 1, color: Palette.uiPanel, shade: Palette.uiPanelShade, textColor: Palette.uiTextDark)
    }

    /// Devam etme teklifi kosullari:
    ///  - bolum basina EN FAZLA BIR kez
    ///  - reklam gercekten hazir olmali (yoksa oyuncuya bos umut verme)
    ///  - sonsuz modda teklif edilmez (rekorun anlami kalmaz)
    private func canOfferRevive() -> Bool {
        !reviveUsed && !endless && services.ads.isRewardedReady()
    }

    private func failPanelHeight(_ vp: Viewport) -> CGFloat {
        vp.designHeight * (canOfferRevive() ? 0.38 : 0.30)
    }

    private func reviveY(_ vp: Viewport) -> CGFloat {
        vp.designHeight * 0.42 + failPanelHeight(vp) * 0.06
    }

    private func failButtonsY(_ vp: Viewport) -> CGFloat {
        vp.designHeight * 0.42 + failPanelHeight(vp) * (canOfferRevive() ? 0.30 : 0.22)
    }

    private func popIn(_ now: CGFloat, _ start: CGFloat) -> CGFloat {
        if now < start { return 0 }
        let p = ((now - start) / 0.30).clamped(0, 1)
        return 0.70 + 0.30 * (1 - (1 - p) * (1 - p)) + sin(p * 3.1416) * 0.10
    }

    // ---------------------------------------------------------------- girdi

    @discardableResult
    func onTouch(x: CGFloat, y: CGFloat, down: Bool) -> Bool {
        if down {
            if phase == .failed {
                let uw = lastW
                let pw = uw * 0.86
                let bw = pw * 0.42
                let bh = uw * 0.145
                let revive = canOfferRevive()
                let panelH = lastH * (revive ? 0.38 : 0.30)
                let by = lastH * 0.42 + panelH * (revive ? 0.30 : 0.22)
                let ry = lastH * 0.42 + panelH * 0.06
                if revive && UiArtist.hit(x, y, lastCx, ry, pw * 0.78, bh) {
                    pressedButton = 2
                } else if UiArtist.hit(x, y, lastCx - bw * 0.56, by, bw, bh) {
                    pressedButton = 0
                } else if UiArtist.hit(x, y, lastCx + bw * 0.56, by, bw, bh) {
                    pressedButton = 1
                } else {
                    pressedButton = -1
                }
                return true
            }
            commitSit()
        } else {
            if phase == .failed && pressedButton >= 0 {
                services.sound.play(.button)
                services.haptics.tap()
                switch pressedButton {
                case 0: pendingRetry = true
                case 1: pendingMenu = true
                case 2: pendingRevive = true
                default: break
                }
            }
            pressedButton = -1
        }
        return true
    }

    func onBack() -> Bool {
        pendingMenu = true
        return true
    }

    private var pendingRetry = false
    private var pendingMenu = false
    private var pendingRevive = false
    private var lastW: CGFloat = 1080
    private var lastH: CGFloat = 1920
    private var lastCx: CGFloat = 540

    /// Girdi ile dongu arasindaki niyetler burada islenir (Kotlin'deki
    /// UI-thread/render-thread ayriminin mimari izini korur; iOS'ta ikisi de
    /// ana kuyrukta oldugu icin bir yaris durumu yoktur, ama gelecekte
    /// Android portuyla ayni desende kalmasi bakim kolayligi saglar).
    private func consumeIntents(_ vp: Viewport) {
        if pendingRevive {
            pendingRevive = false
            startRevive(vp)
        }
        if pendingRetry {
            pendingRetry = false
            retry(vp)
        }
        if pendingMenu {
            pendingMenu = false
            services.save.flush()
            next = MainMenuScreen(services: services)
        }
    }

    private static let successHold: CGFloat = 1.15
}
