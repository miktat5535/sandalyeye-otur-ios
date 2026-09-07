import CoreGraphics

/// Sahnedeki bir sandalyenin CALISMA ZAMANI hali.
///
/// Gorunum (`style`) ve davranis (`behaviour`) disaridan verilir; bu sinif
/// yalnizca ikisinin ortak durumunu tutar. (bkz. ChairActor.kt)
final class ChairActor {

    /// Baslangic (ev) konumu - davranislarin referans aldigi nokta.
    var homeX: CGFloat = 0
    var homeY: CGFloat = 0

    var x: CGFloat = 0
    var y: CGFloat = 0

    /// Gorsel yukseklik (tasarim birimi).
    var height: CGFloat = 200

    /// -1..+1 donus. ROTATE kullanir; oturma toleransini daraltir.
    var turn: CGFloat = 0

    /// 0..1 gorunurluk. INVISIBLE ve FAKE kullanir.
    var alpha: CGFloat = 1

    /// false ise bu sandalyeye oturulamaz (havada, kapali, yok olmus).
    var sittable = true

    /// Bu sandalye sahte mi? Oturulursa fail.
    var fake = false

    /// Bu bolumun DOGRU sandalyesi mi? (coklu sandalye bolumlerinde)
    var isTarget = true

    /// Sahneden tamamen kalkti mi (FAKE kayboldu).
    var gone = false

    var style: ChairStyle!
    var behaviour: ChairBehaviour!

    /// Davranisin kendi ic sayaclari icin serbest alanlar.
    var t: CGFloat = 0
    var phase: CGFloat = 0
    var scratchA: CGFloat = 0
    var scratchB: CGFloat = 0
    var triggered = false

    func reset(style: ChairStyle, behaviour: ChairBehaviour, x: CGFloat, y: CGFloat, height: CGFloat) {
        self.style = style
        self.behaviour = behaviour
        homeX = x
        homeY = y
        self.x = x
        self.y = y
        self.height = height
        turn = 0
        alpha = 1
        sittable = true
        fake = false
        isTarget = true
        gone = false
        t = 0
        phase = 0
        scratchA = 0
        scratchB = 0
        triggered = false
        behaviour.reset(self)
    }

    /// Oturma yuzeyinin merkezi (popo hedefi).
    var seatY: CGFloat { ChairArtist.seatY(groundY: y, height: height) }

    /// Donus nedeniyle efektif oturma genisligi daralir.
    /// ROTATE mekaniginin zorlugu tam olarak buradan gelir.
    var toleranceScale: CGFloat { 1 - abs(turn) * 0.55 }
}
