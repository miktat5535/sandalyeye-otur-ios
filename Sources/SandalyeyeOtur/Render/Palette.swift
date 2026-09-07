import UIKit

/// Oyunun TEK renk kaynagi. Hicbir yerde ham hex yazilmaz.
/// (bkz. Palette.kt — degerler birebir ayni, referans: docs/UI_STYLE_GUIDE.md)
enum Palette {
    // MARK: - Sahne / atmosfer
    static let skyTop = UIColor(hex: "#7FD8F7")
    static let skyBottom = UIColor(hex: "#CFF3FF")
    static let hillFar = UIColor(hex: "#9BE3C8")
    static let hillNear = UIColor(hex: "#6FD3AE")
    static let floor = UIColor(hex: "#F2C57C")
    static let floorStripe = UIColor(hex: "#E9B368")
    static let floorEdge = UIColor(hex: "#D89B4F")
    static let shadow = UIColor(hex: "#33221A2E") // ARGB - alpha ilk iki hane

    // MARK: - Marka
    static let orange = UIColor(hex: "#FF7A3D")
    static let orangeDark = UIColor(hex: "#E25F26")
    static let ink = UIColor(hex: "#2B2438")
    static let cream = UIColor(hex: "#FFF6E6")
    static let coin = UIColor(hex: "#FFC53D")
    static let coinDark = UIColor(hex: "#E5A013")

    // MARK: - Durum
    static let success = UIColor(hex: "#4CD98A")
    static let fail = UIColor(hex: "#FF5C7A")
    static let hint = UIColor(hex: "#7C6BFF")

    // MARK: - Miko (varsayilan skin)
    static let mikoShirt = orange
    static let mikoShirtShade = orangeDark
    static let mikoPants = UIColor(hex: "#3A3550")
    static let mikoPantsShade = UIColor(hex: "#2A263C")
    static let mikoSkin = UIColor(hex: "#FFD9A8")
    static let mikoSkinShade = UIColor(hex: "#F0BE86")
    static let mikoHair = UIColor(hex: "#3A2E2A")
    static let mikoShoe = UIColor(hex: "#FFFFFF")
    static let mikoShoeSole = UIColor(hex: "#DDE3EA")

    // MARK: - Sandalye (temel plastik)
    static let chairPlastic = UIColor(hex: "#5AC8FA")
    static let chairPlasticShade = UIColor(hex: "#3AA8DC")
    static let chairWood = UIColor(hex: "#C98A4B")
    static let chairWoodShade = UIColor(hex: "#A96E36")
    static let chairMetal = UIColor(hex: "#B8C4CE")
    static let chairMetalShade = UIColor(hex: "#8E9AA6")

    // MARK: - UI
    static let uiPanel = UIColor(hex: "#FFFFFF")
    static let uiPanelShade = UIColor(hex: "#E4E9F2")
    static let uiTextDark = ink
    static let uiTextLight = UIColor(hex: "#FFFFFF")
    static let uiOutline = UIColor(hex: "#2B2438")
}

extension UIColor {
    /// "#RRGGBB" veya "#AARRGGBB" (Android Color.parseColor ile ayni sirali) hex parse eder.
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)

        let a, r, g, b: UInt64
        switch s.count {
        case 8: // AARRGGBB
            a = (value >> 24) & 0xFF
            r = (value >> 16) & 0xFF
            g = (value >> 8) & 0xFF
            b = value & 0xFF
        case 6: // RRGGBB
            a = 0xFF
            r = (value >> 16) & 0xFF
            g = (value >> 8) & 0xFF
            b = value & 0xFF
        default:
            a = 0xFF; r = 0; g = 0; b = 0
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255,
                   alpha: CGFloat(a) / 255)
    }
}
