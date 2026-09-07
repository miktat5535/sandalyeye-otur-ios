import UIKit

/// Oyun tipografisi.
///
/// Yazi stili tek yerden yonetilir: kalin, koyu konturlu, "sticker"
/// gorunumu casual oyunlarda metni arka plandan bagimsiz okunur kilar.
///
/// Font notu: sistem sans-serif BOLD kullanilir (Android tarafiyla ayni
/// gerekce — her cihazda var, lisans sorunu yok). (bkz. TextArtist.kt)
enum TextArtist {
    enum Align { case center, left, right }

    private static func font(size: CGFloat) -> UIFont {
        UIFont.boldSystemFont(ofSize: size)
    }

    private static func drawX(_ text: NSString, _ font: UIFont, _ x: CGFloat, _ align: Align) -> CGFloat {
        let w = text.size(withAttributes: [.font: font]).width
        switch align {
        case .center: return x - w / 2
        case .left: return x
        case .right: return x - w
        }
    }

    /// Konturlu, golgeli baslik.
    /// - Parameter y: Android'deki gibi metnin BASELINE'i (ust-sol degil).
    static func title(
        _ ctx: CGContext, _ text: String, x: CGFloat, y: CGFloat, size: CGFloat,
        color: UIColor = Palette.cream,
        outlineColor: UIColor = Palette.ink,
        outlineRatio: CGFloat = 0.16,
        align: Align = .center,
        alpha: CGFloat = 1
    ) {
        guard size > 0 else { return }
        let a = alpha.clamped(0, 1)
        let f = font(size: size)
        let str = text as NSString
        let dx = drawX(str, f, x, align)
        let topY = y - f.ascender

        UIGraphicsPushContext(ctx)
        let outlineAttrs: [NSAttributedString.Key: Any] = [
            .font: f,
            .strokeColor: outlineColor.withAlphaComponent(a),
            .foregroundColor: UIColor.clear,
            .strokeWidth: outlineRatio * 100
        ]
        // Alt golge - metni zeminden ayirir (outline'in hafif asagi kaydirilmis kopyasi)
        str.draw(at: CGPoint(x: dx, y: topY + size * 0.055), withAttributes: outlineAttrs)
        str.draw(at: CGPoint(x: dx, y: topY), withAttributes: outlineAttrs)

        let fillAttrs: [NSAttributedString.Key: Any] = [
            .font: f, .foregroundColor: color.withAlphaComponent(a)
        ]
        str.draw(at: CGPoint(x: dx, y: topY), withAttributes: fillAttrs)
        UIGraphicsPopContext()
    }

    /// Duz, konturuz metin (UI etiketleri, sayaclar).
    static func label(
        _ ctx: CGContext, _ text: String, x: CGFloat, y: CGFloat, size: CGFloat,
        color: UIColor = Palette.uiTextDark,
        align: Align = .center,
        alpha: CGFloat = 1
    ) {
        guard size > 0 else { return }
        let f = font(size: size)
        let str = text as NSString
        let dx = drawX(str, f, x, align)
        let topY = y - f.ascender

        UIGraphicsPushContext(ctx)
        str.draw(at: CGPoint(x: dx, y: topY), withAttributes: [
            .font: f, .foregroundColor: color.withAlphaComponent(alpha.clamped(0, 1))
        ])
        UIGraphicsPopContext()
    }

    static func measure(_ text: String, size: CGFloat) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: font(size: size)]).width
    }
}

extension Comparable {
    func clamped(_ lo: Self, _ hi: Self) -> Self { min(max(self, lo), hi) }
}
