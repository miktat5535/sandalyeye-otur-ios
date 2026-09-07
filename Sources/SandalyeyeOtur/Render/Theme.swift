import UIKit

/// Sahne paleti. Her 10 bolumluk blok kendi temasini kullanir -> oyuncu
/// ilerledigini GORUR. Yeni tema eklemek yeni sanat degil, yeni renk kaydidir.
/// (bkz. Theme.kt)
struct Theme {
    let id: String
    let skyTop: UIColor
    let skyBottom: UIColor
    let hillFar: UIColor
    let hillNear: UIColor
    let floor: UIColor
    let floorStripe: UIColor
    let floorEdge: UIColor
    /// Gunes/ay parlakligi. 0 = gizli.
    var sunAlpha: CGFloat = 1
    var sunColor: UIColor = UIColor(hex: "#FFF3B0")
    var cloudColor: UIColor = UIColor(hex: "#FFFFFFFF")
    var cloudAlpha: CGFloat = 0.90
    /// Baslik metni bu tema uzerinde okunur mu? Koyu temada acik metin.
    var darkBackdrop: Bool = false

    static let defaultTheme = Theme(
        id: "default", skyTop: UIColor(hex: "#7FD8F7"), skyBottom: UIColor(hex: "#CFF3FF"),
        hillFar: UIColor(hex: "#9BE3C8"), hillNear: UIColor(hex: "#6FD3AE"),
        floor: UIColor(hex: "#F2C57C"), floorStripe: UIColor(hex: "#E9B368"), floorEdge: UIColor(hex: "#D89B4F")
    )
    static let sunset = Theme(
        id: "sunset", skyTop: UIColor(hex: "#FF9E6D"), skyBottom: UIColor(hex: "#FFE0B8"),
        hillFar: UIColor(hex: "#C98BA8"), hillNear: UIColor(hex: "#A96B90"),
        floor: UIColor(hex: "#E8A96B"), floorStripe: UIColor(hex: "#DB9455"), floorEdge: UIColor(hex: "#C07C3F"),
        sunColor: UIColor(hex: "#FFD79A")
    )
    static let meadow = Theme(
        id: "meadow", skyTop: UIColor(hex: "#8FE3F0"), skyBottom: UIColor(hex: "#DFF8E8"),
        hillFar: UIColor(hex: "#7BD99B"), hillNear: UIColor(hex: "#57C47D"),
        floor: UIColor(hex: "#A9D97C"), floorStripe: UIColor(hex: "#96CA69"), floorEdge: UIColor(hex: "#7CAF52")
    )
    static let night = Theme(
        id: "night", skyTop: UIColor(hex: "#1E2A5A"), skyBottom: UIColor(hex: "#3E4E8C"),
        hillFar: UIColor(hex: "#2C3A6E"), hillNear: UIColor(hex: "#1F2A52"),
        floor: UIColor(hex: "#4A4470"), floorStripe: UIColor(hex: "#413B63"), floorEdge: UIColor(hex: "#332E4E"),
        sunAlpha: 0.85, sunColor: UIColor(hex: "#E8ECFF"), cloudAlpha: 0.35, darkBackdrop: true
    )
    static let desert = Theme(
        id: "desert", skyTop: UIColor(hex: "#FFCE7A"), skyBottom: UIColor(hex: "#FFEFC9"),
        hillFar: UIColor(hex: "#E0B072"), hillNear: UIColor(hex: "#CE9A57"),
        floor: UIColor(hex: "#F0C98A"), floorStripe: UIColor(hex: "#E3B771"), floorEdge: UIColor(hex: "#CDA059"),
        sunColor: UIColor(hex: "#FFF0A8")
    )
    static let arena = Theme(
        id: "arena", skyTop: UIColor(hex: "#6FC6E8"), skyBottom: UIColor(hex: "#CDEBF7"),
        hillFar: UIColor(hex: "#8E7BD6"), hillNear: UIColor(hex: "#7062BE"),
        floor: UIColor(hex: "#D98C6A"), floorStripe: UIColor(hex: "#C87A58"), floorEdge: UIColor(hex: "#AC6444")
    )
    static let fog = Theme(
        id: "fog", skyTop: UIColor(hex: "#B9C4CE"), skyBottom: UIColor(hex: "#E4EAF0"),
        hillFar: UIColor(hex: "#9EAAB6"), hillNear: UIColor(hex: "#87939F"),
        floor: UIColor(hex: "#C3BFB4"), floorStripe: UIColor(hex: "#B4B0A5"), floorEdge: UIColor(hex: "#9B978C"),
        sunAlpha: 0.35, cloudAlpha: 0.55
    )
    static let neon = Theme(
        id: "neon", skyTop: UIColor(hex: "#2A1B4D"), skyBottom: UIColor(hex: "#54307A"),
        hillFar: UIColor(hex: "#7A3FA8"), hillNear: UIColor(hex: "#5C2E84"),
        floor: UIColor(hex: "#3D2A63"), floorStripe: UIColor(hex: "#4A3376"), floorEdge: UIColor(hex: "#2E2049"),
        sunAlpha: 0.9, sunColor: UIColor(hex: "#FF7AE0"), cloudAlpha: 0.25, darkBackdrop: true
    )
    static let storm = Theme(
        id: "storm", skyTop: UIColor(hex: "#4E5A6E"), skyBottom: UIColor(hex: "#8894A6"),
        hillFar: UIColor(hex: "#4A5566"), hillNear: UIColor(hex: "#3A4452"),
        floor: UIColor(hex: "#6E6A62"), floorStripe: UIColor(hex: "#615D56"), floorEdge: UIColor(hex: "#4C4943"),
        sunAlpha: 0.20, cloudAlpha: 0.75, darkBackdrop: true
    )
    static let gold = Theme(
        id: "gold", skyTop: UIColor(hex: "#FFD98A"), skyBottom: UIColor(hex: "#FFF3D0"),
        hillFar: UIColor(hex: "#E8C46A"), hillNear: UIColor(hex: "#D4A94C"),
        floor: UIColor(hex: "#F5D793"), floorStripe: UIColor(hex: "#E9C67C"), floorEdge: UIColor(hex: "#D0A85C"),
        sunColor: UIColor(hex: "#FFFAE0")
    )

    private static let order: [Theme] = [defaultTheme, sunset, meadow, night, desert, arena, fog, neon, storm, gold]
    private static let byId: [String: Theme] = Dictionary(uniqueKeysWithValues: order.map { ($0.id, $0) })

    static func of(_ id: String) -> Theme { byId[id] ?? defaultTheme }

    /// Bolum numarasindan tema (her 10 bolumde bir degisir).
    static func forLevel(_ level: Int) -> Theme {
        let idx = max(0, min(order.count - 1, (level - 1) / 10))
        return order[idx]
    }
}
