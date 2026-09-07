import UIKit

/// 10 karakterin tam katalogu (docs/CHARACTER_MIKO.md bolum 6).
///
/// Hepsi AYNI iskeleti kullanir; yalnizca renk + kafa aksesuari + goz stili
/// degisir. Bu yuzden 10 karakter icin 10 ayri animasyon seti yoktur.
///
/// Hicbiri mevcut bir markaya veya oyun karakterine benzemez; her biri
/// yalnizca palet ve basit bir siluet aksaniyla ayrisir. (bkz. CharacterCatalog.kt)
enum CharacterCatalog {

    struct Entry {
        let skin: CharacterSkin
        let price: Int
    }

    private static func entry(
        _ id: String, _ name: String,
        _ shirt: String, _ shirtShade: String,
        _ pants: String, _ pantsShade: String,
        _ body: String, _ bodyShade: String,
        _ hair: String, _ shoe: String, _ shoeSole: String,
        _ gear: CharacterSkin.HeadGear, _ eyes: CharacterSkin.EyeStyle, _ price: Int
    ) -> Entry {
        Entry(skin: CharacterSkin(
            id: id, displayName: name,
            shirt: UIColor(hex: shirt), shirtShade: UIColor(hex: shirtShade),
            pants: UIColor(hex: pants), pantsShade: UIColor(hex: pantsShade),
            skin: UIColor(hex: body), skinShade: UIColor(hex: bodyShade),
            hair: UIColor(hex: hair), shoe: UIColor(hex: shoe), shoeSole: UIColor(hex: shoeSole),
            headGear: gear, eyeStyle: eyes
        ), price: price)
    }

    static let all: [Entry] = [
        Entry(skin: .miko, price: 0),
        entry("robot", "Robot",
              "#B8C4CE", "#8E9AA6", "#6E7A86", "#54606C",
              "#D7DEE6", "#AEB8C4", "#3DF0FF", "#54606C", "#3A424C",
              .antenna, .visor, 2500),
        entry("astronaut", "Astronot",
              "#F2F5F8", "#D2D8DE", "#DDE3EA", "#BFC6CE",
              "#FFD9A8", "#F0BE86", "#3A2E2A", "#E8EEF4", "#B8C4CE",
              .helmet, .visor, 4000),
        entry("ninja", "Ninja",
              "#33303C", "#22202A", "#22202A", "#151420",
              "#4A4656", "#38343F", "#E23B4E", "#22202A", "#151420",
              .band, .slit, 3500),
        entry("chef", "Şef",
              "#F7F5F0", "#DCD8D0", "#4A5566", "#38414F",
              "#FFD9A8", "#F0BE86", "#3A2E2A", "#E8E4DC", "#C6C2B8",
              .hat, .round, 3000),
        entry("cowboy", "Kovboy",
              "#C96B3C", "#A34F27", "#5A6E8C", "#42546E",
              "#F0C89A", "#D8AA78", "#6E4A2A", "#8C5A3C", "#6E442C",
              .hat, .round, 3500),
        entry("penguin", "Penguen",
              "#2B2C38", "#1A1B26", "#2B2C38", "#1A1B26",
              "#F7F5F0", "#DCD8D0", "#2B2C38", "#FFA83D", "#DB8420",
              .beakHood, .round, 5000),
        entry("potato", "Patates",
              "#C8A06A", "#A87E4C", "#6BAF5C", "#4E8E42",
              "#D8B584", "#B8945E", "#8C6A3C", "#6BAF5C", "#4E8E42",
              .none, .big, 6000),
        entry("alien", "Uzaylı",
              "#7BD96B", "#57B848", "#4A3F7A", "#372E5C",
              "#A8E896", "#7CC468", "#4A8C3C", "#7A6ECC", "#5C51A4",
              .antenna, .big, 8000),
        entry("businessman", "Komik İş Adamı",
              "#3A4560", "#2A3246", "#2A3246", "#1C2231",
              "#FFD9A8", "#F0BE86", "#3A2E2A", "#2B2438", "#1A1526",
              .none, .round, 12000)
    ]

    private static let byId: [String: Entry] = Dictionary(uniqueKeysWithValues: all.map { ($0.skin.id, $0) })

    static func skin(_ id: String) -> CharacterSkin { byId[id]?.skin ?? .miko }
    static func entry(_ id: String) -> Entry { byId[id] ?? all[0] }
    static func priceOf(_ id: String) -> Int { byId[id]?.price ?? 0 }

    /// Rakip NPC: Miko iskeleti, notr gri palet - oyuncuyla karistirilmasin.
    static let rival = CharacterSkin(
        id: "rival", displayName: "Rakip",
        shirt: UIColor(hex: "#9AA0AC"), shirtShade: UIColor(hex: "#7C828E"),
        pants: UIColor(hex: "#5A606C"), pantsShade: UIColor(hex: "#464C57"),
        skin: UIColor(hex: "#E0D6C8"), skinShade: UIColor(hex: "#C4BAAC"),
        hair: UIColor(hex: "#5A5048"), shoe: UIColor(hex: "#D8D4CE"), shoeSole: UIColor(hex: "#B4B0AA"),
        headGear: .hairTuft, eyeStyle: .round
    )
}
