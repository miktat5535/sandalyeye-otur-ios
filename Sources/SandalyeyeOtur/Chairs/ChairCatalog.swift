import UIKit

/// 20 sandalyenin tam katalogu (docs/CHAIRS_SPEC.md bolum 5).
///
/// Hicbiri yeni cizim kodu gerektirmez - hepsi ayni [ChairArtist]'in
/// parametreleridir. Yeni sandalye = buraya bir satir. (bkz. ChairCatalog.kt)
enum ChairCatalog {

    struct Entry {
        let style: ChairStyle
        let price: Int
    }

    private static func style(
        _ id: String, _ name: String, _ seat: String, _ seatShade: String,
        _ frame: String, _ frameShade: String,
        back: ChairStyle.BackType = .rounded, legs: ChairStyle.LegType = .four,
        size: CGFloat = 1, glossy: Bool = false, price: Int = 0
    ) -> Entry {
        Entry(style: ChairStyle(
            id: id, displayName: name,
            seat: UIColor(hex: seat), seatShade: UIColor(hex: seatShade),
            frame: UIColor(hex: frame), frameShade: UIColor(hex: frameShade),
            back: back, legs: legs, sizeScale: size, glossy: glossy
        ), price: price)
    }

    static let all: [Entry] = [
        style("chair_plastic", "Plastik Sandalye", "#5AC8FA", "#3AA8DC", "#5AC8FA", "#3AA8DC",
              back: .rounded, legs: .four, price: 0),
        style("chair_wood", "Ahşap Sandalye", "#C98A4B", "#A96E36", "#C98A4B", "#A96E36",
              back: .slats, legs: .four, price: 800),
        style("chair_office", "Ofis Koltuğu", "#2B2438", "#1A1526", "#B8C4CE", "#8E9AA6",
              back: .high, legs: .wheels, price: 1200),
        style("chair_gaming", "Oyuncu Koltuğu", "#E23B4E", "#B72A3B", "#2B2438", "#1A1526",
              back: .winged, legs: .wheels, size: 1.05, price: 2000),
        style("chair_throne", "Taht", "#7B3FA0", "#5E2C7C", "#FFC53D", "#E5A013",
              back: .high, legs: .sled, size: 1.25, glossy: true, price: 4000),
        style("chair_picnic", "Piknik Sandalyesi", "#4CD98A", "#33B76B", "#E8E4DC", "#C6C2B8",
              back: .rounded, legs: .xFold, size: 0.95, price: 900),
        style("chair_folding", "Katlanır Sandalye", "#9AA7B4", "#78848F", "#B8C4CE", "#8E9AA6",
              back: .slats, legs: .xFold, size: 0.95, price: 900),
        style("chair_barstool", "Bar Taburesi", "#8C5A3C", "#6E442C", "#B8C4CE", "#8E9AA6",
              back: .none, legs: .pedestal, size: 1.15, price: 1500),
        style("chair_gold", "Altın Sandalye", "#FFC53D", "#E5A013", "#FFD98A", "#D9A32E",
              back: .rounded, legs: .four, glossy: true, price: 6000),
        style("chair_silver", "Gümüş Sandalye", "#D7DEE6", "#AEB8C4", "#E8EEF4", "#B8C4CE",
              back: .rounded, legs: .four, glossy: true, price: 3500),
        style("chair_neon", "Neon Sandalye", "#FF3DD1", "#C42AA0", "#3DF0FF", "#22B8CC",
              back: .rounded, legs: .four, glossy: true, price: 5000),
        style("chair_ice", "Buz Sandalyesi", "#A8E8FF", "#78C8E8", "#D8F4FF", "#A0D8F0",
              back: .rounded, legs: .four, glossy: true, price: 4500),
        style("chair_balloon", "Balon Sandalye", "#FF6BA8", "#DB4A85", "#FF9CC4", "#E06B9E",
              back: .rounded, legs: .four, size: 1.10, glossy: true, price: 3000),
        style("chair_cardboard", "Karton Sandalye", "#C8A87C", "#A8875C", "#B89868", "#98784C",
              back: .slats, legs: .four, price: 700),
        style("chair_giant", "Dev Sandalye", "#6BAF5C", "#4E8E42", "#6BAF5C", "#4E8E42",
              back: .rounded, legs: .four, size: 1.60, price: 2500),
        style("chair_mini", "Mini Sandalye", "#FFA83D", "#DB8420", "#FFA83D", "#DB8420",
              back: .rounded, legs: .four, size: 0.55, price: 2500),
        style("chair_roller", "Tekerlekli Sandalye", "#3D6BE2", "#2A4EB7", "#B8C4CE", "#8E9AA6",
              back: .high, legs: .wheels, price: 2200),
        style("chair_rocket", "Roket Sandalye", "#E24B2A", "#B7361A", "#D7DEE6", "#AEB8C4",
              back: .high, legs: .sled, size: 1.05, glossy: true, price: 7000),
        style("chair_stool", "Komik Tabure", "#FF7A3D", "#E25F26", "#FF7A3D", "#E25F26",
              back: .none, legs: .four, size: 0.80, price: 600),
        style("chair_premium", "Özel Sandalye", "#1FD6C0", "#14A896", "#FFC53D", "#E5A013",
              back: .winged, legs: .pedestal, size: 1.10, glossy: true, price: 12000)
    ]

    private static let byId: [String: Entry] = Dictionary(uniqueKeysWithValues: all.map { ($0.style.id, $0) })

    /// Bilinmeyen kimlik gelirse plastik sandalyeye duser - COKMEZ.
    static func style(_ id: String) -> ChairStyle { byId[id]?.style ?? all[0].style }
    static func entry(_ id: String) -> Entry { byId[id] ?? all[0] }
    static func priceOf(_ id: String) -> Int { byId[id]?.price ?? 0 }
}
