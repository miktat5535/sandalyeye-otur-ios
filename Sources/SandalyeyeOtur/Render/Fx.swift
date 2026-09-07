import UIKit

/// Partikul ve efekt sistemi.
///
/// Tum parcaciklar havuzdan gelir; oyun icinde tek bir tahsis yapilmaz.
/// Efekt sayisi [quality] ile olceklenir -> dusuk segment cihazda otomatik azalir.
/// (bkz. Fx.kt)
final class Fx {

    enum Kind { case dust, coin, star, spark, smoke }

    final class Particle {
        var kind: Kind = .dust
        var x: CGFloat = 0; var y: CGFloat = 0
        var vx: CGFloat = 0; var vy: CGFloat = 0
        var life: CGFloat = 0; var maxLife: CGFloat = 1
        var size: CGFloat = 0
        var rot: CGFloat = 0; var vrot: CGFloat = 0
        var color: UIColor = .white
        var gravity: CGFloat = 0
        var targetX: CGFloat = 0; var targetY: CGFloat = 0 // COIN icin
        var alive = false
    }

    /// Halka dalgasi (oturus/dusus vurgusu).
    private final class Ring {
        var x: CGFloat = 0; var y: CGFloat = 0
        var life: CGFloat = 0; var maxLife: CGFloat = 0.45
        var startR: CGFloat = 0; var endR: CGFloat = 0
        var color: UIColor = .white
        var alive = false
    }

    private let pool = Pool<Particle>(initialSize: 96) { Particle() }
    private var active: [Particle] = []
    private let ringPool = Pool<Ring>(initialSize: 8) { Ring() }
    private var rings: [Ring] = []

    /// 1.0 = tam kalite, 0.5 = yari parcacik. Cihaza gore ayarlanabilir.
    var quality: CGFloat = 1

    var activeCount: Int { active.count }

    func clear() {
        for p in active { p.alive = false; pool.recycle(p) }
        active.removeAll()
        for r in rings { r.alive = false; ringPool.recycle(r) }
        rings.removeAll()
    }

    // ------------------------------------------------------------- uretenler

    /// Yere carpma / oturma tozu.
    func dust(_ x: CGFloat, _ y: CGFloat, scale: CGFloat, strength: CGFloat = 1) {
        ring(x, y, r0: scale * 0.35, r1: scale * 1.5, color: UIColor.white.withAlphaComponent(0x66.0 / 255), life: 0.40)
        let n = max(2, Int(7 * quality * strength))
        for _ in 0..<n {
            guard let p = spawn(.dust) else { return }
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let sp = (0.5 + CGFloat.random(in: 0..<1)) * scale * 2.2 * strength
            p.x = x; p.y = y
            p.vx = cos(a) * sp
            p.vy = -abs(sin(a)) * sp * 0.7 - scale * 0.6
            p.gravity = scale * 5.5
            p.size = scale * (0.18 + CGFloat.random(in: 0..<1) * 0.22)
            p.maxLife = 0.45 + CGFloat.random(in: 0..<1) * 0.25
            p.life = p.maxLife
            p.color = UIColor.white.withAlphaComponent(0xCC.0 / 255)
        }
    }

    /// Basari yildizlari.
    func burst(_ x: CGFloat, _ y: CGFloat, scale: CGFloat, color: UIColor = Palette.coin) {
        ring(x, y, r0: scale * 0.3, r1: scale * 2.0, color: color.withAlphaComponent(0x66.0 / 255), life: 0.45)
        let n = max(3, Int(10 * quality))
        for _ in 0..<n {
            guard let p = spawn(.star) else { return }
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let sp = (0.6 + CGFloat.random(in: 0..<1)) * scale * 3.2
            p.x = x; p.y = y
            p.vx = cos(a) * sp
            p.vy = sin(a) * sp - scale * 1.2
            p.gravity = scale * 6
            p.size = scale * (0.14 + CGFloat.random(in: 0..<1) * 0.14)
            p.maxLife = 0.55 + CGFloat.random(in: 0..<1) * 0.3
            p.life = p.maxLife
            p.rot = CGFloat.random(in: 0..<1) * 6.28
            p.vrot = (CGFloat.random(in: 0..<1) - 0.5) * 12
            p.color = color
        }
    }

    /// Sandalyeden sayaca ucan coinler.
    func coins(from fromX: CGFloat, _ fromY: CGFloat, to toX: CGFloat, _ toY: CGFloat, count: Int, scale: CGFloat) {
        let n = min(14, max(3, Int(CGFloat(count) * quality)))
        for i in 0..<n {
            guard let p = spawn(.coin) else { return }
            p.x = fromX + (CGFloat.random(in: 0..<1) - 0.5) * scale * 1.6
            p.y = fromY + (CGFloat.random(in: 0..<1) - 0.5) * scale * 1.0
            p.targetX = toX; p.targetY = toY
            p.size = scale * 0.30
            p.maxLife = 0.55 + CGFloat(i) * 0.035
            p.life = p.maxLife
            p.vx = (CGFloat.random(in: 0..<1) - 0.5) * scale * 2
            p.vy = -scale * (1.5 + CGFloat.random(in: 0..<1))
            p.color = Palette.coin
        }
    }

    /// FAKE sandalye kaybolurken.
    func smoke(_ x: CGFloat, _ y: CGFloat, scale: CGFloat) {
        let n = max(3, Int(9 * quality))
        for _ in 0..<n {
            guard let p = spawn(.smoke) else { return }
            p.x = x + (CGFloat.random(in: 0..<1) - 0.5) * scale
            p.y = y + (CGFloat.random(in: 0..<1) - 0.5) * scale * 0.6
            p.vx = (CGFloat.random(in: 0..<1) - 0.5) * scale * 1.4
            p.vy = -scale * (0.8 + CGFloat.random(in: 0..<1) * 0.8)
            p.gravity = -scale * 0.4
            p.size = scale * (0.30 + CGFloat.random(in: 0..<1) * 0.25)
            p.maxLife = 0.5 + CGFloat.random(in: 0..<1) * 0.3
            p.life = p.maxLife
            p.color = UIColor(hex: "#CCE8E4F0")
        }
    }

    private func ring(_ x: CGFloat, _ y: CGFloat, r0: CGFloat, r1: CGFloat, color: UIColor, life: CGFloat) {
        if quality < 0.4 { return }
        let r = ringPool.obtain()
        r.x = x; r.y = y; r.startR = r0; r.endR = r1
        r.color = color; r.maxLife = life; r.life = life; r.alive = true
        rings.append(r)
    }

    private func spawn(_ kind: Kind) -> Particle? {
        if active.count >= 220 { return nil }
        let p = pool.obtain()
        p.kind = kind
        p.gravity = 0
        p.rot = 0; p.vrot = 0
        p.alive = true
        active.append(p)
        return p
    }

    // ---------------------------------------------------------------- dongu

    func update(_ dt: CGFloat) {
        var i = active.count - 1
        while i >= 0 {
            let p = active[i]
            p.life -= dt
            if p.life <= 0 {
                p.alive = false
                active.remove(at: i)
                pool.recycle(p)
            } else if p.kind == .coin {
                // Coin hedefe dogru hizlanarak gider (yay egrisi hissi).
                let t = 1 - (p.life / p.maxLife)
                let ease = t * t
                p.vx += (p.targetX - p.x) * ease * dt * 9
                p.vy += (p.targetY - p.y) * ease * dt * 9
                p.x += p.vx * dt
                p.y += p.vy * dt
            } else {
                p.vy += p.gravity * dt
                p.x += p.vx * dt
                p.y += p.vy * dt
                p.rot += p.vrot * dt
            }
            i -= 1
        }

        var j = rings.count - 1
        while j >= 0 {
            let r = rings[j]
            r.life -= dt
            if r.life <= 0 {
                r.alive = false
                rings.remove(at: j)
                ringPool.recycle(r)
            }
            j -= 1
        }
    }

    func draw(_ ctx: CGContext) {
        // Halkalar en altta
        for r in rings {
            let t = 1 - (r.life / r.maxLife)
            let rad = r.startR + (r.endR - r.startR) * (1 - (1 - t) * (1 - t))
            let alpha = ((1 - t) * 160 / 255).clamped(0, 1)
            ctx.setStrokeColor(r.color.withAlphaComponent(alpha).cgColor)
            ctx.strokeEllipse(cx: r.x, cy: r.y, rx: rad, ry: rad * 0.32, lineWidth: rad * 0.10)
        }

        for p in active {
            let t = p.life / p.maxLife
            switch p.kind {
            case .dust, .smoke:
                let alpha = (t * 200 / 255).clamped(0, 1)
                ctx.setFillColor(p.color.withAlphaComponent(alpha).cgColor)
                let s = p.size * (1 + (1 - t) * 0.8)
                ctx.fillEllipse(cx: p.x, cy: p.y, rx: s, ry: s * 0.85)
            case .coin:
                let alpha = (min(t, 0.35) / 0.35).clamped(0, 1)
                // Yandan bakinca yassilasan madeni para hissi
                let flat = abs(sin((1 - t) * 12))
                let c = flat < 0.4 ? Palette.coinDark : Palette.coin
                ctx.setFillColor(c.withAlphaComponent(alpha).cgColor)
                ctx.fillEllipse(cx: p.x, cy: p.y, rx: p.size * (0.35 + flat * 0.65), ry: p.size)
            case .star, .spark:
                let alpha = (t).clamped(0, 1)
                ctx.setFillColor(p.color.withAlphaComponent(alpha).cgColor)
                ctx.saveGState()
                ctx.rotate(degrees: p.rot * 180 / .pi, around: CGPoint(x: p.x, y: p.y))
                let s = p.size * (0.6 + t * 0.6)
                ctx.fillRoundRect(cx: p.x, cy: p.y, w: s * 2, h: s * 0.55, r: s * 0.27)
                ctx.fillRoundRect(cx: p.x, cy: p.y, w: s * 0.55, h: s * 2, r: s * 0.27)
                ctx.restoreGState()
            }
        }
    }
}
