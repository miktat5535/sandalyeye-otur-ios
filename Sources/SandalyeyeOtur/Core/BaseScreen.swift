import CoreGraphics

/// Ekranlarin ortak tabani.
///
/// Dokunma olaylari ile cizim/mantik ayni ana kuyrukta calisir (Android'deki
/// UI thread/render thread ayrimi burada yok), ama ekran olculerinin her
/// karede tek yerde saklanmasi faydasi aynen gecerli: alt siniflar [vw]/[vh]
/// uzerinden okur, her ekranda ayni kodu tekrarlamaz. (bkz. BaseScreen.kt)
class BaseScreen: Screen {
    var next: Screen?

    private(set) var vw: CGFloat = GameConstants.designWidth
    private(set) var vh: CGFloat = GameConstants.designHeightRef
    private(set) var safeTop: CGFloat = 0
    private(set) var safeBottom: CGFloat = 0

    /// Ekran ORTASI. [vw] arayuz OLCUSU icindir; konumlandirma her zaman
    /// bunun etrafinda yapilir. Genis ekranda ikisi ayrisir.
    private(set) var cx: CGFloat = GameConstants.designWidth * 0.5

    final func update(_ dt: CGFloat, _ vp: Viewport) {
        vw = vp.uiWidth
        vh = vp.designHeight
        cx = vp.centerX
        safeTop = vp.safeTop
        safeBottom = vp.safeBottom
        onUpdate(dt, vp)
    }

    /// Alt siniflar bunu override eder (Kotlin'deki `abstract fun onUpdate`).
    func onUpdate(_ dt: CGFloat, _ vp: Viewport) {
        fatalError("BaseScreen alt sinifi onUpdate(_:_:) override etmeli")
    }

    func draw(_ ctx: CGContext, _ vp: Viewport) {
        fatalError("BaseScreen alt sinifi draw(_:_:) override etmeli")
    }

    // Asagidakiler protokolun varsayilan (bos) davranisini BURADA, gercek
    // sinif govdesi olarak saglar. Sebep: Swift'te bir protokol-uzantisi
    // varsayilani, alt siniflarda `override` ile degistirilemez ("does not
    // override any method from its superclass" hatasi verir) - `override`
    // yalnizca UST SINIFIN KENDI govdesinde tanimladigi metotlar icin
    // gecerlidir. Bu yuzden BaseScreen bu metotlari (bos govdeyle de olsa)
    // KENDI govdesinde tanimlamak zorunda, aksi halde onlari override eden
    // her ekran (MainMenuScreen, LevelSelectScreen, ...) derlenmez.
    func onEnter(_ vp: Viewport) {}
    func onTouch(x: CGFloat, y: CGFloat, down: Bool) -> Bool { false }
    func onTouchMoved(x: CGFloat, y: CGFloat) {}
    func onTouchCancelled() {}
    func onBack() -> Bool { false }
    func onExit() {}
}
