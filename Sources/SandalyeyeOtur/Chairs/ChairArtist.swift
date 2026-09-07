import UIKit

/// Sandalyeyi 2.5D olarak cizer.
///
/// "2.5D" burada su demek: sahne duz yandan degil, hafif YUKARIDAN-YANDAN
/// gorunur. Oturma yuzeyi bir yamuk (trapez) olarak cizilir; on kenar arka
/// kenardan genis olur. Beyin bunu derinlik olarak okur, ama maliyeti sifirdir.
///
/// Referans nokta: (x, groundY) = sandalyenin ayaklarinin yere degdigi orta nokta.
/// Toplam yukseklik H icin oranlar:
///   oturma yuzeyi ust hizasi   groundY - 0.46 H
///   oturma yuzeyi genisligi    0.72 H  (on kenar), 0.60 H (arka kenar)
///   sirtlik ust hizasi         groundY - 1.00 H
/// (bkz. ChairArtist.kt)
enum ChairArtist {

    static let rSeatTop: CGFloat = 0.40
    private static let rSeatWFront: CGFloat = 0.72
    private static let rSeatWBack: CGFloat = 0.60
    private static let rSeatThick: CGFloat = 0.10
    private static let rLegThick: CGFloat = 0.055
    private static let rBackW: CGFloat = 0.56

    /// Karakterin popo hedefi: oturma yuzeyinin merkezi.
    static func seatY(groundY: CGFloat, height: CGFloat) -> CGFloat {
        groundY - rSeatTop * height
    }

    /// [seatY]'nin tersi: oturma yuzeyi tam olarak [seatY] hizasinda olsun
    /// istiyorsak sandalyenin boyu ne olmali?
    ///
    /// Sandalye boyunu elle secmek yerine bunu kullaniriz; boylece Miko'nun
    /// poposu ile oturma yuzeyi HER ZAMAN ayni yerdedir, ekran orani ne olursa
    /// olsun. Iki sabiti elle senkron tutma derdi kalmaz.
    static func heightForSeatY(groundY: CGFloat, seatY: CGFloat) -> CGFloat {
        (groundY - seatY) / rSeatTop
    }

    /// Sandalyenin hangi parcasinin cizilecegi.
    ///
    /// Karakter sandalyeye OTURDUGUNDA arkasi sirtligin onunde, bacaklari ise
    /// on ayaklarin ARKASINDA olmalidir. Tek seferde cizilirse karakter
    /// sandalyenin onunde duruyormus gibi gorunur - oturdugu okunmaz.
    /// Bu yuzden cizim boyle siralanir:  BACK -> karakter -> FRONT
    enum Part { case all, back, front }

    static func draw(
        _ ctx: CGContext, x: CGFloat, groundY: CGFloat, height: CGFloat,
        style: ChairStyle,
        /// 0 = tam onden, +1 = saga donuk, -1 = sola donuk (ROTATE mekanigi icin)
        turn: CGFloat = 0,
        drawShadow: Bool = true,
        /// 0..1 gorunurluk. INVISIBLE ve FAKE mekanikleri kullanir.
        alpha: CGFloat = 1,
        part: Part = .all
    ) {
        if alpha <= 0.01 { return }
        if alpha >= 0.995 {
            drawInner(ctx, x: x, groundY: groundY, height: height, style: style,
                      turn: turn, drawShadow: drawShadow, part: part)
            return
        }
        // CGContext.setAlpha tek basina ustuste binen dolgu+konturu ayri ayri
        // saydamlastirir (Android'de Paint.alpha'nin ise yaramamasiyla ayni
        // sorun) — bu yuzden bir seffaflik katmani icinde ciziyoruz, boylece
        // katmanin tamami TEK seferde `alpha` ile composite edilir.
        ctx.saveGState()
        ctx.setAlpha(alpha)
        ctx.beginTransparencyLayer(auxiliaryInfo: nil)
        drawInner(ctx, x: x, groundY: groundY, height: height, style: style,
                  turn: turn, drawShadow: drawShadow, part: part)
        ctx.endTransparencyLayer()
        ctx.restoreGState()
    }

    private static func drawInner(
        _ ctx: CGContext, x: CGFloat, groundY: CGFloat, height: CGFloat,
        style: ChairStyle, turn: CGFloat, drawShadow: Bool, part: Part
    ) {
        let drawBack = part == .all || part == .back
        let drawFront = part == .all || part == .front
        let h = height * style.sizeScale
        let outline = h * 0.018
        let seatTop = groundY - rSeatTop * h
        let seatWF = rSeatWFront * h
        let seatWB = rSeatWBack * h
        let seatThick = rSeatThick * h
        let legThick = rLegThick * h
        let backTop = groundY - h
        // Donus, arka kenari yatayda kaydirarak taklit edilir
        let skew = turn * seatWF * 0.22

        if drawShadow && drawBack {
            ctx.groundShadow(cx: x, cy: groundY, rx: seatWF * 0.55, alpha: 0.28)
        }

        ctx.setStrokeColor(Palette.ink.cgColor)

        // ---------------- ARKA AYAKLAR ----------------
        if drawBack && (style.legs == .four || style.legs == .sled) {
            ctx.setFillColor(style.frameShade.cgColor)
            let bx = seatWB * 0.42
            ctx.capsule(x1: x - bx + skew, y1: seatTop - seatThick * 0.2, x2: x - bx * 0.92 + skew, y2: groundY - h * 0.13,
                        thickness: legThick, color: style.frameShade.cgColor)
            ctx.capsule(x1: x + bx + skew, y1: seatTop - seatThick * 0.2, x2: x + bx * 0.92 + skew, y2: groundY - h * 0.13,
                        thickness: legThick, color: style.frameShade.cgColor)
        }

        // ---------------- SIRTLIK ----------------
        if drawBack {
            switch style.back {
            case .none:
                break
            case .slats:
                ctx.setFillColor(style.frameShade.cgColor)
                let bw = rBackW * h
                // iki dikey direk
                ctx.capsule(x1: x - bw * 0.5 + skew, y1: seatTop, x2: x - bw * 0.5 + skew * 1.3, y2: backTop,
                            thickness: legThick, color: style.frameShade.cgColor)
                ctx.capsule(x1: x + bw * 0.5 + skew, y1: seatTop, x2: x + bw * 0.5 + skew * 1.3, y2: backTop,
                            thickness: legThick, color: style.frameShade.cgColor)
                // yatay latalar
                var i = 0
                while i < 3 {
                    let ly = backTop + (seatTop - backTop) * (0.10 + CGFloat(i) * 0.30)
                    ctx.setFillColor(style.seat.cgColor)
                    ctx.fillRoundRect(cx: x + skew * 1.2, cy: ly, w: bw * 1.06, h: h * 0.075, r: h * 0.035)
                    ctx.setStrokeColor(Palette.ink.cgColor)
                    ctx.strokeRoundRect(cx: x + skew * 1.2, cy: ly, w: bw * 1.06, h: h * 0.075, r: h * 0.035, lineWidth: outline)
                    i += 1
                }
            case .high, .winged:
                ctx.setFillColor(style.seat.cgColor)
                let bw = rBackW * h * 1.06
                let bh = seatTop - backTop
                ctx.fillRoundRect(cx: x + skew * 1.2, cy: backTop + bh * 0.5, w: bw, h: bh, r: bw * 0.30)
                ctx.setFillColor(style.seatShade.cgColor)
                ctx.saveGState()
                let clipRect = CGRect(x: x + skew * 1.2 - bw / 2, y: backTop + bh * 0.62,
                                       width: bw, height: backTop + bh - (backTop + bh * 0.62))
                ctx.clip(to: clipRect)
                ctx.fillRoundRect(cx: x + skew * 1.2, cy: backTop + bh * 0.5, w: bw, h: bh, r: bw * 0.30)
                ctx.restoreGState()
                ctx.setStrokeColor(Palette.ink.cgColor)
                ctx.strokeRoundRect(cx: x + skew * 1.2, cy: backTop + bh * 0.5, w: bw, h: bh, r: bw * 0.30, lineWidth: outline)
            case .rounded:
                ctx.setFillColor(style.seat.cgColor)
                let bw = rBackW * h
                let bh = (seatTop - backTop) * 0.80
                ctx.fillRoundRect(cx: x + skew * 1.2, cy: backTop + bh * 0.5, w: bw, h: bh, r: bw * 0.42)
                ctx.setStrokeColor(Palette.ink.cgColor)
                ctx.strokeRoundRect(cx: x + skew * 1.2, cy: backTop + bh * 0.5, w: bw, h: bh, r: bw * 0.42, lineWidth: outline)
                ctx.setFillColor(style.frameShade.cgColor)
                ctx.capsule(x1: x - bw * 0.36 + skew, y1: backTop + bh, x2: x - bw * 0.40 + skew * 0.8, y2: seatTop,
                            thickness: legThick * 0.9, color: style.frameShade.cgColor)
                ctx.capsule(x1: x + bw * 0.36 + skew, y1: backTop + bh, x2: x + bw * 0.40 + skew * 0.8, y2: seatTop,
                            thickness: legThick * 0.9, color: style.frameShade.cgColor)
            }
        }

        // ---------------- OTURMA YUZEYI (trapez = derinlik) ----------------
        // Oturma yuzeyi ARKA parcaya aittir: karakterin poposu bunun USTUNDE.
        let yBack = seatTop - seatThick * 0.35
        let yFront = seatTop + seatThick * 0.35
        if drawBack {
            ctx.setFillColor(style.seat.cgColor)
            let seatPoly = [
                CGPoint(x: x - seatWB / 2 + skew, y: yBack),
                CGPoint(x: x + seatWB / 2 + skew, y: yBack),
                CGPoint(x: x + seatWF / 2, y: yFront),
                CGPoint(x: x - seatWF / 2, y: yFront)
            ]
            ctx.fillPolygon(seatPoly)
            ctx.setStrokeColor(Palette.ink.cgColor)
            ctx.strokePolygon(seatPoly, lineWidth: outline)

            // on kalinlik yuzu (govde hissi)
            ctx.setFillColor(style.seatShade.cgColor)
            let frontFace = [
                CGPoint(x: x - seatWF / 2, y: yFront),
                CGPoint(x: x + seatWF / 2, y: yFront),
                CGPoint(x: x + seatWF / 2 * 0.99, y: yFront + seatThick),
                CGPoint(x: x - seatWF / 2 * 0.99, y: yFront + seatThick)
            ]
            ctx.fillPolygon(frontFace)
            ctx.setStrokeColor(Palette.ink.cgColor)
            ctx.strokePolygon(frontFace, lineWidth: outline)

            if style.glossy {
                ctx.setFillColor(UIColor(hex: "#55FFFFFF").cgColor)
                let gloss = [
                    CGPoint(x: x - seatWB * 0.34 + skew, y: yBack + seatThick * 0.15),
                    CGPoint(x: x + seatWB * 0.10 + skew, y: yBack + seatThick * 0.15),
                    CGPoint(x: x - seatWF * 0.02, y: yFront - seatThick * 0.10),
                    CGPoint(x: x - seatWF * 0.40, y: yFront - seatThick * 0.10)
                ]
                ctx.fillPolygon(gloss)
            }
        }

        // ---------------- ON AYAKLAR / TABAN ----------------
        // On ayaklar ON parcadir: karakterin baldirlarinin ONUNDE cizilirler.
        if drawFront {
            switch style.legs {
            case .four:
                let fx = seatWF * 0.40
                ctx.capsule(x1: x - fx, y1: yFront + seatThick * 0.5, x2: x - fx * 1.04, y2: groundY,
                            thickness: legThick, color: style.frame.cgColor)
                ctx.capsule(x1: x + fx, y1: yFront + seatThick * 0.5, x2: x + fx * 1.04, y2: groundY,
                            thickness: legThick, color: style.frame.cgColor)
            case .wheels, .pedestal:
                ctx.capsule(x1: x, y1: yFront + seatThick * 0.4, x2: x, y2: groundY - h * 0.10,
                            thickness: legThick * 1.5, color: style.frameShade.cgColor)
                // yildiz taban
                let armY = groundY - h * 0.07
                let armLen = seatWF * 0.46
                ctx.capsule(x1: x, y1: armY, x2: x - armLen, y2: groundY - h * 0.015, thickness: legThick * 0.95, color: style.frame.cgColor)
                ctx.capsule(x1: x, y1: armY, x2: x + armLen, y2: groundY - h * 0.015, thickness: legThick * 0.95, color: style.frame.cgColor)
                ctx.capsule(x1: x, y1: armY, x2: x - armLen * 0.35, y2: groundY + h * 0.005, thickness: legThick * 0.95, color: style.frame.cgColor)
                ctx.capsule(x1: x, y1: armY, x2: x + armLen * 0.35, y2: groundY + h * 0.005, thickness: legThick * 0.95, color: style.frame.cgColor)
                if style.legs == .wheels {
                    ctx.setFillColor(Palette.ink.cgColor)
                    ctx.fillEllipse(cx: x - armLen, cy: groundY, rx: legThick * 0.85, ry: legThick * 0.85)
                    ctx.fillEllipse(cx: x + armLen, cy: groundY, rx: legThick * 0.85, ry: legThick * 0.85)
                    ctx.fillEllipse(cx: x - armLen * 0.35, cy: groundY + h * 0.015, rx: legThick * 0.85, ry: legThick * 0.85)
                    ctx.fillEllipse(cx: x + armLen * 0.35, cy: groundY + h * 0.015, rx: legThick * 0.85, ry: legThick * 0.85)
                }
            case .xFold:
                let fx = seatWF * 0.42
                ctx.capsule(x1: x - fx, y1: yFront, x2: x + fx * 0.85, y2: groundY, thickness: legThick, color: style.frame.cgColor)
                ctx.capsule(x1: x + fx, y1: yFront, x2: x - fx * 0.85, y2: groundY, thickness: legThick, color: style.frame.cgColor)
            case .sled:
                let fx = seatWF * 0.40
                ctx.capsule(x1: x - fx, y1: yFront + seatThick * 0.5, x2: x - fx, y2: groundY, thickness: legThick, color: style.frame.cgColor)
                ctx.capsule(x1: x + fx, y1: yFront + seatThick * 0.5, x2: x + fx, y2: groundY, thickness: legThick, color: style.frame.cgColor)
                ctx.capsule(x1: x - fx * 1.1, y1: groundY, x2: x + fx * 1.1, y2: groundY, thickness: legThick, color: style.frame.cgColor)
            }
        }
    }
}
