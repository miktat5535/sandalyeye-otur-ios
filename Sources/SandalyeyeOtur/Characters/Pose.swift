import CoreGraphics

/// Miko'nun tek karelik hali. Animasyonlar bu alanlari zamanla degistirir;
/// cizim kodu (MikoArtist) tamamen durumsuzdur. (bkz. Pose.kt)
struct Pose {
    /// Govde egimi, derece. + ileri.
    var lean: CGFloat = 0
    /// Kalca yuksekligi carpani (1 = ayakta, 0.55 = tam oturmus).
    var hipDrop: CGFloat = 0
    /// Yuruyus fazi 0..1
    var stepPhase: CGFloat = 0
    /// Dikey zipzip (nefes/adim) - birim.
    var bob: CGFloat = 0
    /// Ezilme/uzama: 1 = normal, >1 uzun-ince, <1 basik-genis.
    var squash: CGFloat = 1
    /// Kafa egimi, derece.
    var headTilt: CGFloat = 0
    /// Tum karakter donusu (dusme icin), derece.
    var bodyRotation: CGFloat = 0
    /// Kollar: -1 asagi, 0 yanda, +1 yukarida (kutlama).
    var armRaise: CGFloat = 0
    var face: Face = .neutral
    /// Goz kirpma 0..1 (1 = tamamen kapali).
    var blink: CGFloat = 0
    /// Bakis yonu: -1 sol, 0 karsi, +1 sag.
    var lookX: CGFloat = 0

    enum Face { case neutral, happy, surprised, confused, dizzy, determined }
}
