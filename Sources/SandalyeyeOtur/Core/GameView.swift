import UIKit

/// Android'deki `GameView` (SurfaceView) karsiligi: butun oyun her karede
/// buraya Core Graphics ile cizilir (Kotlin tarafindaki Path/Paint mantigiyla
/// birebir ayni ruh — immediate-mode, retained sahne grafigi YOK).
///
/// SU AN: sadece Viewport matematigini ve boru hattini (XcodeGen -> Codemagic
/// -> Simulator -> ekran goruntusu) dogrulayan bir "kanit" cizimi var. Gercek
/// sanat katmani (MikoArtist/ChairArtist/SceneArtist portlari) Faz 3'te,
/// Codemagic'in gercek simulator ciktisi gorulup dogrulandiktan sonra gelecek.
final class GameView: UIView {

    private let viewport = Viewport()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) kullanilmiyor") }

    override func layoutSubviews() {
        super.layoutSubviews()
        viewport.onSurfaceChanged(
            widthPx: bounds.width,
            heightPx: bounds.height,
            insetTopPx: safeAreaInsets.top,
            insetBottomPx: safeAreaInsets.bottom,
            insetLeftPx: safeAreaInsets.left,
            insetRightPx: safeAreaInsets.right
        )
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        viewport.apply(ctx)

        // Gokyuzu
        ctx.setFillColor(UIColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: viewport.designWidth, height: viewport.horizonY))

        // Zemin
        ctx.setFillColor(UIColor(red: 0.86, green: 0.75, blue: 0.55, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 0, y: viewport.horizonY, width: viewport.designWidth,
                         height: viewport.designHeight - viewport.horizonY))

        // Ufuk cizgisi
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.6).cgColor)
        ctx.setLineWidth(4)
        ctx.move(to: CGPoint(x: 0, y: viewport.horizonY))
        ctx.addLine(to: CGPoint(x: viewport.designWidth, y: viewport.horizonY))
        ctx.strokePath()

        // Miko yer tutucu: zeminde, merkezde bir daire
        let mikoR: CGFloat = GameConstants.mikoHeight * 0.18
        ctx.setFillColor(UIColor(red: 1, green: 0.42, blue: 0.42, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(
            x: viewport.centerX - mikoR, y: viewport.groundY - mikoR * 2,
            width: mikoR * 2, height: mikoR * 2
        ))

        ctx.restoreGState()

        // Debug metni (tasarim uzayi disinda, ekran biriminde — okunakli kalsin)
        let text = "SANDALYEYE OTUR — wide:\(viewport.wideMode) scale:\(String(format: "%.2f", viewport.scale))"
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ]
        text.draw(at: CGPoint(x: 16, y: safeAreaInsets.top + 8), withAttributes: attrs)
    }
}
