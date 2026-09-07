import Foundation

/// Sihirli sayi yok kurali: oyunun tum ayarlanabilir sabitleri burada.
/// Denge ayari yaparken sadece bu dosyaya ve level JSON'una dokunulur.
/// (Android GameConstants.kt ile birebir eslenir — degerler ASLA sapmasin,
/// aksi halde iki platformda oyun farkli hissettirir.)
enum GameConstants {

    // MARK: - Tasarim uzayi
    /// Tum sanat 1080 birim genislige gore cizilir; yukseklik cihaza gore degisir.
    static let designWidth: CGFloat = 1080
    /// Referans yukseklik (9:16). Daha uzun ekranlarda ustte fazladan bosluk olusur.
    static let designHeightRef: CGFloat = 1920
    /// Bu orandan (h/w) daha "kare" ekranlar GENIS kip sayilir: tablet,
    /// katlanabilir, yatay telefon. Buyuk ekranlarda yon kilidi guvenilmez
    /// oldugu icin bu kip ZORUNLU (Android'deki targetSdk 36 gerekcesiyle ayni).
    static let portraitAspectMin: CGFloat = 1.40

    /// Arayuz olculerinin ust siniri - genis ekranda butonlar devlesmesin.
    static let maxUIWidth: CGFloat = 1250
    /// Oynanis seridinin ust siniri - genis ekranda yuruyus mesafesi buyumesin.
    static let maxPlayWidth: CGFloat = 1500

    // MARK: - Dongu
    static let targetFPS: Int = 60
    /// Tek karede islenecek en buyuk delta (arka plandan donunce sicramayi onler).
    static let maxDeltaSec: TimeInterval = 0.05

    // MARK: - Sahne yerlesimi (tasarim birimi)
    /// Zeminin ufuk cizgisi, ekran yuksekliginin orani olarak.
    static let horizonRatio: CGFloat = 0.46
    /// Karakterin durdugu zemin cizgisi orani.
    static let groundRatio: CGFloat = 0.78

    // MARK: - Karakter
    /// Miko'nun ayaktan tepeye toplam yuksekligi (tasarim birimi).
    static let mikoHeight: CGFloat = 320
    static let mikoWalkSpeed: CGFloat = 260      // birim/saniye
    static let mikoStepPeriod: TimeInterval = 0.42 // saniye/adim dongusu

    // MARK: - Sandalye
    static let chairHeight: CGFloat = 260
    /// Oturusun basarili sayildigi yatay tolerans (kolay zorluk).
    static let sitToleranceEasy: CGFloat = 70
    static let sitToleranceNormal: CGFloat = 46
    static let sitToleranceHard: CGFloat = 30
    /// Tam ortadan oturma - "PERFECT" esigi.
    static let sitPerfect: CGFloat = 14

    // MARK: - Ekonomi
    static let coinLevelComplete: Int = 100
    static let coinThreeStarBonus: Int = 50
    static let coinFirstTryBonus: Int = 100

    // MARK: - Combo
    static let comboTiers: [Int] = [2, 3, 4, 5, 10]

    // MARK: - Haptic (saniye) — iOS UIImpactFeedbackGenerator sure almaz,
    // ama karsilastirma/loglama icin Android'deki ms degerlerini koruyoruz.
    static let hapticSuccessMs: Double = 18
    static let hapticFailMs: Double = 45
    static let hapticComboMs: Double = 12
}
