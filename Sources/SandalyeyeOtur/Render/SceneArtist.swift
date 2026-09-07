import UIKit

/// Arka plan sahnesi: gokyuzu, gunes, bulutlar, tepeler ve PERSPEKTIF ZEMIN.
///
/// Derinlik hissi uc katmandan gelir:
///  1) Gokyuzu gradyani
///  2) Farkli hizda kayan iki tepe katmani (parallax)
///  3) Zemindeki KACIS NOKTASINA yakinsayan cizgiler - tek basina en guclu ipucu
///
/// Renkler [Theme] uzerinden gelir; her 10 bolumde bir tema degisir.
/// (bkz. SceneArtist.kt)
enum SceneArtist {

    /// Sahne genisligi: kamera hareket edebilsin diye ekrandan genis cizeriz.
    private static let overdraw: CGFloat = 0.45

    static func draw(_ ctx: CGContext, vp: Viewport, scroll: CGFloat, time: CGFloat, theme: Theme = .defaultTheme) {
        let w = vp.designWidth
        let h = vp.designHeight
        let horizon = vp.horizonY
        let ground = vp.groundY
        let left = -w * overdraw
        let right = w * (1 + overdraw)

        // ---------- GOKYUZU ----------
        ctx.saveGState()
        ctx.clip(to: CGRect(x: left, y: -h, width: right - left, height: horizon + 2 - (-h)))
        let colors = [theme.skyTop.cgColor, theme.skyBottom.cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
            ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: horizon),
                                    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        }
        ctx.restoreGState()

        // ---------- GUNES / AY ----------
        if theme.sunAlpha > 0.02 {
            ctx.setFillColor(UIColor.white.withAlphaComponent(theme.sunAlpha * 0.40).cgColor)
            ctx.fillEllipse(cx: w * 0.78, cy: horizon * 0.28, rx: w * 0.16, ry: w * 0.16)
            ctx.setFillColor(theme.sunColor.withAlphaComponent(theme.sunAlpha.clamped(0, 1)).cgColor)
            ctx.fillEllipse(cx: w * 0.78, cy: horizon * 0.28, rx: w * 0.10, ry: w * 0.10)
        }

        // ---------- BULUTLAR ----------
        ctx.setFillColor(UIColor.white.withAlphaComponent(theme.cloudAlpha).cgColor)
        let cs = -scroll * 0.06
        drawCloud(ctx, wrap(w * 0.18 + cs, w), horizon * 0.22 + sin(time * 0.5) * 6, w * 0.13)
        drawCloud(ctx, wrap(w * 0.62 + cs * 1.3, w), horizon * 0.40 + sin(time * 0.4 + 2) * 5, w * 0.10)
        drawCloud(ctx, wrap(w * 1.05 + cs * 0.8, w), horizon * 0.14, w * 0.16)

        // ---------- TEPELER ----------
        ctx.setFillColor(theme.hillFar.cgColor)
        drawHills(ctx, w: w, horizon: horizon, offset: -scroll * 0.12, height: horizon * 0.16, count: 3)
        ctx.setFillColor(theme.hillNear.cgColor)
        drawHills(ctx, w: w, horizon: horizon, offset: -scroll * 0.22, height: horizon * 0.10, count: 4)

        // ---------- ZEMIN ----------
        ctx.setFillColor(theme.floor.cgColor)
        ctx.fill(CGRect(x: left, y: horizon, width: right - left, height: h * 2 - horizon))

        // Yatay seritler ufka dogru INCELIR (karesel dagilim = perspektif)
        ctx.setFillColor(theme.floorStripe.cgColor)
        let depth = h - horizon
        var i = 0
        while i < 14 {
            if i % 2 == 0 {
                let f0 = CGFloat(i) / 14
                let f1 = CGFloat(i + 1) / 14
                let y0 = horizon + depth * f0 * f0
                let y1 = horizon + depth * f1 * f1
                ctx.fill(CGRect(x: left, y: y0, width: right - left, height: y1 - y0))
            }
            i += 1
        }

        // KACIS NOKTASINA yakinsayan cizgiler
        let vpX = w * 0.5
        ctx.setFillColor(theme.floorEdge.withAlphaComponent(70.0 / 255).cgColor)
        var k = -5
        while k <= 5 {
            if k != 0 {
                let bottomX = vpX + CGFloat(k) * w * 0.42 - (scroll * 0.35).truncatingRemainder(dividingBy: w * 0.42)
                ctx.fillPolygon([
                    CGPoint(x: bottomX, y: h * 1.4),
                    CGPoint(x: bottomX + w * 0.026, y: h * 1.4),
                    CGPoint(x: vpX, y: horizon)
                ])
            }
            k += 1
        }

        // Ufuk cizgisi
        ctx.setFillColor(theme.floorEdge.cgColor)
        ctx.fill(CGRect(x: left, y: horizon, width: right - left, height: h * 0.006))

        // Oyun bandinin hafif vurgusu - oyuncu nereye bakacagini bilsin
        ctx.setFillColor(UIColor.white.withAlphaComponent(theme.darkBackdrop ? CGFloat(0x18) / 255 : CGFloat(0x14) / 255).cgColor)
        ctx.fill(CGRect(x: left, y: ground - h * 0.10, width: right - left, height: h * 0.13))
    }

    private static func wrap(_ x: CGFloat, _ w: CGFloat) -> CGFloat {
        var v = x
        let span = w * 1.4
        while v < -span * 0.2 { v += span }
        while v > span { v -= span }
        return v
    }

    private static func drawCloud(_ ctx: CGContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
        ctx.fillEllipse(cx: cx, cy: cy, rx: r * 0.62, ry: r * 0.42)
        ctx.fillEllipse(cx: cx - r * 0.45, cy: cy + r * 0.10, rx: r * 0.40, ry: r * 0.28)
        ctx.fillEllipse(cx: cx + r * 0.45, cy: cy + r * 0.08, rx: r * 0.44, ry: r * 0.30)
    }

    private static func drawHills(_ ctx: CGContext, w: CGFloat, horizon: CGFloat, offset: CGFloat, height: CGFloat, count: Int) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -w * 0.6, y: horizon + 4))
        let step = w / CGFloat(count)
        var i = -2
        while i <= count + 2 {
            let cx = CGFloat(i) * step + offset.truncatingRemainder(dividingBy: step * 2)
            path.addQuadCurve(to: CGPoint(x: cx + step, y: horizon + 4),
                               control: CGPoint(x: cx + step * 0.5, y: horizon - height))
            i += 1
        }
        path.addLine(to: CGPoint(x: w * 1.7, y: horizon + 8))
        path.closeSubpath()
        ctx.addPath(path)
        ctx.fillPath()
    }
}
