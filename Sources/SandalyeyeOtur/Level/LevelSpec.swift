import Foundation

/// Bir bolumun TUM tanimi. Koda hicbir bolum gomulmez; bunlar
/// `Resources/levels/levels.json` dosyasindan okunur (Android surumuyle
/// BYTE-ESIT ayni dosya — bkz. LevelSpec.kt).
///
/// Yeni bolum eklemek = JSON'a bir nesne eklemek. Kod degismez.
struct LevelSpec {
    let id: Int
    /// 1..5 gorsel zorluk gostergesi
    let difficulty: Int
    /// Bu bolumdeki sandalyeler (en az 1)
    let chairs: [ChairSpec]
    /// Oturma toleransi (tasarim birimi). Buyuk = kolay.
    let tolerance: CGFloat
    /// Karakterin yuruyus hizi carpani
    let walkSpeed: CGFloat
    /// Davranis hiz carpani
    let speedScale: CGFloat
    /// Sure siniri (saniye). 0 = sinirsiz.
    let timeLimit: CGFloat
    /// Tamamlama odulu
    let reward: Int
    /// Her 10 bolumde bir ozel bolum hissi
    let special: Bool
    /// Ayni sandalyeyi isteyen rakip karakter sayisi (bolum 51+)
    let rivals: Int
    /// Sahne paleti kimligi (tema).
    let theme: String
    /// Bolum basinda gosterilecek kisa ipucu (ilk kez oynanirken).
    let hint: String

    struct ChairSpec {
        /// ChairStyle kimligi, orn. "chair_plastic"
        let style: String
        /// ChairBehaviour kimligi, orn. "SLIDE"
        let behaviour: String
        /// Sahnedeki yatay konum, ekran genisliginin orani (0..1)
        let xRatio: CGFloat
        let speed: CGFloat
        let amplitude: CGFloat
        let triggerDistance: CGFloat
        let period: CGFloat
        /// Bu sandalye sahte mi (oturulursa fail)
        let fake: Bool
    }

    /// Bozuk/eksik veri geldiginde kullanilacak guvenli bolum.
    static let fallback = LevelSpec(
        id: 1,
        difficulty: 1,
        chairs: [ChairSpec(style: "chair_plastic", behaviour: "STATIC", xRatio: 0.62,
                            speed: 1, amplitude: 160, triggerDistance: 260, period: 1.2, fake: false)],
        tolerance: 70,
        walkSpeed: 1,
        speedScale: 1,
        timeLimit: 0,
        reward: 100,
        special: false,
        rivals: 0,
        theme: "default",
        hint: ""
    )
}

// MARK: - Gevsek JSON ayristirma (org.json'daki optX() davranisini birebir taklit eder)
//
// Kural 40: dosya yoksa veya bozuksa uygulama COKMEZ - elde ne varsa onu
// kullanir, tek bir bozuk bolum tum dosyayi cope atmaz.
extension LevelSpec {
    /// `[String: Any]` sozlugunden esnek okuma. Android'deki `optInt/optDouble/
    /// optString/optBoolean` mantigiyla ayni: alan yoksa veya tipi uyusmuyorsa
    /// sessizce varsayilana duser, ASLA fırlatmaz.
    init?(json o: [String: Any], fallbackId: Int) {
        guard let chairsArr = o["chairs"] as? [[String: Any]] else { return nil }
        var parsedChairs: [ChairSpec] = []
        parsedChairs.reserveCapacity(chairsArr.count)
        for c in chairsArr {
            let style = (c["style"] as? String) ?? "chair_plastic"
            let behaviour = (c["behaviour"] as? String) ?? "STATIC"
            let xRatio = CGFloat((c["xRatio"] as? Double) ?? 0.62)
            let speed = CGFloat((c["speed"] as? Double) ?? 1.0)
            let amplitude = CGFloat((c["amplitude"] as? Double) ?? 160.0)
            let triggerDistance = CGFloat((c["triggerDistance"] as? Double) ?? 260.0)
            let period = CGFloat((c["period"] as? Double) ?? 1.2)
            let fake = (c["fake"] as? Bool) ?? false
            parsedChairs.append(ChairSpec(style: style, behaviour: behaviour, xRatio: xRatio,
                                           speed: speed, amplitude: amplitude,
                                           triggerDistance: triggerDistance, period: period, fake: fake))
        }
        // Sandalyesiz bolum oynanamaz - atla, cokme.
        guard !parsedChairs.isEmpty else { return nil }

        id = (o["id"] as? Int) ?? fallbackId
        difficulty = (o["difficulty"] as? Int) ?? 1
        chairs = parsedChairs
        tolerance = CGFloat((o["tolerance"] as? Double) ?? 70.0)
        walkSpeed = CGFloat((o["walkSpeed"] as? Double) ?? 1.0)
        speedScale = CGFloat((o["speedScale"] as? Double) ?? 1.0)
        timeLimit = CGFloat((o["timeLimit"] as? Double) ?? 0.0)
        reward = (o["reward"] as? Int) ?? 100
        special = (o["special"] as? Bool) ?? false
        rivals = (o["rivals"] as? Int) ?? 0
        theme = (o["theme"] as? String) ?? "default"
        hint = (o["hint"] as? String) ?? ""
    }
}
