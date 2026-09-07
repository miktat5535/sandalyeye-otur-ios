import CoreGraphics

/// Bir sandalyenin NE YAPTIGI. Gorunumden (ChairStyle) tamamen bagimsiz.
///
/// Oynanis kodu somut davranisi TANIMAZ; bolum verisindeki `behaviour` alanina
/// gore [ChairBehaviours.create] fabrikasindan alir. (bkz. ChairBehaviour.kt)
protocol ChairBehaviour: AnyObject {
    var id: String { get }
    func reset(_ chair: ChairActor)
    /// - Parameters:
    ///   - dt: saniye
    ///   - chair: guncellenecek sandalye
    ///   - ctx: oyuncunun konumu, sahne sinirlari
    func update(dt: CGFloat, chair: ChairActor, ctx: ChairBehaviourCtx)
}

extension ChairBehaviour {
    func reset(_ chair: ChairActor) {}
}

/// Davranisin ihtiyac duydugu dis dunya bilgisi.
final class ChairBehaviourCtx {
    /// Karakterin yatay konumu.
    var playerX: CGFloat = 0
    /// Karakterin zemin cizgisi.
    var groundY: CGFloat = 0
    /// Sahne genisligi (tasarim birimi).
    var sceneWidth: CGFloat = 1080
    /// Oyuncu oturma hamlesini baslatti mi?
    var playerCommitted = false
    /// Bolum zorluk carpani (hiz/genlik olceklemesi).
    var speedScale: CGFloat = 1
    /// Es sandalye (SWAP icin).
    weak var partner: ChairActor?
}

/// Davranis parametreleri. Bolum verisinden gelir; koda gomulmez.
struct ChairParams {
    /// Hareket hizi carpani
    var speed: CGFloat = 1
    /// Hareket genligi (tasarim birimi)
    var amplitude: CGFloat = 160
    /// Tetiklenme mesafesi (RUN, FAKE, TRAP)
    var triggerDistance: CGFloat = 260
    /// Donem/gecikme saniye (JUMP, INVISIBLE, SWAP)
    var period: CGFloat = 1.2
}

// ---------------------------------------------------------------------------
// 11 DAVRANIS
// ---------------------------------------------------------------------------

/// Sabit. Ogretici sandalye.
final class StaticBehaviour: ChairBehaviour {
    let id = "STATIC"
    func update(dt: CGFloat, chair: ChairActor, ctx: ChairBehaviourCtx) {
        chair.t += dt
    }
}

/// Saga sola kayar.
final class SlideBehaviour: ChairBehaviour {
    let id = "SLIDE"
    private let p: ChairParams
    init(_ p: ChairParams) { self.p = p }
    func update(dt: CGFloat, chair: ChairActor, ctx: ChairBehaviourCtx) {
        chair.t += dt
        let w = sin(chair.t * p.speed * ctx.speedScale * 2.4)
        chair.x = chair.homeX + w * p.amplitude
        // Hareket yonune hafif yatis - "kayiyor" hissi
        chair.turn = w * 0.18
    }
}

/// Kendi ekseninde doner; efektif oturma yuzeyi daralir.
final class RotateBehaviour: ChairBehaviour {
    let id = "ROTATE"
    private let p: ChairParams
    init(_ p: ChairParams) { self.p = p }
    func update(dt: CGFloat, chair: ChairActor, ctx: ChairBehaviourCtx) {
        chair.t += dt
        chair.turn = sin(chair.t * p.speed * ctx.speedScale * 2.2)
    }
}

/// Karakter yaklasinca kisa bir kacis atagi yapar, sonra yorulur.
final class RunBehaviour: ChairBehaviour {
    let id = "RUN"
    private let p: ChairParams
    init(_ p: ChairParams) { self.p = p }
    func reset(_ chair: ChairActor) {
        chair.triggered = false
        chair.scratchA = 0 // kacis ilerlemesi
    }
    func update(dt: CGFloat, chair: ChairActor, ctx: ChairBehaviourCtx) {
        chair.t += dt
        let dist = abs(ctx.playerX - chair.x)
        if !chair.triggered && dist < p.triggerDistance {
            chair.triggered = true
            chair.scratchA = 0
        }
        if chair.triggered {
            // Kacis: hizli baslar, yorulup durur (ters ustel)
            chair.scratchA = min(chair.scratchA + dt * p.speed * ctx.speedScale * 1.6, 1)
            let e = 1 - (1 - chair.scratchA) * (1 - chair.scratchA)
            chair.x = chair.homeX + p.amplitude * e
            chair.turn = (1 - chair.scratchA) * 0.35
            // Sahne disina cikmasin
            let maxX = ctx.sceneWidth - chair.height * 0.6
            if chair.x > maxX { chair.x = maxX }
        }
    }
}

/// Ritmik ziplar; havadayken oturulamaz.
final class JumpBehaviour: ChairBehaviour {
    let id = "JUMP"
    private let p: ChairParams
    init(_ p: ChairParams) { self.p = p }
    func update(dt: CGFloat, chair: ChairActor, ctx: ChairBehaviourCtx) {
        chair.t += dt
        let cycle = (chair.t.truncatingRemainder(dividingBy: p.period)) / p.period
        // Yarim sinus = zipla ve in
        let hop = cycle < 0.55 ? sin(cycle / 0.55 * 3.1416) : 0
        let lift = hop * p.amplitude * 0.55
        chair.y = chair.homeY - lift
        // Yerden 12 birimden fazla yukseldeyse oturulamaz
        chair.sittable = lift < 12
    }
}

/// Yaklasinca duman olup kaybolur. Dogrusu diger sandalyedir.
final class FakeBehaviour: ChairBehaviour {
    let id = "FAKE"
    private let p: ChairParams
    init(_ p: ChairParams) { self.p = p }
    func reset(_ chair: ChairActor) {
        chair.fake = true
        chair.triggered = false
        chair.gone = false
        chair.alpha = 1
    }
    func update(dt: CGFloat, chair: ChairActor, ctx: ChairBehaviourCtx) {
        chair.t += dt
        if !chair.triggered && abs(ctx.playerX - chair.x) < p.triggerDistance {
            chair.triggered = true
            chair.scratchA = 0
        }
        if chair.triggered && !chair.gone {
            chair.scratchA += dt * 5
            chair.alpha = max(1 - chair.scratchA, 0)
            chair.sittable = chair.alpha > 0.45
            if chair.alpha <= 0 { chair.gone = true }
        }
    }
}

/// Iki sandalye hizla yer degistirir (hokkabaz).
final class SwapBehaviour: ChairBehaviour {
    let id = "SWAP"
    private let p: ChairParams
    init(_ p: ChairParams) { self.p = p }
    func reset(_ chair: ChairActor) {
        chair.phase = 0
        chair.scratchA = chair.homeX
    }
    func update(dt: CGFloat, chair: ChairActor, ctx: ChairBehaviourCtx) {
        chair.t += dt
        guard let partner = ctx.partner else { return }
        let cycle = chair.t.truncatingRemainder(dividingBy: p.period)
        let swapDur = 0.42 / max(p.speed, 0.2)

        if cycle < swapDur {
            let k = smoothStep((cycle / swapDur).clamped(0, 1))
            let from = chair.scratchA
            let to = partner.homeX
            chair.x = from + (to - from) * k
            // Takas sirasinda kavis cizerek gecerler - goz takip edebilsin
            chair.y = chair.homeY - sin(k * 3.1416) * 26
        } else {
            chair.y = chair.homeY
            if chair.scratchA != partner.homeX && cycle > swapDur + 0.02 {
                // Takas tamamlandi: ev konumlarini degistir
                let tmp = chair.homeX
                chair.homeX = partner.homeX
                partner.homeX = tmp
                chair.scratchA = chair.homeX
                chair.x = chair.homeX
                chair.t = 0
            }
        }
    }
    private func smoothStep(_ x: CGFloat) -> CGFloat { x * x * (3 - 2 * x) }
}

/// Belirli araliklarla saydamlasir; oyuncu hafizadan oynar.
final class InvisibleBehaviour: ChairBehaviour {
    let id = "INVISIBLE"
    private let p: ChairParams
    init(_ p: ChairParams) { self.p = p }
    func update(dt: CGFloat, chair: ChairActor, ctx: ChairBehaviourCtx) {
        chair.t += dt
        let cycle = (chair.t.truncatingRemainder(dividingBy: p.period)) / p.period
        // Yarisinda gorunur, yarisinda degil; gecisler yumusak
        let a: CGFloat
        switch cycle {
        case ..<0.35: a = 1
        case ..<0.45: a = 1 - (cycle - 0.35) / 0.10
        case ..<0.85: a = 0
        default: a = (cycle - 0.85) / 0.15
        }
        chair.alpha = a.clamped(0, 1)
        // Gorunmez olsa da OTURULABILIR - mesele gormek degil, hatirlamak
        chair.sittable = true
    }
}

/// Kisa sure yukari ucar, geri iner.
final class RocketBehaviour: ChairBehaviour {
    let id = "ROCKET"
    private let p: ChairParams
    init(_ p: ChairParams) { self.p = p }
    func update(dt: CGFloat, chair: ChairActor, ctx: ChairBehaviourCtx) {
        chair.t += dt
        let cycle = (chair.t.truncatingRemainder(dividingBy: p.period)) / p.period
        let lift: CGFloat
        switch cycle {
        case ..<0.30: lift = cycle / 0.30
        case ..<0.55: lift = 1
        case ..<0.80: lift = 1 - (cycle - 0.55) / 0.25
        default: lift = 0
        }
        let liftC = lift.clamped(0, 1)
        let h = liftC * p.amplitude * 1.6
        chair.y = chair.homeY - h
        chair.turn = liftC * 0.20
        chair.sittable = h < 14
    }
}

/// Karakteri kendine ceker: yardim gibi gorunur, zamanlamayi bozar.
final class MagnetBehaviour: ChairBehaviour {
    let id = "MAGNET"
    private let p: ChairParams
    init(_ p: ChairParams) { self.p = p }

    /// Oynanis bunu okur ve karakteri kaydirir.
    private(set) var pullThisFrame: CGFloat = 0

    func update(dt: CGFloat, chair: ChairActor, ctx: ChairBehaviourCtx) {
        chair.t += dt
        let d = chair.x - ctx.playerX
        let dist = abs(d)
        if dist < p.triggerDistance && dist > 1 {
            let strength = 1 - (dist / p.triggerDistance)
            // Nabiz atarak ceker - ongorulemez olmasi zorlugu yaratir
            let pulse = 0.55 + 0.45 * sin(chair.t * 6)
            pullThisFrame = (d > 0 ? 1 : -1) * strength * pulse * p.speed * 190 * dt
        } else {
            pullThisFrame = 0
        }
        // Gorsel ipucu: cekerken hafif titrer
        chair.turn = pullThisFrame != 0 ? sin(chair.t * 22) * 0.10 : 0
    }
}

/// Karakter yaklasinca katlanir/acilir; kapaliyken oturulamaz.
final class TrapBehaviour: ChairBehaviour {
    let id = "TRAP"
    private let p: ChairParams
    init(_ p: ChairParams) { self.p = p }
    func reset(_ chair: ChairActor) {
        chair.triggered = false
        chair.scratchA = 0
    }
    func update(dt: CGFloat, chair: ChairActor, ctx: ChairBehaviourCtx) {
        chair.t += dt
        if !chair.triggered && abs(ctx.playerX - chair.x) < p.triggerDistance {
            chair.triggered = true
        }
        if chair.triggered {
            // Acilip kapanir; kapali = oturulamaz
            chair.scratchA += dt * p.speed * 3.2
            let k = (sin(chair.scratchA) + 1) * 0.5 // 0..1
            chair.turn = 0.85 * (1 - k) // kapaninca yandan gorunur
            chair.sittable = k > 0.55
        }
    }
}

// ---------------------------------------------------------------------------

enum ChairBehaviours {
    /// Bolum verisindeki metin kimlikten davranis uretir.
    /// Bilinmeyen kimlik gelirse STATIC dondurur - bozuk veri oyunu COKERTMEZ.
    static func create(_ id: String, _ p: ChairParams) -> ChairBehaviour {
        switch id.uppercased() {
        case "STATIC": return StaticBehaviour()
        case "SLIDE": return SlideBehaviour(p)
        case "ROTATE": return RotateBehaviour(p)
        case "RUN": return RunBehaviour(p)
        case "JUMP": return JumpBehaviour(p)
        case "FAKE": return FakeBehaviour(p)
        case "SWAP": return SwapBehaviour(p)
        case "INVISIBLE": return InvisibleBehaviour(p)
        case "ROCKET": return RocketBehaviour(p)
        case "MAGNET": return MagnetBehaviour(p)
        case "TRAP": return TrapBehaviour(p)
        default: return StaticBehaviour()
        }
    }

    static let all = ["STATIC", "SLIDE", "ROTATE", "RUN", "JUMP", "FAKE", "SWAP", "INVISIBLE", "ROCKET", "MAGNET", "TRAP"]
}
