import UIKit

/// Android'deki `GameView` (SurfaceView) karsiligi: butun oyun her karede
/// buraya Core Graphics ile cizilir (Kotlin tarafindaki Path/Paint mantigiyla
/// birebir ayni ruh — immediate-mode, retained sahne grafigi YOK).
///
/// Ekran gecisleri [Screen.next] uzerinden yurur: her karede aktif ekran
/// guncellenir, `next` doluysa bir sonraki karede ona gecilir.
final class GameView: UIView {

    var screen: Screen? {
        didSet {
            if window != nil { screen?.onEnter(viewport) }
        }
    }

    private let viewport = Viewport()
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        contentMode = .redraw
        isMultipleTouchEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) kullanilmiyor") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startLoop()
            layoutIfNeeded()
            screen?.onEnter(viewport)
        } else {
            stopLoop()
        }
    }

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
    }

    // ---------------------------------------------------------------- dongu

    private func startLoop() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func pauseLoop() {
        displayLink?.isPaused = true
    }

    func resumeLoop() {
        // Duraklama sirasinda gecen sureyi tek buyuk bir dt olarak yutmamak
        // icin zaman damgasi sifirlanir (Android'deki maxDeltaSec kirpmasiyla
        // ayni amac).
        lastTimestamp = nil
        displayLink?.isPaused = false
    }

    private func stopLoop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt: CGFloat
        if let last = lastTimestamp {
            dt = min(CGFloat(now - last), CGFloat(GameConstants.maxDeltaSec))
        } else {
            dt = 0
        }
        lastTimestamp = now

        if let current = screen {
            current.update(dt, viewport)
            if let n = current.next {
                current.onExit()
                screen = n
                n.onEnter(viewport)
            }
        }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        viewport.apply(ctx)
        screen?.draw(ctx, viewport)
        ctx.restoreGState()
    }

    // ---------------------------------------------------------------- girdi

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        screen?.onTouch(x: viewport.toDesignX(p.x), y: viewport.toDesignY(p.y), down: true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        screen?.onTouchMoved(x: viewport.toDesignX(p.x), y: viewport.toDesignY(p.y))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        screen?.onTouch(x: viewport.toDesignX(p.x), y: viewport.toDesignY(p.y), down: false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        screen?.onTouchCancelled()
    }

    /// Geri jesti (Android geri tusunun iOS karsiligi yok, ama Screen'lerin
    /// `onBack` mantigini korumak icin — orn. sistem swipe-back kapali oldugundan
    /// bu su an yalnizca ihtiyac halinde disaridan cagrilir).
    @discardableResult
    func handleBack() -> Bool {
        screen?.onBack() ?? false
    }
}
