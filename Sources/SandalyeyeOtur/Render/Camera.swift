import CoreGraphics

/// Sahne kamerasi: yatay takip + sarsinti + hafif zoom.
///
/// Kamera oyuncuya "bu bir sahne, dolasan bir alan" hissi verir. Sabit bir
/// ekranda oynanan oyun tahta gibi durur; 20-30 birimlik yumusak bir takip
/// bile sahneyi canlandirir. (bkz. Camera.kt)
final class Camera {
    /// Kameranin baktigi yatay merkez (tasarim birimi).
    private(set) var x: CGFloat = 0

    private var targetX: CGFloat = 0
    private var shakeTime: CGFloat = 0
    private var shakeDuration: CGFloat = 0
    private var shakeAmount: CGFloat = 0
    private var shakeSeed: CGFloat = 0

    /// 1 = normal. Basari aninda hafif icine cekilir.
    private(set) var zoom: CGFloat = 1
    private var targetZoom: CGFloat = 1

    func reset(_ centerX: CGFloat) {
        x = centerX
        targetX = centerX
        shakeTime = 0
        shakeDuration = 0
        zoom = 1
        targetZoom = 1
    }

    func follow(_ worldX: CGFloat) {
        targetX = worldX
    }

    func setZoom(_ z: CGFloat) {
        targetZoom = z
    }

    func shake(amount: CGFloat, duration: CGFloat) {
        // Devam eden daha guclu bir sarsintiyi zayifi ezmesin.
        if amount >= shakeAmount || shakeTime >= shakeDuration {
            shakeAmount = amount
            shakeDuration = duration
            shakeTime = 0
            shakeSeed = CGFloat.random(in: 0..<100)
        }
    }

    func update(_ dt: CGFloat) {
        // Kritik sonumleme yerine basit ustel yaklasim: kararli ve ucuz.
        x += (targetX - x) * (1 - pow(0.0015, dt))
        zoom += (targetZoom - zoom) * (1 - pow(0.0025, dt))
        if shakeTime < shakeDuration { shakeTime += dt }
    }

    /// Baglami kamera uzayina gecirir. [restore] ile geri alinir.
    func apply(_ ctx: CGContext, viewCenterX: CGFloat, viewCenterY: CGFloat) {
        ctx.saveGState()
        var ox = viewCenterX - x
        var oy: CGFloat = 0
        if shakeTime < shakeDuration && shakeDuration > 0 {
            let k = 1 - (shakeTime / shakeDuration) // sonumlenir
            let t = (shakeTime + shakeSeed) * 62
            ox += sin(t) * shakeAmount * k
            oy += sin(t * 1.37 + 1.1) * shakeAmount * k * 0.7
        }
        if zoom != 1 {
            ctx.translateBy(x: viewCenterX, y: viewCenterY)
            ctx.scaleBy(x: zoom, y: zoom)
            ctx.translateBy(x: -viewCenterX, y: -viewCenterY)
        }
        ctx.translateBy(x: ox, y: oy)
    }

    func restore(_ ctx: CGContext) { ctx.restoreGState() }
}
