import UIKit

/// Miko'yu (ve ayni iskeleti paylasan tum skinleri) tamamen vektorle cizer.
///
/// Oranlar (toplam boy H = 1.0 kabul edilerek):
///   kafa yaricapi   0.245 H   -> kafa capi boyun ~%49'u  (buyuk kafa = sevimli)
///   govde           0.37 x 0.30 H
///   bacak           0.23 H,  kalinlik 0.088 H
///   kol             0.24 H,  kalinlik 0.085 H
///   ayakkabi        0.19 x 0.075 H
/// Bu oranlar docs/CHARACTER_MIKO.md ile birebir aynidir. (bkz. MikoArtist.kt
/// — Kotlin'deki Paint-nesnesi state'i yerine burada dogrudan CGContext
/// setFillColor/setStrokeColor cagrilir; geometri birebir aynidir.)
enum MikoArtist {

    // MARK: - Oran sabitleri
    private static let rHead: CGFloat = 0.245
    private static let rTorsoW: CGFloat = 0.370
    private static let rTorsoH: CGFloat = 0.300
    static let rLegLen: CGFloat = 0.230
    private static let rLegThick: CGFloat = 0.088
    private static let rArmLen: CGFloat = 0.240
    private static let rArmThick: CGFloat = 0.085
    private static let rShoeW: CGFloat = 0.190
    static let rShoeH: CGFloat = 0.075

    /// Oturunca kalcanin indigi mesafe (boy orani).
    ///
    /// Kucuk gorunuyor ve oyle olmali: Miko'nun bacaklari boyunun yalnizca
    /// %20'si, yani ayaktayken kalcasi zaten alcakta. "Oturmus" gorunumunu
    /// saglayan sey dusme degil, BACAKLARIN ONE KIVRILMASIDIR (bkz. drawLeg).
    static let sitDropRatio: CGFloat = 0.0535

    /// Ayaktayken kalcanin y konumu.
    static func standingHipY(groundY: CGFloat, height: CGFloat) -> CGFloat {
        groundY - (rLegLen + rShoeH * 0.5) * height
    }

    /// Tam oturmus haldeki kalca y konumu.
    ///
    /// Sandalyenin boyu BU degere gore secilir; boylece popo gercekten
    /// oturma yuzeyine deger, havada kalmaz:
    ///   chairH = ChairArtist.heightForSeatY(groundY, MikoArtist.seatedHipY(groundY, mikoH))
    static func seatedHipY(groundY: CGFloat, height: CGFloat) -> CGFloat {
        groundY - (rLegLen + rShoeH * 0.5 - sitDropRatio) * height
    }

    /// - Parameters:
    ///   - x: karakterin yatay merkezi (tasarim birimi)
    ///   - groundY: ayaklarin bastigi cizgi
    ///   - height: toplam ayakta boy
    static func draw(
        _ ctx: CGContext, x: CGFloat, groundY: CGFloat, height: CGFloat,
        pose: Pose, skin: CharacterSkin = .miko, drawShadow: Bool = true
    ) {
        let h = height
        let headR = rHead * h
        let torsoW = rTorsoW * h * (2 - pose.squash)
        let torsoH = rTorsoH * h * pose.squash
        let legLen = rLegLen * h
        let legThick = rLegThick * h
        let armLen = rArmLen * h
        let armThick = rArmThick * h
        let shoeW = rShoeW * h
        let shoeH = rShoeH * h
        let outline = h * 0.016

        let sitDrop = pose.hipDrop * h * sitDropRatio

        if drawShadow {
            let shadowScale = 1 - pose.hipDrop * 0.15
            ctx.groundShadow(cx: x, cy: groundY + shoeH * 0.15, rx: torsoW * 0.62 * shadowScale, alpha: 0.30)
        }

        // Kalca asagi iner ama AYAKLAR YERDE KALIR -> bacaklar kivrilir.
        let hipY = groundY - legLen - shoeH * 0.5 + sitDrop

        ctx.saveGState()
        ctx.rotate(degrees: pose.lean + pose.bodyRotation, around: CGPoint(x: x, y: hipY))
        ctx.translateBy(x: 0, y: pose.bob)

        let torsoCY = hipY - torsoH * 0.5
        let headCY = torsoCY - torsoH * 0.5 - headR * 0.62
        let shoulderY = torsoCY - torsoH * 0.22

        let sp = pose.stepPhase * 2 * .pi
        let legSwing = sin(sp) * legLen * 0.55 * (1 - pose.hipDrop)
        let legLift = (cos(sp) > 0 ? cos(sp) : 0) * legLen * 0.18 * (1 - pose.hipDrop)

        // ARKA BACAK
        drawLeg(ctx, hipX: x - torsoW * 0.27, hipY: hipY, groundY: groundY, legLen: legLen,
                thick: legThick, shoeW: shoeW, shoeH: shoeH, swing: -legSwing,
                lift: legSwing < 0 ? legLift : 0, sit: pose.hipDrop, skin: skin, back: true, outline: outline)

        // ARKA KOL
        drawArm(ctx, shX: x - torsoW * 0.42, shY: shoulderY, side: -1, len: armLen, thick: armThick,
                swing: -legSwing * 0.7, raise: pose.armRaise, skin: skin, back: true, outline: outline)

        // GOVDE
        ctx.setFillColor(skin.shirt.cgColor)
        ctx.fillRoundRect(cx: x, cy: torsoCY, w: torsoW, h: torsoH, r: torsoW * 0.42)
        ctx.setFillColor(skin.shirtShade.cgColor)
        ctx.saveGState()
        ctx.clip(to: CGRect(x: x - torsoW / 2, y: torsoCY + torsoH * 0.24,
                             width: torsoW, height: torsoH * 0.26))
        ctx.fillRoundRect(cx: x, cy: torsoCY, w: torsoW, h: torsoH, r: torsoW * 0.42)
        ctx.restoreGState()
        ctx.setStrokeColor(Palette.ink.cgColor)
        ctx.strokeRoundRect(cx: x, cy: torsoCY, w: torsoW, h: torsoH, r: torsoW * 0.42, lineWidth: outline)

        // ON BACAK
        drawLeg(ctx, hipX: x + torsoW * 0.27, hipY: hipY, groundY: groundY, legLen: legLen,
                thick: legThick, shoeW: shoeW, shoeH: shoeH, swing: legSwing,
                lift: legSwing > 0 ? legLift : 0, sit: pose.hipDrop, skin: skin, back: false, outline: outline)

        // ON KOL
        drawArm(ctx, shX: x + torsoW * 0.42, shY: shoulderY, side: 1, len: armLen, thick: armThick,
                swing: legSwing * 0.7, raise: pose.armRaise, skin: skin, back: false, outline: outline)

        // KAFA
        ctx.saveGState()
        ctx.rotate(degrees: pose.headTilt, around: CGPoint(x: x, y: headCY))
        drawHead(ctx, cx: x, cy: headCY, r: headR, pose: pose, skin: skin, outline: outline)
        ctx.restoreGState()

        ctx.restoreGState()
    }

    // MARK: - Bacak
    /// Bacak iki parcadir: kalca -> diz, diz -> ayak bilegi.
    ///
    /// `sit` 0 = ayakta (diz duz, iki parca hizali), 1 = oturmus (diz ONE
    /// cikar, ayak one gelir -> "L" durusu). Oturmus gorunumu asil bu
    /// kivrilmadan gelir; kalca yalnizca biraz iner.
    private static func drawLeg(
        _ ctx: CGContext, hipX: CGFloat, hipY: CGFloat, groundY: CGFloat,
        legLen: CGFloat, thick: CGFloat, shoeW: CGFloat, shoeH: CGFloat,
        swing: CGFloat, lift: CGFloat, sit: CGFloat,
        skin: CharacterSkin, back: Bool, outline: CGFloat
    ) {
        let ankleX = hipX + swing + sit * legLen * 0.62
        let ankleY = groundY - shoeH * 0.6 - lift
        // Diz: duz bacakta orta nokta; otururken one dogru itilir.
        let kneeX = (hipX + ankleX) * 0.5 + sit * legLen * 0.30
        let kneeY = (hipY + ankleY) * 0.5 + sit * legLen * 0.10

        let legColor = (back ? skin.pantsShade : skin.pants).cgColor
        ctx.capsule(x1: hipX, y1: hipY, x2: kneeX, y2: kneeY, thickness: thick, color: legColor)
        ctx.capsule(x1: kneeX, y1: kneeY, x2: ankleX, y2: ankleY, thickness: thick, color: legColor)

        ctx.setFillColor((back ? skin.shoeSole : skin.shoe).cgColor)
        ctx.fillRoundRect(cx: ankleX + shoeW * 0.10, cy: ankleY + shoeH * 0.35, w: shoeW, h: shoeH, r: shoeH * 0.48)
        ctx.setStrokeColor(Palette.ink.cgColor)
        ctx.strokeRoundRect(cx: ankleX + shoeW * 0.10, cy: ankleY + shoeH * 0.35, w: shoeW, h: shoeH,
                             r: shoeH * 0.48, lineWidth: outline * 0.85)
    }

    // MARK: - Kol
    /// `side` -1 = govdenin solundaki kol, +1 = sagindaki kol.
    ///
    /// Kol iki referans durus arasinda enterpole edilir: raise = -1 -> el
    /// asagida govdeye yakin (normal durus/yuruyus); raise = +1 -> el
    /// yukarida disa acik (kutlama). Boylece iki kol da kendi tarafina
    /// dogru calisir; tek bir aci formulu kullanildiginda ikisi de ayni
    /// yone savruluyordu.
    private static func drawArm(
        _ ctx: CGContext, shX: CGFloat, shY: CGFloat, side: CGFloat, len: CGFloat, thick: CGFloat,
        swing: CGFloat, raise: CGFloat, skin: CharacterSkin, back: Bool, outline: CGFloat
    ) {
        let t = min(max((raise + 1) * 0.5, 0), 1)
        let downX = shX + side * len * 0.14
        let downY = shY + len * 0.86
        let upX = shX + side * len * 0.60
        let upY = shY - len * 0.52
        let handX = downX + (upX - downX) * t + swing * 0.6
        let handY = downY + (upY - downY) * t

        ctx.capsule(x1: shX, y1: shY, x2: handX, y2: handY, thickness: thick,
                     color: (back ? skin.shirtShade : skin.shirt).cgColor)
        ctx.setFillColor((back ? skin.skinShade : skin.skin).cgColor)
        ctx.fillEllipse(cx: handX, cy: handY, rx: thick * 0.62, ry: thick * 0.62)
        ctx.setStrokeColor(Palette.ink.cgColor)
        ctx.strokeEllipse(cx: handX, cy: handY, rx: thick * 0.62, ry: thick * 0.62, lineWidth: outline * 0.8)
    }

    // MARK: - Kafa
    private static func drawHead(
        _ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat,
        pose: Pose, skin: CharacterSkin, outline: CGFloat
    ) {
        ctx.setFillColor(skin.skinShade.cgColor)
        ctx.fillEllipse(cx: cx - r * 0.94, cy: cy + r * 0.10, rx: r * 0.17, ry: r * 0.22)
        ctx.fillEllipse(cx: cx + r * 0.94, cy: cy + r * 0.10, rx: r * 0.17, ry: r * 0.22)

        ctx.setFillColor(skin.skin.cgColor)
        ctx.fillEllipse(cx: cx, cy: cy, rx: r, ry: r * 0.97)
        ctx.setStrokeColor(Palette.ink.cgColor)
        ctx.strokeEllipse(cx: cx, cy: cy, rx: r, ry: r * 0.97, lineWidth: outline)

        drawHeadGear(ctx, cx: cx, cy: cy, r: r, skin: skin, outline: outline)

        ctx.setFillColor(UIColor(hex: "#33FF6B6B").cgColor)
        ctx.fillEllipse(cx: cx - r * 0.58, cy: cy + r * 0.24, rx: r * 0.20, ry: r * 0.14)
        ctx.fillEllipse(cx: cx + r * 0.58, cy: cy + r * 0.24, rx: r * 0.20, ry: r * 0.14)

        drawFace(ctx, cx: cx, cy: cy, r: r, pose: pose, skin: skin, outline: outline)
    }

    // MARK: - Kafa aksesuari
    /// 10 skini birbirinden ayiran iki seyden biri (digeri palet).
    /// Hepsi ayni kafa dairesinin uzerine oturur; iskelet degismez.
    private static func drawHeadGear(
        _ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat,
        skin: CharacterSkin, outline: CGFloat
    ) {
        ctx.setStrokeColor(Palette.ink.cgColor)
        let strokeW = outline * 0.9

        switch skin.headGear {
        case .none:
            break

        case .hairTuft:
            // Android RectF(cx-r, cy-1.02r, cx+r, cy+0.30r) -> merkez cy-0.36r, ry=0.66r
            ctx.setFillColor(skin.hair.cgColor)
            let cap = CGMutablePath()
            cap.addEllipticalArc(cx: cx, cy: cy - r * 0.36, rx: r, ry: r * 0.66,
                                  startDeg: 182, sweepDeg: 176)
            cap.closeSubpath()
            ctx.addPath(cap)
            ctx.fillPath()
            // tepe tutami - Miko'nun imzasi
            let tuft = CGMutablePath()
            tuft.move(to: CGPoint(x: cx + r * 0.06, y: cy - r * 0.96))
            tuft.addQuadCurve(to: CGPoint(x: cx + r * 0.30, y: cy - r * 0.72),
                               control: CGPoint(x: cx + r * 0.52, y: cy - r * 1.46))
            tuft.addQuadCurve(to: CGPoint(x: cx + r * 0.06, y: cy - r * 0.96),
                               control: CGPoint(x: cx + r * 0.16, y: cy - r * 0.86))
            ctx.addPath(tuft)
            ctx.fillPath()

        case .antenna:
            // Kafa ustu tek anten + ucunda kure
            ctx.setFillColor(skin.hair.cgColor)
            ctx.capsule(x1: cx, y1: cy - r * 0.92, x2: cx + r * 0.14, y2: cy - r * 1.42,
                         thickness: r * 0.09, color: skin.hair.cgColor)
            ctx.fillEllipse(cx: cx + r * 0.14, cy: cy - r * 1.50, rx: r * 0.17, ry: r * 0.17)
            ctx.strokeEllipse(cx: cx + r * 0.14, cy: cy - r * 1.50, rx: r * 0.17, ry: r * 0.17, lineWidth: strokeW)

        case .helmet:
            // Saydam kask kubbesi - yuzu ortmesin diye yalnizca kontur + parlama
            ctx.setFillColor(UIColor(hex: "#33FFFFFF").cgColor)
            ctx.fillEllipse(cx: cx, cy: cy - r * 0.06, rx: r * 1.20, ry: r * 1.16)
            ctx.strokeEllipse(cx: cx, cy: cy - r * 0.06, rx: r * 1.20, ry: r * 1.16, lineWidth: strokeW * 1.15 / 0.9)
            ctx.setFillColor(UIColor(hex: "#88FFFFFF").cgColor)
            let shine = CGMutablePath()
            shine.move(to: CGPoint(x: cx - r * 0.82, y: cy - r * 0.52))
            shine.addQuadCurve(to: CGPoint(x: cx + r * 0.12, y: cy - r * 1.00),
                                control: CGPoint(x: cx - r * 0.34, y: cy - r * 1.06))
            shine.addQuadCurve(to: CGPoint(x: cx - r * 0.66, y: cy - r * 0.28),
                                control: CGPoint(x: cx - r * 0.40, y: cy - r * 0.80))
            shine.closeSubpath()
            ctx.addPath(shine)
            ctx.fillPath()
            // boyun halkasi
            ctx.setFillColor(skin.shoe.cgColor)
            ctx.fillRoundRect(cx: cx, cy: cy + r * 0.96, w: r * 1.10, h: r * 0.24, r: r * 0.12)

        case .hat:
            ctx.setFillColor(skin.shirt.cgColor)
            // genis kenar
            ctx.fillEllipse(cx: cx, cy: cy - r * 0.68, rx: r * 1.28, ry: r * 0.24)
            ctx.strokeEllipse(cx: cx, cy: cy - r * 0.68, rx: r * 1.28, ry: r * 0.24, lineWidth: strokeW)
            // tepe
            ctx.fillRoundRect(cx: cx, cy: cy - r * 1.06, w: r * 1.05, h: r * 0.62, r: r * 0.26)
            ctx.strokeRoundRect(cx: cx, cy: cy - r * 1.06, w: r * 1.05, h: r * 0.62, r: r * 0.26, lineWidth: strokeW)
            ctx.setFillColor(skin.pants.cgColor)
            ctx.fillRoundRect(cx: cx, cy: cy - r * 0.80, w: r * 1.08, h: r * 0.18, r: r * 0.08)

        case .band:
            ctx.setFillColor(skin.hair.cgColor)
            // Yuzun ustunu ortmeyen alin bandi + arkada ucan iki uc
            ctx.fillRoundRect(cx: cx, cy: cy - r * 0.52, w: r * 2.06, h: r * 0.30, r: r * 0.14)
            ctx.capsule(x1: cx - r * 0.92, y1: cy - r * 0.52, x2: cx - r * 1.55, y2: cy - r * 0.22,
                         thickness: r * 0.11, color: skin.hair.cgColor)
            ctx.capsule(x1: cx - r * 0.92, y1: cy - r * 0.52, x2: cx - r * 1.48, y2: cy - r * 0.66,
                         thickness: r * 0.11, color: skin.hair.cgColor)

        case .beakHood:
            // Penguen: kafanin ust yarisini saran koyu baslik + gaga
            ctx.setFillColor(skin.pants.cgColor)
            let hood = CGMutablePath()
            hood.addEllipticalArc(cx: cx, cy: cy - r * 0.29 /* merkezi RectF'e gore ayarla */,
                                   rx: r * 1.02, ry: r * 0.75, startDeg: 178, sweepDeg: 184)
            hood.closeSubpath()
            ctx.addPath(hood)
            ctx.fillPath()
            ctx.setFillColor(skin.shoe.cgColor)
            let beak = CGMutablePath()
            beak.move(to: CGPoint(x: cx - r * 0.20, y: cy + r * 0.30))
            beak.addLine(to: CGPoint(x: cx + r * 0.20, y: cy + r * 0.30))
            beak.addLine(to: CGPoint(x: cx, y: cy + r * 0.66))
            beak.closeSubpath()
            ctx.addPath(beak)
            ctx.fillPath()
            ctx.setLineWidth(strokeW)
            ctx.addPath(beak)
            ctx.strokePath()
        }
    }

    // MARK: - Yuz
    private static func drawFace(
        _ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat,
        pose: Pose, skin: CharacterSkin, outline: CGFloat
    ) {
        let eyeY = cy - r * 0.06
        let look = pose.lookX * r * 0.10

        // VISOR (robot/astronot) tek parca vizor cizer, digerleri iki goz.
        if skin.eyeStyle == .visor {
            ctx.setFillColor(Palette.ink.cgColor)
            ctx.fillRoundRect(cx: cx, cy: eyeY, w: r * 1.30, h: r * 0.52, r: r * 0.26)
            ctx.setStrokeColor(Palette.ink.cgColor)
            ctx.strokeRoundRect(cx: cx, cy: eyeY, w: r * 1.30, h: r * 0.52, r: r * 0.26, lineWidth: outline * 0.75)
            if pose.blink < 0.8 {
                // Vizorun icinde iki isik noktasi = "goz"
                ctx.setFillColor(skin.hair.cgColor)
                let gw = pose.face == .surprised ? r * 0.20 : r * 0.15
                ctx.fillEllipse(cx: cx - r * 0.34 + look, cy: eyeY, rx: gw, ry: gw * 1.05)
                ctx.fillEllipse(cx: cx + r * 0.34 + look, cy: eyeY, rx: gw, ry: gw * 1.05)
            }
            drawBrowsAndMouth(ctx, cx: cx, cy: cy, r: r, pose: pose, browY: eyeY - r * 0.34, outline: outline)
            return
        }

        let big = skin.eyeStyle == .big
        let slit = skin.eyeStyle == .slit
        let eyeDX = big ? r * 0.44 : r * 0.40

        var eyeRX = big ? r * 0.225 : r * 0.155
        var eyeRY = big ? r * 0.270 : r * 0.185
        switch pose.face {
        case .surprised:
            eyeRX *= 1.30
            eyeRY *= 1.32
        case .determined:
            eyeRY *= 0.73
        default:
            break
        }
        if slit { eyeRY *= 0.52 } // ninja: dar bakis
        eyeRY *= (1 - pose.blink * 0.92)

        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(cx: cx - eyeDX, cy: eyeY, rx: eyeRX, ry: eyeRY)
        ctx.fillEllipse(cx: cx + eyeDX, cy: eyeY, rx: eyeRX, ry: eyeRY)
        ctx.setStrokeColor(Palette.ink.cgColor)
        ctx.strokeEllipse(cx: cx - eyeDX, cy: eyeY, rx: eyeRX, ry: eyeRY, lineWidth: outline * 0.75)
        ctx.strokeEllipse(cx: cx + eyeDX, cy: eyeY, rx: eyeRX, ry: eyeRY, lineWidth: outline * 0.75)

        if pose.blink < 0.8 {
            ctx.setFillColor(Palette.ink.cgColor)
            let pr = eyeRX * 0.52
            ctx.fillEllipse(cx: cx - eyeDX + look, cy: eyeY + eyeRY * 0.10, rx: pr, ry: pr * 1.05)
            ctx.fillEllipse(cx: cx + eyeDX + look, cy: eyeY + eyeRY * 0.10, rx: pr, ry: pr * 1.05)
            // Parlama noktasi olmadan bakis "olu" gorunur - zorunlu.
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(cx: cx - eyeDX + look + pr * 0.4, cy: eyeY - eyeRY * 0.25, rx: pr * 0.32, ry: pr * 0.32)
            ctx.fillEllipse(cx: cx + eyeDX + look + pr * 0.4, cy: eyeY - eyeRY * 0.25, rx: pr * 0.32, ry: pr * 0.32)
        }

        drawBrowsAndMouth(ctx, cx: cx, cy: cy, r: r, pose: pose, browY: eyeY - eyeRY - r * 0.16, outline: outline)
    }

    private static func drawBrowsAndMouth(
        _ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat,
        pose: Pose, browY: CGFloat, outline: CGFloat
    ) {
        let eyeDX = r * 0.40
        ctx.setStrokeColor(Palette.ink.cgColor)
        ctx.setLineWidth(outline * 0.95)
        ctx.setLineCap(.round)

        switch pose.face {
        case .surprised:
            ctx.move(to: CGPoint(x: cx - eyeDX - r * 0.14, y: browY - r * 0.05))
            ctx.addLine(to: CGPoint(x: cx - eyeDX + r * 0.14, y: browY - r * 0.09))
            ctx.move(to: CGPoint(x: cx + eyeDX - r * 0.14, y: browY - r * 0.09))
            ctx.addLine(to: CGPoint(x: cx + eyeDX + r * 0.14, y: browY - r * 0.05))
            ctx.strokePath()
        case .confused:
            ctx.move(to: CGPoint(x: cx - eyeDX - r * 0.14, y: browY + r * 0.04))
            ctx.addLine(to: CGPoint(x: cx - eyeDX + r * 0.14, y: browY - r * 0.08))
            ctx.move(to: CGPoint(x: cx + eyeDX - r * 0.14, y: browY - r * 0.02))
            ctx.addLine(to: CGPoint(x: cx + eyeDX + r * 0.14, y: browY + r * 0.02))
            ctx.strokePath()
        case .determined:
            ctx.move(to: CGPoint(x: cx - eyeDX - r * 0.15, y: browY - r * 0.06))
            ctx.addLine(to: CGPoint(x: cx - eyeDX + r * 0.13, y: browY + r * 0.06))
            ctx.move(to: CGPoint(x: cx + eyeDX - r * 0.13, y: browY + r * 0.06))
            ctx.addLine(to: CGPoint(x: cx + eyeDX + r * 0.15, y: browY - r * 0.06))
            ctx.strokePath()
        default:
            break
        }

        let mouthY = cy + r * 0.44
        ctx.setStrokeColor(Palette.ink.cgColor)
        ctx.setLineWidth(outline * 1.05)

        switch pose.face {
        case .happy:
            let path = CGMutablePath()
            path.addEllipticalArc(cx: cx, cy: mouthY, rx: r * 0.30, ry: r * 0.24, startDeg: 15, sweepDeg: 150)
            ctx.addPath(path)
            ctx.strokePath()
        case .surprised:
            ctx.setFillColor(Palette.ink.cgColor)
            ctx.fillEllipse(cx: cx, cy: mouthY, rx: r * 0.13, ry: r * 0.17)
        case .confused:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: cx - r * 0.22, y: mouthY))
            path.addQuadCurve(to: CGPoint(x: cx + r * 0.04, y: mouthY + r * 0.02),
                               control: CGPoint(x: cx - r * 0.07, y: mouthY - r * 0.12))
            path.addQuadCurve(to: CGPoint(x: cx + r * 0.24, y: mouthY + r * 0.01),
                               control: CGPoint(x: cx + r * 0.16, y: mouthY + r * 0.14))
            ctx.addPath(path)
            ctx.strokePath()
        case .dizzy:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: cx - r * 0.24, y: mouthY + r * 0.10))
            path.addQuadCurve(to: CGPoint(x: cx + r * 0.24, y: mouthY + r * 0.10),
                               control: CGPoint(x: cx, y: mouthY - r * 0.16))
            ctx.addPath(path)
            ctx.strokePath()
        default:
            let path = CGMutablePath()
            path.addEllipticalArc(cx: cx, cy: mouthY, rx: r * 0.20, ry: r * 0.16, startDeg: 25, sweepDeg: 130)
            ctx.addPath(path)
            ctx.strokePath()
        }
    }
}
