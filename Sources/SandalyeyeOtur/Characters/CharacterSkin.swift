import UIKit

/// Bir karakterin GORUNUMU sadece renk + birkac sekil bayragidir.
/// Ayni iskelet 10 skin'i besler (bkz. docs/ART_ASSET_LIST.md > Karakterler).
/// (bkz. CharacterSkin.kt)
struct CharacterSkin {
    let id: String
    let displayName: String
    let shirt: UIColor
    let shirtShade: UIColor
    let pants: UIColor
    let pantsShade: UIColor
    let skin: UIColor
    let skinShade: UIColor
    let hair: UIColor
    let shoe: UIColor
    let shoeSole: UIColor
    /// Kafa ustu aksesuar
    var headGear: HeadGear = .hairTuft
    /// Goz stili: round (Miko), visor (robot/astronot), slit (ninja), big (uzayli)
    var eyeStyle: EyeStyle = .round

    enum HeadGear { case none, hairTuft, helmet, hat, band, antenna, beakHood }
    enum EyeStyle { case round, visor, slit, big }

    static let miko = CharacterSkin(
        id: "miko", displayName: "Miko",
        shirt: Palette.mikoShirt, shirtShade: Palette.mikoShirtShade,
        pants: Palette.mikoPants, pantsShade: Palette.mikoPantsShade,
        skin: Palette.mikoSkin, skinShade: Palette.mikoSkinShade,
        hair: Palette.mikoHair, shoe: Palette.mikoShoe, shoeSole: Palette.mikoShoeSole,
        headGear: .hairTuft, eyeStyle: .round
    )
}
