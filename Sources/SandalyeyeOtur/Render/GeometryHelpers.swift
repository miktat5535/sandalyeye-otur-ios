import CoreGraphics

/// Android'in `Canvas.rotate(deg, px, py)` (belli bir nokta etrafinda donme)
/// ve `Path.addArc(RectF, startDeg, sweepDeg)` (eliptik yay, 0deg=saat 3 yonu,
/// pozitif sweep = saat yonu) davranislarini CoreGraphics'te birebir
/// karsilayan yardimcilar. MikoArtist/ChairArtist gibi dogrudan Android
/// cizim kodundan cevrilen dosyalar bunlara guvenir.
extension CGContext {
    /// Belirtilen nokta etrafinda derece cinsinden dondurur.
    func rotate(degrees: CGFloat, around point: CGPoint) {
        translateBy(x: point.x, y: point.y)
        rotate(by: degrees * .pi / 180)
        translateBy(x: -point.x, y: -point.y)
    }
}

extension CGMutablePath {
    /// Android `RectF` + start/sweep (derece) ile tanimlanan eliptik yayin
    /// esdegeri. sweepDeg pozitifse ekranda saat yonunde ilerler (flipped
    /// UIView draw baglaminda `clockwise: true` bunu saglar).
    func addEllipticalArc(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat,
                           startDeg: CGFloat, sweepDeg: CGFloat) {
        let startRad = startDeg * .pi / 180
        let endRad = (startDeg + sweepDeg) * .pi / 180
        let transform = CGAffineTransform(translationX: cx, y: cy).scaledBy(x: rx, y: ry)
        addArc(center: .zero, radius: 1, startAngle: startRad, endAngle: endRad,
               clockwise: sweepDeg >= 0, transform: transform)
    }
}
