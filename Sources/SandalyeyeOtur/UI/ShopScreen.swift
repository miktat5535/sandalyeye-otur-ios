import UIKit

/// Magaza: karakterler, sandalyeler ve coin paketleri.
///
/// Kozmetikler coin ile acilir; gercek para YALNIZCA coin paketleri ve iki
/// premium skin icin. Hicbir bolum burada satilmaz. (bkz. ShopScreen.kt)
final class ShopScreen: BaseScreen {
    private let services: Services
    private var tab: Tab

    enum Tab { case characters, chairs, coins }

    private var scroll: CGFloat = 0
    private var scrollVel: CGFloat = 0
    private var dragging = false
    private var dragStartY: CGFloat = 0
    private var lastDragY: CGFloat = 0
    private var dragStartScroll: CGFloat = 0
    private var moved: CGFloat = 0
    private var pressedIndex = -1
    private var pressedTab = -1
    private var pressedBack = false
    private var pendingBack = false
    private var t: CGFloat = 0
    private var message = ""
    private var messageTime: CGFloat = 0
    private var idlePose: Pose = {
        var p = Pose()
        p.face = .happy
        return p
    }()

    init(services: Services, tab: Tab) {
        self.services = services
        self.tab = tab
        super.init()
    }

    override func onEnter(_ vp: Viewport) {
        scroll = 0
        services.analytics.event(AnalyticsEvent.shopOpened, ["tab": "\(tab)"])
    }

    private func cardH(_ w: CGFloat) -> CGFloat { w * 0.30 }
    private func listTop(_ h: CGFloat) -> CGFloat { safeTop + h * 0.20 }

    override func onUpdate(_ dt: CGFloat, _ vp: Viewport) {
        t += dt
        services.tick(dt)
        if messageTime > 0 { messageTime -= dt }

        if !dragging {
            scroll += scrollVel * dt
            scrollVel *= pow(0.06, dt)
            if abs(scrollVel) < 4 { scrollVel = 0 }
            let maxS = maxScroll(vp)
            if scroll < 0 { scroll += (0 - scroll) * dt * 12; scrollVel = 0 }
            else if scroll > maxS { scroll += (maxS - scroll) * dt * 12; scrollVel = 0 }
        }

        if pendingBack {
            pendingBack = false
            next = MainMenuScreen(services: services)
        }
    }

    private func itemCount() -> Int {
        switch tab {
        case .characters: return CharacterCatalog.all.count
        case .chairs: return ChairCatalog.all.count
        case .coins: return IapProduct.all.count
        }
    }

    private func maxScroll(_ vp: Viewport) -> CGFloat {
        let contentH = CGFloat(itemCount()) * (cardH(vp.uiWidth) * 1.12)
        let viewH = vp.designHeight - listTop(vp.designHeight) - safeBottom - vp.designHeight * 0.03
        return max(contentH - viewH, 0)
    }

    override func draw(_ c: CGContext, _ vp: Viewport) {
        let w = vp.uiWidth
        let h = vp.designHeight
        SceneArtist.draw(c, vp: vp, scroll: 0, time: t, theme: .defaultTheme)
        UiArtist.scrim(c, w: vp.designWidth, h: h, alpha: 0.32)

        let ch = cardH(w)
        let step = ch * 1.12
        let top = listTop(h)
        let clipBottom = h - safeBottom - h * 0.02

        c.saveGState()
        c.clip(to: CGRect(x: 0, y: top - ch * 0.6, width: vp.designWidth, height: clipBottom - (top - ch * 0.6)))
        for i in 0..<itemCount() {
            let y = top + CGFloat(i) * step - scroll + ch / 2
            if y < top - ch || y > clipBottom + ch { continue }
            switch tab {
            case .characters: drawCharacterCard(c, vp, y: y, ch: ch, i: i)
            case .chairs: drawChairCard(c, vp, y: y, ch: ch, i: i)
            case .coins: drawCoinCard(c, vp, y: y, ch: ch, i: i)
            }
        }
        c.restoreGState()

        // --- Ust bar ---
        UiArtist.panel(c, cx: vp.centerX, cy: safeTop + h * 0.055, w: vp.designWidth * 1.3, h: h * 0.09)
        UiArtist.iconButton(c, cx: vp.centerX - w * 0.39, cy: safeTop + h * 0.055, r: w * 0.052, kind: .back, pressed: pressedBack)
        UiArtist.coinBadge(c, cx: vp.centerX + w * 0.22, cy: safeTop + h * 0.055, h: w * 0.078, amount: services.wallet.coins)

        // --- Sekmeler ---
        let tabYPos = safeTop + h * 0.135
        let tw = w * 0.30
        let th = w * 0.105
        drawTab(c, x: vp.centerX - tw * 1.04, y: tabYPos, w: tw, h: th, label: "KARAKTER", which: .characters)
        drawTab(c, x: vp.centerX, y: tabYPos, w: tw, h: th, label: "SANDALYE", which: .chairs)
        drawTab(c, x: vp.centerX + tw * 1.04, y: tabYPos, w: tw, h: th, label: "COIN", which: .coins)

        if messageTime > 0 {
            let a = min(messageTime / 0.4, 1)
            UiArtist.panel(c, cx: vp.centerX, cy: h * 0.80, w: w * 0.80, h: w * 0.15, alpha: a * 0.95)
            TextArtist.label(c, message, x: vp.centerX, y: h * 0.80 + w * 0.018, size: w * 0.048, color: Palette.uiTextDark, alpha: a)
        }
    }

    private func drawTab(_ c: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, label: String, which: Tab) {
        let active = tab == which
        UiArtist.button(
            c, cx: x, cy: y, w: w, h: h, label: label, pressed: pressedTab == tabIndex(which),
            color: active ? Palette.orange : Palette.uiPanel,
            shade: active ? Palette.orangeDark : Palette.uiPanelShade,
            textColor: active ? Palette.uiTextLight : Palette.uiTextDark,
            depth: 8
        )
    }

    private func tabIndex(_ t: Tab) -> Int {
        switch t {
        case .characters: return 0
        case .chairs: return 1
        case .coins: return 2
        }
    }

    // ------------------------------------------------------------ kartlar

    private func drawCharacterCard(_ c: CGContext, _ vp: Viewport, y: CGFloat, ch: CGFloat, i: Int) {
        let e = CharacterCatalog.all[i]
        let owned = services.save.data.unlockedCharacters.contains(e.skin.id)
        let selected = e.skin.id == services.save.data.selectedCharacter
        card(c, vp, y: y, ch: ch, i: i, name: e.skin.displayName, price: e.price, owned: owned, selected: selected)
        // Onizleme: gercek karakter, gercek cizim
        MikoArtist.draw(c, x: vp.centerX - vp.uiWidth * 0.30, groundY: y + ch * 0.34, height: ch * 0.80, pose: idlePose, skin: e.skin, drawShadow: false)
    }

    private func drawChairCard(_ c: CGContext, _ vp: Viewport, y: CGFloat, ch: CGFloat, i: Int) {
        let e = ChairCatalog.all[i]
        let owned = services.save.data.unlockedChairs.contains(e.style.id)
        let selected = e.style.id == services.save.data.selectedChair
        card(c, vp, y: y, ch: ch, i: i, name: e.style.displayName, price: e.price, owned: owned, selected: selected)
        ChairArtist.draw(c, x: vp.centerX - vp.uiWidth * 0.30, groundY: y + ch * 0.34, height: ch * 0.62, style: e.style, turn: 0.12, drawShadow: false)
    }

    private func drawCoinCard(_ c: CGContext, _ vp: Viewport, y: CGFloat, ch: CGFloat, i: Int) {
        let id = IapProduct.all[i]
        let product = services.billing.products().first { $0.id == id }
        let amount = IapProduct.coinAmount[id]
        let name: String
        switch id {
        case IapProduct.removeAds: name = "Reklamları Kaldır"
        case IapProduct.starterPack: name = "Başlangıç Paketi"
        case IapProduct.premiumSkin01: name = "Özel Karakter 1"
        case IapProduct.premiumSkin02: name = "Özel Karakter 2"
        default: name = "\(amount ?? 0) Coin"
        }
        let w = vp.uiWidth
        UiArtist.panel(c, cx: vp.centerX, cy: y, w: w * 0.88, h: ch)
        if amount != nil {
            UiArtist.coin(c, cx: vp.centerX - w * 0.30, cy: y, r: ch * 0.28)
        } else {
            UiArtist.icon(c, cx: vp.centerX - w * 0.30, cy: y, r: ch * 0.28, kind: .shop, color: Palette.orange)
        }
        let nameSize = UiArtist.fitTextSize(name, maxW: w * 0.30, preferred: w * 0.052)
        TextArtist.label(c, name, x: vp.centerX - w * 0.14, y: y - ch * 0.04, size: nameSize, color: Palette.uiTextDark, align: .left)

        // Fiyat App Store'dan gelir; yoksa "-" gosterilir. Koda fiyat YAZILMAZ.
        let price = product?.formattedPrice ?? ""
        let bw = w * 0.24
        let bh = ch * 0.46
        UiArtist.button(
            c, cx: vp.centerX + w * 0.28, cy: y, w: bw, h: bh,
            label: price.isEmpty ? "-" : price, pressed: pressedIndex == i,
            color: Palette.success, shade: UIColor(hex: "#33B76B"), depth: 7, enabled: !price.isEmpty
        )
        if price.isEmpty && i == 0 {
            TextArtist.label(c, "Mağaza bağlantısı yok", x: vp.centerX - w * 0.14, y: y + ch * 0.22, size: w * 0.036, color: Palette.fail, align: .left)
        }
    }

    private func card(_ c: CGContext, _ vp: Viewport, y: CGFloat, ch: CGFloat, i: Int, name: String, price: Int, owned: Bool, selected: Bool) {
        let w = vp.uiWidth
        UiArtist.panel(c, cx: vp.centerX, cy: y, w: w * 0.88, h: ch)

        if selected {
            c.setStrokeColor(Palette.success.cgColor)
            c.strokeRoundRect(cx: vp.centerX, cy: y, w: w * 0.88 - 10, h: ch - 10, r: ch * 0.16, lineWidth: w * 0.011)
        }

        let nameSize = UiArtist.fitTextSize(name, maxW: w * 0.30, preferred: w * 0.052)
        TextArtist.label(c, name, x: vp.centerX - w * 0.14, y: y - ch * 0.06, size: nameSize, color: Palette.uiTextDark, align: .left)

        let bw = w * 0.24
        let bh = ch * 0.46
        if selected {
            UiArtist.button(c, cx: vp.centerX + w * 0.28, cy: y, w: bw, h: bh, label: "SEÇİLİ", pressed: false,
                             color: Palette.uiPanelShade, shade: Palette.uiPanelShade, textColor: Palette.uiTextDark, depth: 0, enabled: false)
        } else if owned {
            UiArtist.button(c, cx: vp.centerX + w * 0.28, cy: y, w: bw, h: bh, label: "SEÇ", pressed: pressedIndex == i,
                             color: Palette.success, shade: UIColor(hex: "#33B76B"), depth: 7)
        } else {
            UiArtist.button(
                c, cx: vp.centerX + w * 0.28, cy: y, w: bw, h: bh, label: UiArtist.formatNumber(price), pressed: pressedIndex == i,
                color: services.wallet.canAfford(price) ? Palette.coin : Palette.uiPanelShade,
                shade: Palette.coinDark, textColor: Palette.uiTextDark, depth: 7
            )
        }
    }

    // ------------------------------------------------------------- girdi

    @discardableResult
    override func onTouch(x: CGFloat, y: CGFloat, down: Bool) -> Bool {
        let w = vw
        let h = vh
        let tabYPos = safeTop + h * 0.135
        let tw = w * 0.30
        let th = w * 0.105

        if down {
            pressedBack = UiArtist.hit(x, y, cx - w * 0.39, safeTop + h * 0.055, w * 0.104, w * 0.104)
            if pressedBack { return true }
            if UiArtist.hit(x, y, cx - tw * 1.04, tabYPos, tw, th) {
                pressedTab = tabIndex(.characters)
            } else if UiArtist.hit(x, y, cx, tabYPos, tw, th) {
                pressedTab = tabIndex(.chairs)
            } else if UiArtist.hit(x, y, cx + tw * 1.04, tabYPos, tw, th) {
                pressedTab = tabIndex(.coins)
            } else {
                pressedTab = -1
            }
            if pressedTab >= 0 { return true }
            dragging = true
            dragStartY = y
            lastDragY = y
            dragStartScroll = scroll
            moved = 0
            scrollVel = 0
            pressedIndex = itemAt(y)
        } else {
            if pressedBack {
                pressedBack = false
                services.sound.play(.menu)
                pendingBack = true
                return true
            }
            if pressedTab >= 0 {
                let newTab: Tab = pressedTab == 0 ? .characters : (pressedTab == 1 ? .chairs : .coins)
                if newTab != tab {
                    tab = newTab
                    scroll = 0
                    scrollVel = 0
                    services.sound.play(.menu)
                }
                pressedTab = -1
                return true
            }
            dragging = false
            if moved < w * 0.03 && pressedIndex >= 0 {
                let ch = cardH(w)
                let yy = listTop(h) + CGFloat(pressedIndex) * (ch * 1.12) - scroll + ch / 2
                if UiArtist.hit(x, y, cx + w * 0.28, yy, w * 0.24, ch * 0.46) {
                    activate(pressedIndex)
                }
            }
            pressedIndex = -1
        }
        return true
    }

    override func onTouchMoved(x: CGFloat, y: CGFloat) {
        guard dragging else { return }
        let dy = y - lastDragY
        lastDragY = y
        moved += abs(dy)
        scroll = dragStartScroll - (y - dragStartY)
        if moved > vw * 0.03 { pressedIndex = -1 }
        scrollVel = -dy * 14
    }

    override func onTouchCancelled() {
        dragging = false; pressedIndex = -1; pressedTab = -1; pressedBack = false
    }

    private func itemAt(_ y: CGFloat) -> Int {
        let ch = cardH(vw)
        let idx = Int((y + scroll - listTop(vh)) / (ch * 1.12))
        return (0..<itemCount()).contains(idx) ? idx : -1
    }

    private func activate(_ i: Int) {
        services.haptics.tap()
        switch tab {
        case .characters:
            let e = CharacterCatalog.all[i]
            let d = services.save.data
            if d.unlockedCharacters.contains(e.skin.id) {
                d.selectedCharacter = e.skin.id
                services.save.markDirty()
                services.sound.play(.button)
            } else if services.wallet.spend(e.price) {
                d.unlockedCharacters.insert(e.skin.id)
                d.selectedCharacter = e.skin.id
                services.save.markDirty()
                services.save.flush()
                services.sound.play(.levelComplete)
                services.analytics.event(AnalyticsEvent.skinUnlocked, ["type": "character", "id": e.skin.id, "price": e.price])
                toast("\(e.skin.displayName) açıldı!")
            } else {
                toast("Yeterli coin yok")
                services.sound.play(.fail, volume: 0.5)
            }

        case .chairs:
            let e = ChairCatalog.all[i]
            let d = services.save.data
            if d.unlockedChairs.contains(e.style.id) {
                d.selectedChair = e.style.id
                services.save.markDirty()
                services.sound.play(.button)
            } else if services.wallet.spend(e.price) {
                d.unlockedChairs.insert(e.style.id)
                d.selectedChair = e.style.id
                services.save.markDirty()
                services.save.flush()
                services.sound.play(.levelComplete)
                services.analytics.event(AnalyticsEvent.skinUnlocked, ["type": "chair", "id": e.style.id, "price": e.price])
                toast("\(e.style.displayName) açıldı!")
            } else {
                toast("Yeterli coin yok")
                services.sound.play(.fail, volume: 0.5)
            }

        case .coins:
            let productId = IapProduct.all[i]
            guard services.presenter != nil else {
                toast("Mağaza şu an kullanılamıyor")
                return
            }
            services.analytics.event(AnalyticsEvent.purchaseStarted, ["product": productId])
            services.billing.purchase(productId: productId) { [weak self] status in
                guard let self else { return }
                // Odul zaten PurchaseGranter tarafindan verildi; burada
                // yalnizca kullaniciya sonucu bildiriyoruz.
                switch status {
                case .ok:
                    self.services.sound.play(.levelComplete)
                    self.toast("Satın alma tamamlandı!")
                    self.services.analytics.event(AnalyticsEvent.purchaseCompleted, ["product": productId])
                case .alreadyOwned: self.toast("Bu ürün zaten sizde")
                case .cancelled: self.toast("Satın alma iptal edildi")
                case .unavailable: self.toast("Mağaza bağlantısı yok")
                case .error: self.toast("Satın alma başarısız")
                }
            }
        }
    }

    private func toast(_ text: String) {
        message = text
        messageTime = 1.8
    }

    override func onBack() -> Bool {
        pendingBack = true
        return true
    }
}
