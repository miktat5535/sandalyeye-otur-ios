import CoreGraphics

/// Cozunurluk ve en-boy oranindan bagimsizlik.
///
/// IKI kip vardir:
///
///  1) DIKEY (h/w >= 1.4) - telefonlarin normali.
///     Genislik 1080 birime sabitlenir, yukseklik cihaz oranindan turer.
///     Uzun telefonlarda sahne gerilmez, sadece daha cok gokyuzu gorunur.
///
///  2) GENIS (h/w < 1.4) - iPad, katlanabilir, yatay.
///     Yukseklik 1920 birime sabitlenir, genislik cihaz oranindan turer.
///     Sahne yanlara dogru buyur (SceneArtist zaten ekrandan genis cizer).
///
/// Bu mantik Android surumuyle BIREBIR aynidir (bkz. Viewport.kt) — degerler
/// sapmasin, aksi halde iki platformda oyun farkli hissettirir.
///
/// Arayuzun devasa gorunmemesi icin ayrica `uiWidth` vardir: arayuz OLCULERI
/// bununla hesaplanir ve sinirlanir; KONUM ise her zaman `centerX` etrafinda
/// verilir. Boylece cok genis ekranda oyun alani genisler ama butonlar makul
/// boyutta ortada kalir.
final class Viewport {

    private(set) var pixelWidth: CGFloat = 0
    private(set) var pixelHeight: CGFloat = 0
    private(set) var scale: CGFloat = 1

    private(set) var designWidth: CGFloat = GameConstants.designWidth
    private(set) var designHeight: CGFloat = GameConstants.designHeightRef

    /// true = genis/yatay kip (iPad, katlanabilir, yatay telefon).
    private(set) var wideMode = false

    /// Guvenli bosluklar (Dynamic Island, home indicator) - tasarim biriminde.
    var safeTop: CGFloat = 0
    var safeBottom: CGFloat = 0
    var safeLeft: CGFloat = 0
    var safeRight: CGFloat = 0

    /// Arayuz olculeri icin referans genislik.
    /// Dar ekranda `designWidth` ile ayni; cok genis ekranda sinirlanir.
    var uiWidth: CGFloat {
        designWidth < GameConstants.maxUIWidth ? designWidth : GameConstants.maxUIWidth
    }

    /// Oynanisin kullandigi yatay serit genisligi.
    var playWidth: CGFloat {
        designWidth < GameConstants.maxPlayWidth ? designWidth : GameConstants.maxPlayWidth
    }

    /// - Parameters bekleneni pixel cinsindendir (UIScreen point degil — draw
    ///   katmani pixel-doldurma icin bunu boyle kullanir; caller `contentScaleFactor`
    ///   ile carpip cagirir).
    func onSurfaceChanged(
        widthPx: CGFloat, heightPx: CGFloat,
        insetTopPx: CGFloat = 0, insetBottomPx: CGFloat = 0,
        insetLeftPx: CGFloat = 0, insetRightPx: CGFloat = 0
    ) {
        pixelWidth = widthPx
        pixelHeight = heightPx
        guard widthPx > 0, heightPx > 0 else { return }

        let aspect = heightPx / widthPx
        if aspect >= GameConstants.portraitAspectMin {
            // DIKEY: genisligi sabitle, yukseklik turesin
            wideMode = false
            scale = widthPx / GameConstants.designWidth
            designWidth = GameConstants.designWidth
            designHeight = heightPx / scale
        } else {
            // GENIS: yuksekligi sabitle, genislik uzasin
            wideMode = true
            scale = heightPx / GameConstants.designHeightRef
            designHeight = GameConstants.designHeightRef
            designWidth = widthPx / scale
        }

        safeTop = insetTopPx / scale
        safeBottom = insetBottomPx / scale
        safeLeft = insetLeftPx / scale
        safeRight = insetRightPx / scale
    }

    /// Context'i tasarim uzayina gecirir. Cizimden once cagrilir.
    func apply(_ context: CGContext) {
        context.scaleBy(x: scale, y: scale)
    }

    /// Ekran pikselini tasarim birimine cevirir (dokunma girdisi icin).
    func toDesignX(_ px: CGFloat) -> CGFloat { px / scale }
    func toDesignY(_ py: CGFloat) -> CGFloat { py / scale }

    var horizonY: CGFloat { designHeight * GameConstants.horizonRatio }
    var groundY: CGFloat { designHeight * GameConstants.groundRatio }
    var centerX: CGFloat { designWidth / 2 }

    /// Bolum verisindeki 0..1 yatay orani sahne konumuna cevirir.
    ///
    /// Oran dogrudan `designWidth` ile carpilmaz; ORTALANMIS bir oyun seridine
    /// yerlestirilir. Boylece iPad'de Miko ekranin bir ucundan digerine
    /// yurumek zorunda kalmaz, oynanis her cihazda ayni hizda kalir.
    func playX(_ ratio: CGFloat) -> CGFloat {
        centerX + (ratio - 0.5) * playWidth
    }
}
