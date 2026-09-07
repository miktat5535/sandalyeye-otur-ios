import UIKit

/// Cizim yardimcilari. Tum oyun sanati bu ilkel islerden olusur:
/// yuvarlak dikdortgen, kapsul, elips, poligon.
/// (bkz. Draw.kt — Kotlin'deki "Paint nesnesinin rengini ayarlayip Draw.x'e
/// gecirme" deseni yerine burada CGContext extension'lari kullanilir; her
/// cagridan once `ctx.setFillColor`/`setStrokeColor` cagirilir.)
///
/// Neden runtime vektor, neden PNG degil:
///  - Her ekran yogunlugunda net (@1x'ten @3x'e tek kod)
///  - Uygulamada sifir doku -> kucuk boyut, hizli acilis
///  - %100 ozgun, telif riski yok
///  - Renk paleti degistirerek 10 skin uretmek bedava
extension CGContext {

    func fillRoundRect(cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat, r: CGFloat) {
        let rect = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: min(r, min(w, h) / 2))
        addPath(path.cgPath)
        fillPath()
    }

    func strokeRoundRect(cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat, r: CGFloat, lineWidth: CGFloat) {
        let rect = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: min(r, min(w, h) / 2))
        setLineWidth(lineWidth)
        setLineCap(.round)
        setLineJoin(.round)
        addPath(path.cgPath)
        strokePath()
    }

    func fillEllipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) {
        fillEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    func strokeEllipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, lineWidth: CGFloat) {
        setLineWidth(lineWidth)
        strokeEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    /// Iki nokta arasi kapsul (kol/bacak icin) — dolgu rengiyle kalin,
    /// yuvarlak uclu bir cizgi olarak cizilir.
    func capsule(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat, thickness: CGFloat, color: CGColor) {
        setStrokeColor(color)
        setLineWidth(thickness)
        setLineCap(.round)
        setLineJoin(.round)
        move(to: CGPoint(x: x1, y: y1))
        addLine(to: CGPoint(x: x2, y: y2))
        strokePath()
    }

    /// Yumusak zemin golgesi - karakterin "yere basma" hissi bundan gelir.
    func groundShadow(cx: CGFloat, cy: CGFloat, rx: CGFloat, alpha: CGFloat) {
        setFillColor(Palette.shadow.withAlphaComponent(alpha).cgColor)
        fillEllipse(cx: cx, cy: cy, rx: rx, ry: rx * 0.30)
    }

    /// Kapali poligon (perspektif zemin, sandalye oturma yuzeyi trapezi vb.)
    /// (bkz. Draw.kt `polygon` — orada bir Path nesnesi yeniden kullanilir,
    /// burada tasima ihtiyaci olmadigi icin dogrudan CGMutablePath kuruluyor.)
    private func polygonPath(_ points: [CGPoint]) -> CGMutablePath {
        let path = CGMutablePath()
        guard let first = points.first else { return path }
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
        path.closeSubpath()
        return path
    }

    func fillPolygon(_ points: [CGPoint]) {
        addPath(polygonPath(points))
        fillPath()
    }

    func strokePolygon(_ points: [CGPoint], lineWidth: CGFloat) {
        setLineWidth(lineWidth)
        setLineCap(.round)
        setLineJoin(.round)
        addPath(polygonPath(points))
        strokePath()
    }
}
