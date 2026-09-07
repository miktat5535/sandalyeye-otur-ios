import UIKit

/// Arayuz cizimleri.
///
/// Sistem widget'i (UIButton, UITableView, SwiftUI) KULLANILMAZ. Sebep tercih
/// degil zorunluluk: sistem bilesenleriyle kurulan arayuz "oyun" gibi degil
/// "uygulama" gibi gorunur. Butonlar da oyunun sanat diliyle cizilir:
/// yuvarlak, koyu konturlu, altinda koyu bir taban (3B kabartma).
/// (bkz. UiArtist.kt)
enum UiArtist {

    /// Basili butonun asagi inme miktari (tasarim birimi).
    static let pressDepth: CGFloat = 8

    // ------------------------------------------------------------- buton

    /// - Parameter depth: taban kalinligi; 0 = duz (ikincil buton)
    static func button(
        _ ctx: CGContext, cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat,
        label: String, pressed: Bool,
        color: UIColor = Palette.orange, shade: UIColor = Palette.orangeDark,
        textColor: UIColor = Palette.uiTextLight,
        depth: CGFloat = 14,
        enabled: Bool = true
    ) {
        let r = h * 0.34
        let sink: CGFloat = pressed ? pressDepth : 0
        let outline = h * 0.075

        // Taban (butonun govdesi) - basilinca kisalir
        if depth > 0 {
            ctx.setFillColor(shade.withAlphaComponent(enabled ? 1 : 110.0 / 255).cgColor)
            ctx.fillRoundRect(cx: cx, cy: cy + depth - sink * 0.5, w: w, h: h, r: r)
        }

        // Ust yuzey
        ctx.setFillColor((enabled ? color : Palette.uiPanelShade).cgColor)
        ctx.fillRoundRect(cx: cx, cy: cy + sink, w: w, h: h, r: r)

        // Ust kenarda ince acik serit - plastik parlaklik
        ctx.setFillColor(UIColor.white.withAlphaComponent(0x33.0 / 255).cgColor)
        ctx.fillRoundRect(cx: cx, cy: cy + sink - h * 0.26, w: w * 0.86, h: h * 0.26, r: h * 0.13)

        ctx.setStrokeColor(Palette.uiOutline.cgColor)
        ctx.strokeRoundRect(cx: cx, cy: cy + sink, w: w, h: h, r: r, lineWidth: outline)

        if !label.isEmpty {
            let size = fitTextSize(label, maxW: w * 0.80, preferred: h * 0.46)
            let ink = enabled ? textColor : Palette.ink
            TextArtist.title(
                ctx, label, x: cx, y: cy + sink + size * 0.35, size: size,
                color: ink, outlineColor: outlineFor(ink), outlineRatio: 0.14,
                alpha: enabled ? 1 : 0.45
            )
        }
    }

    /// Metin konturu icin zit renk secer.
    ///
    /// Koyu metne koyu kontur cizilirse yazi tamamen kaybolur (beyaz butonda
    /// "MENU" boyle okunmaz olmustu). Parlaklik esigine gore acik/koyu secilir.
    static func outlineFor(_ textColor: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        textColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance < 0.55 ? Palette.cream : Palette.uiOutline
    }

    /// Buton dokunma alani testi. Gorsel kucuk olsa da alan genis tutulur.
    static func hit(_ px: CGFloat, _ py: CGFloat, _ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat, pad: CGFloat = 24) -> Bool {
        px >= cx - w / 2 - pad && px <= cx + w / 2 + pad && py >= cy - h / 2 - pad && py <= cy + h / 2 + pad
    }

    // ------------------------------------------------------------- panel

    static func panel(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat, color: UIColor = Palette.uiPanel, alpha: CGFloat = 1) {
        let r = min(h, w) * 0.10 + 24
        let a = alpha.clamped(0, 1)
        ctx.setFillColor(color.withAlphaComponent(a).cgColor)
        ctx.fillRoundRect(cx: cx, cy: cy + 10, w: w, h: h, r: r)
        ctx.setFillColor(Palette.uiPanelShade.withAlphaComponent(a).cgColor)
        ctx.fillRoundRect(cx: cx, cy: cy + 14, w: w, h: h, r: r)
        ctx.setFillColor(color.withAlphaComponent(a).cgColor)
        ctx.fillRoundRect(cx: cx, cy: cy, w: w, h: h, r: r)
        ctx.setStrokeColor(Palette.uiOutline.withAlphaComponent(a).cgColor)
        ctx.strokeRoundRect(cx: cx, cy: cy, w: w, h: h, r: r, lineWidth: 7)
    }

    /// Tam ekran karartma (modal arkasi).
    static func scrim(_ ctx: CGContext, w: CGFloat, h: CGFloat, alpha: CGFloat) {
        ctx.setFillColor(Palette.ink.withAlphaComponent((alpha * 190 / 255).clamped(0, 1)).cgColor)
        ctx.fill(CGRect(x: -w, y: -h, width: w * 3, height: h * 3))
    }

    // ------------------------------------------------------------- yildiz

    static func star(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat, filled: Bool, scale: CGFloat = 1) {
        let rr = r * scale
        var points: [CGPoint] = []
        for i in 0..<10 {
            let a = (-90 + CGFloat(i) * 36) * .pi / 180
            let rad = i % 2 == 0 ? rr : rr * 0.46
            points.append(CGPoint(x: cx + cos(a) * rad, y: cy + sin(a) * rad))
        }
        ctx.setFillColor((filled ? Palette.coin : UIColor.white.withAlphaComponent(0x55.0 / 255)).cgColor)
        ctx.fillPolygon(points)
        if filled {
            ctx.saveGState()
            ctx.clip(to: CGRect(x: cx - rr, y: cy + rr * 0.10, width: rr * 2, height: rr * 0.90))
            ctx.setFillColor(Palette.coinDark.cgColor)
            ctx.fillPolygon(points)
            ctx.restoreGState()
        }
        ctx.setStrokeColor(Palette.uiOutline.cgColor)
        ctx.strokePolygon(points, lineWidth: rr * 0.16)
    }

    /// Yildiz sirasi (bolum karti ve bolum sonu icin).
    static func stars(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat, count: Int, popScale: [CGFloat]? = nil) {
        let gap = r * 2.4
        for i in 0..<3 {
            let s = (popScale != nil && i < popScale!.count) ? popScale![i] : 1
            star(ctx, cx: cx + CGFloat(i - 1) * gap, cy: cy, r: r, filled: i < count, scale: s)
        }
    }

    // ------------------------------------------------------------- coin

    static func coin(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat) {
        ctx.setFillColor(Palette.coinDark.cgColor)
        ctx.fillEllipse(cx: cx, cy: cy + r * 0.10, rx: r, ry: r)
        ctx.setFillColor(Palette.coin.cgColor)
        ctx.fillEllipse(cx: cx, cy: cy, rx: r, ry: r)
        ctx.setStrokeColor(Palette.uiOutline.cgColor)
        ctx.strokeEllipse(cx: cx, cy: cy, rx: r, ry: r, lineWidth: r * 0.17)
        // Ic halka - madeni para okunurlugu
        ctx.strokeEllipse(cx: cx, cy: cy, rx: r * 0.56, ry: r * 0.56, lineWidth: r * 0.11)
    }

    /// Coin sayaci rozeti. Sol ust kosede.
    static func coinBadge(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, h: CGFloat, amount: Int) {
        let text = formatNumber(amount)
        let size = h * 0.52
        let tw = TextArtist.measure(text, size: size)
        let w = tw + h * 1.55
        ctx.setFillColor(Palette.uiPanel.cgColor)
        ctx.fillRoundRect(cx: cx, cy: cy, w: w, h: h, r: h * 0.5)
        ctx.setStrokeColor(Palette.uiOutline.cgColor)
        ctx.strokeRoundRect(cx: cx, cy: cy, w: w, h: h, r: h * 0.5, lineWidth: h * 0.09)
        coin(ctx, cx: cx - w * 0.5 + h * 0.50, cy: cy, r: h * 0.34)
        TextArtist.label(ctx, text, x: cx + h * 0.30, y: cy + size * 0.35, size: size, color: Palette.uiTextDark)
    }

    // ------------------------------------------------------------- ikonlar

    enum Icon { case gear, sound, mute, vibrate, back, close, character, chair, daily, shop, play, lock, restart, home }

    static func icon(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat, kind: Icon, color: UIColor = Palette.uiTextDark) {
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(r * 0.24)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setFillColor(color.cgColor)

        func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat) {
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(r * 0.24)
            ctx.move(to: CGPoint(x: x1, y: y1))
            ctx.addLine(to: CGPoint(x: x2, y: y2))
            ctx.strokePath()
        }

        switch kind {
        case .gear:
            ctx.setStrokeColor(color.cgColor)
            ctx.strokeEllipse(cx: cx, cy: cy, rx: r * 0.52, ry: r * 0.52, lineWidth: r * 0.24)
            for i in 0..<6 {
                let a = CGFloat(i) * 60 * .pi / 180
                let dx = cos(a), dy = sin(a)
                line(cx + dx * r * 0.66, cy + dy * r * 0.66, cx + dx * r * 0.98, cy + dy * r * 0.98)
            }
        case .sound, .mute:
            let poly = [
                CGPoint(x: cx - r * 0.75, y: cy - r * 0.28), CGPoint(x: cx - r * 0.30, y: cy - r * 0.28),
                CGPoint(x: cx + r * 0.10, y: cy - r * 0.72), CGPoint(x: cx + r * 0.10, y: cy + r * 0.72),
                CGPoint(x: cx - r * 0.30, y: cy + r * 0.28), CGPoint(x: cx - r * 0.75, y: cy + r * 0.28)
            ]
            ctx.setFillColor(color.cgColor)
            ctx.fillPolygon(poly)
            if kind == .sound {
                ctx.setStrokeColor(color.cgColor)
                ctx.strokeEllipse(cx: cx + r * 0.24, cy: cy, rx: r * 0.30, ry: r * 0.42, lineWidth: r * 0.24)
                ctx.strokeEllipse(cx: cx + r * 0.30, cy: cy, rx: r * 0.58, ry: r * 0.78, lineWidth: r * 0.24)
            } else {
                line(cx + r * 0.34, cy - r * 0.34, cx + r * 0.92, cy + r * 0.34)
                line(cx + r * 0.92, cy - r * 0.34, cx + r * 0.34, cy + r * 0.34)
            }
        case .vibrate:
            ctx.setStrokeColor(color.cgColor)
            ctx.strokeRoundRect(cx: cx, cy: cy, w: r * 0.72, h: r * 1.34, r: r * 0.20, lineWidth: r * 0.24)
            line(cx - r * 0.86, cy - r * 0.30, cx - r * 0.86, cy + r * 0.30)
            line(cx + r * 0.86, cy - r * 0.30, cx + r * 0.86, cy + r * 0.30)
        case .back:
            line(cx + r * 0.40, cy - r * 0.60, cx - r * 0.30, cy)
            line(cx - r * 0.30, cy, cx + r * 0.40, cy + r * 0.60)
        case .close:
            line(cx - r * 0.55, cy - r * 0.55, cx + r * 0.55, cy + r * 0.55)
            line(cx + r * 0.55, cy - r * 0.55, cx - r * 0.55, cy + r * 0.55)
        case .character:
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(cx: cx, cy: cy - r * 0.36, rx: r * 0.42, ry: r * 0.42)
            ctx.fillRoundRect(cx: cx, cy: cy + r * 0.48, w: r * 1.06, h: r * 0.78, r: r * 0.36)
        case .chair:
            ctx.setFillColor(color.cgColor)
            ctx.fillRoundRect(cx: cx, cy: cy - r * 0.42, w: r * 0.90, h: r * 0.66, r: r * 0.22)
            ctx.fillRoundRect(cx: cx, cy: cy + r * 0.08, w: r * 1.20, h: r * 0.24, r: r * 0.12)
            line(cx - r * 0.46, cy + r * 0.20, cx - r * 0.46, cy + r * 0.82)
            line(cx + r * 0.46, cy + r * 0.20, cx + r * 0.46, cy + r * 0.82)
        case .daily:
            ctx.setStrokeColor(color.cgColor)
            ctx.strokeRoundRect(cx: cx, cy: cy + r * 0.12, w: r * 1.36, h: r * 1.24, r: r * 0.20, lineWidth: r * 0.24)
            line(cx - r * 0.68, cy - r * 0.18, cx + r * 0.68, cy - r * 0.18)
            line(cx - r * 0.38, cy - r * 0.50, cx - r * 0.38, cy - r * 0.78)
            line(cx + r * 0.38, cy - r * 0.50, cx + r * 0.38, cy - r * 0.78)
        case .shop:
            ctx.setFillColor(color.cgColor)
            ctx.fillRoundRect(cx: cx, cy: cy + r * 0.22, w: r * 1.24, h: r * 1.10, r: r * 0.18)
            ctx.setStrokeColor(Palette.uiPanel.cgColor)
            ctx.strokeEllipse(cx: cx, cy: cy - r * 0.20, rx: r * 0.40, ry: r * 0.46, lineWidth: r * 0.24)
        case .play:
            ctx.setFillColor(color.cgColor)
            ctx.fillPolygon([
                CGPoint(x: cx - r * 0.42, y: cy - r * 0.66), CGPoint(x: cx + r * 0.62, y: cy),
                CGPoint(x: cx - r * 0.42, y: cy + r * 0.66)
            ])
        case .lock:
            ctx.setFillColor(color.cgColor)
            ctx.fillRoundRect(cx: cx, cy: cy + r * 0.28, w: r * 1.10, h: r * 0.94, r: r * 0.20)
            ctx.setStrokeColor(color.cgColor)
            ctx.strokeEllipse(cx: cx, cy: cy - r * 0.34, rx: r * 0.44, ry: r * 0.44, lineWidth: r * 0.24)
        case .restart:
            ctx.setStrokeColor(color.cgColor)
            ctx.strokeEllipse(cx: cx, cy: cy, rx: r * 0.62, ry: r * 0.62, lineWidth: r * 0.24)
            ctx.setFillColor(color.cgColor)
            ctx.fillPolygon([
                CGPoint(x: cx + r * 0.30, y: cy - r * 0.92), CGPoint(x: cx + r * 0.92, y: cy - r * 0.50),
                CGPoint(x: cx + r * 0.26, y: cy - r * 0.30)
            ])
        case .home:
            ctx.setFillColor(color.cgColor)
            ctx.fillPolygon([
                CGPoint(x: cx, y: cy - r * 0.80), CGPoint(x: cx + r * 0.90, y: cy - r * 0.02),
                CGPoint(x: cx - r * 0.90, y: cy - r * 0.02)
            ])
            ctx.fillRoundRect(cx: cx, cy: cy + r * 0.40, w: r * 1.20, h: r * 0.84, r: r * 0.14)
        }
    }

    /// Yuvarlak ikon butonu.
    static func iconButton(
        _ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat, kind: Icon,
        pressed: Bool, bg: UIColor = Palette.uiPanel, tint: UIColor = Palette.uiTextDark
    ) {
        let sink: CGFloat = pressed ? pressDepth * 0.6 : 0
        ctx.setFillColor(Palette.uiPanelShade.cgColor)
        ctx.fillEllipse(cx: cx, cy: cy + r * 0.16, rx: r, ry: r)
        ctx.setFillColor(bg.cgColor)
        ctx.fillEllipse(cx: cx, cy: cy + sink, rx: r, ry: r)
        ctx.setStrokeColor(Palette.uiOutline.cgColor)
        ctx.strokeEllipse(cx: cx, cy: cy + sink, rx: r, ry: r, lineWidth: r * 0.15)
        icon(ctx, cx: cx, cy: cy + sink, r: r * 0.62, kind: kind, color: tint)
    }

    // ------------------------------------------------------------- yardimci

    /// Metni verilen kutuya sigdiran yazi boyutu.
    static func fitTextSize(_ text: String, maxW: CGFloat, preferred: CGFloat) -> CGFloat {
        if text.isEmpty { return preferred }
        let w = TextArtist.measure(text, size: preferred)
        return w <= maxW ? preferred : preferred * (maxW / w)
    }

    /// 12500 -> "12.5B" gibi kisa gosterim.
    static func formatNumber(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 10_000 { return String(format: "%.1fB", Double(n) / 1000) }
        return String(n)
    }

    /// Ilerleme cubugu.
    static func progressBar(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat, p: CGFloat, color: UIColor = Palette.success) {
        ctx.setFillColor(Palette.uiPanelShade.cgColor)
        ctx.fillRoundRect(cx: cx, cy: cy, w: w, h: h, r: h * 0.5)
        let fillW = (w - h * 0.3) * p.clamped(0, 1)
        if fillW > h * 0.4 {
            ctx.setFillColor(color.cgColor)
            let rect = CGRect(x: cx - w / 2 + h * 0.15, y: cy - h * 0.35, width: fillW, height: h * 0.70)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: h * 0.35)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
        }
        ctx.setStrokeColor(Palette.uiOutline.cgColor)
        ctx.strokeRoundRect(cx: cx, cy: cy, w: w, h: h, r: h * 0.5, lineWidth: h * 0.16)
    }
}
