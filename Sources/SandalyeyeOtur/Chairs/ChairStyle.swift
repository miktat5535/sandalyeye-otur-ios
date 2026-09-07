import UIKit

/// Bir sandalyenin GORUNUMU. Davranistan (ChairBehaviour, henuz portlanmadi)
/// tamamen ayridir: her gorunum her davranisla eslesebilir.
/// (bkz. ChairStyle.kt)
struct ChairStyle {
    enum BackType: Equatable { case none, rounded, slats, high, winged }
    enum LegType: Equatable { case four, wheels, xFold, pedestal, sled }

    let id: String
    let displayName: String
    let seat: UIColor
    let seatShade: UIColor
    let frame: UIColor
    let frameShade: UIColor
    /// Sirt dayama tipi
    var back: BackType = .rounded
    /// Ayak tipi
    var legs: LegType = .four
    /// Oturma yuzeyi genisligi carpani (dev/mini sandalye icin).
    var sizeScale: CGFloat = 1
    /// Parlak yuzey (altin, neon, buz)
    var glossy: Bool = false

    /// MVP'nin 3 sandalyesi (bkz. docs/CHAIRS_SPEC.md).
    static let plastic = ChairStyle(
        id: "chair_plastic", displayName: "Plastik Sandalye",
        seat: Palette.chairPlastic, seatShade: Palette.chairPlasticShade,
        frame: Palette.chairPlastic, frameShade: Palette.chairPlasticShade,
        back: .rounded, legs: .four
    )
    static let wood = ChairStyle(
        id: "chair_wood", displayName: "Ahşap Sandalye",
        seat: Palette.chairWood, seatShade: Palette.chairWoodShade,
        frame: Palette.chairWood, frameShade: Palette.chairWoodShade,
        back: .slats, legs: .four
    )
    static let office = ChairStyle(
        id: "chair_office", displayName: "Ofis Koltuğu",
        seat: Palette.ink, seatShade: UIColor(hex: "#1A1526"),
        frame: Palette.chairMetal, frameShade: Palette.chairMetalShade,
        back: .high, legs: .wheels
    )

    static let mvp: [ChairStyle] = [plastic, wood, office]
}
