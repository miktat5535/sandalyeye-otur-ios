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
    /// esdegeri. sweepDeg pozitifse ekranda saat yonunde ilerler.
    ///
    /// DIKKAT: `CGContext.addArc`'in `clockwise` parametresi flipped (UIKit
    /// draw) baglamda bile HER ZAMAN unflipped/matematiksel uzaya gore
    /// yorumlanir (Apple dokumantasyonu) — yani ekranda GORUNEN saat yonu,
    /// matematiksel "clockwise"in TERSIDIR. Bu yuzden Android'in ekran-saat-
    /// yonu tanimini eslemek icin burada `!` ile ters ceviriyoruz. (Ilk
    /// denemede bu ters olarak birakilmisti ve HAIR_TUFT "kepi" kafanin
    /// tepesi yerine gozlerin ustunu kaplayan bir bant olarak cikmisti —
    /// gercek simulator ekran goruntusuyle yakalanip duzeltildi.)
    func addEllipticalArc(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat,
                           startDeg: CGFloat, sweepDeg: CGFloat) {
        let startRad = startDeg * .pi / 180
        let endRad = (startDeg + sweepDeg) * .pi / 180
        let transform = CGAffineTransform(translationX: cx, y: cy).scaledBy(x: rx, y: ry)
        addArc(center: .zero, radius: 1, startAngle: startRad, endAngle: endRad,
               clockwise: sweepDeg < 0, transform: transform)
    }
}
