import CoreGraphics

/// Oyunun her ekrani (splash, menu, oynanis, bolum sonu...) bu protokolu uygular.
/// Ekranlar birbirini TANIMAZ; gecis istegi [next] uzerinden yapilir.
///
/// Bu ayrim sayesinde gameplay kodu UI kodundan bagimsiz kalir. (bkz. Screen.kt)
protocol Screen: AnyObject {
    /// Ekran ilk gorundugunde.
    func onEnter(_ vp: Viewport)

    /// Saniye cinsinden delta ile mantik guncellemesi.
    func update(_ dt: CGFloat, _ vp: Viewport)

    /// Tasarim uzayinda cizim (baglam zaten olceklendi).
    func draw(_ ctx: CGContext, _ vp: Viewport)

    /// - Parameter down: true = parmak degdi, false = kalkti
    /// - Returns: true = olay tuketildi
    @discardableResult
    func onTouch(x: CGFloat, y: CGFloat, down: Bool) -> Bool

    /// Geri tusu / kapatma jesti. true dondurursen olay tuketilir.
    func onBack() -> Bool

    func onExit()

    /// nil degilse bir sonraki karede bu ekrana gecilir.
    var next: Screen? { get set }
}

/// Protokol varsayilanlari (Kotlin `interface`teki `= false`/bos govde karsiligi).
extension Screen {
    func onEnter(_ vp: Viewport) {}
    func onTouch(x: CGFloat, y: CGFloat, down: Bool) -> Bool { false }
    func onBack() -> Bool { false }
    func onExit() {}
}
