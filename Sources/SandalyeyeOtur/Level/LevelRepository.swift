import Foundation
import os.log

/// Bolum verisini `Resources/levels/levels.json` dosyasindan okur
/// (bkz. LevelRepository.kt — mantik birebir).
///
/// Kural 40: dosya yoksa veya bozuksa uygulama COKMEZ - elde ne varsa onu
/// kullanir, hicbir sey yoksa FALLBACK bolume duser.
final class LevelRepository {

    private var levels: [LevelSpec] = []
    private(set) var loadError: String?

    var count: Int { levels.count }
    var isLoaded: Bool { !levels.isEmpty }

    private static let logger = Logger(subsystem: "com.miktat55.sitdown", category: "LevelRepository")

    func load() {
        guard levels.isEmpty else { return }
        guard let url = Bundle.main.url(forResource: "levels", withExtension: "json", subdirectory: "levels")
                ?? Bundle.main.url(forResource: "levels", withExtension: "json") else {
            Self.logger.error("levels.json bundle icinde bulunamadi")
            loadError = "levels.json bulunamadi"
            levels = [LevelSpec.fallback]
            return
        }
        do {
            let data = try Data(contentsOf: url)
            levels = try parse(data)
            if levels.isEmpty {
                loadError = "levels.json bos"
                levels = [LevelSpec.fallback]
            }
        } catch {
            Self.logger.error("Bolum verisi okunamadi: \(error.localizedDescription, privacy: .public)")
            loadError = error.localizedDescription
            levels = [LevelSpec.fallback]
        }
    }

    /// 1 tabanli bolum numarasi. Aralik disi istek en yakina kirpilir.
    func level(_ number: Int) -> LevelSpec {
        if levels.isEmpty { load() }
        guard !levels.isEmpty else { return LevelSpec.fallback }
        let idx = min(max(number - 1, 0), levels.count - 1)
        return levels[idx]
    }

    func all() -> [LevelSpec] {
        if levels.isEmpty { load() }
        return levels
    }

    // MARK: - Ayristirma

    private func parse(_ data: Data) throws -> [LevelSpec] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let arr = root["levels"] as? [[String: Any]] else {
            return []
        }
        var out: [LevelSpec] = []
        out.reserveCapacity(arr.count)
        for (i, o) in arr.enumerated() {
            // Tek bir bozuk bolum tum dosyayi cope atmasin.
            if let spec = LevelSpec(json: o, fallbackId: i + 1) {
                out.append(spec)
            } else {
                Self.logger.warning("Bolum \(i) atlandi: gecersiz veri")
            }
        }
        return out
    }
}
