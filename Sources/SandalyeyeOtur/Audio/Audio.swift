import AVFoundation
import UIKit
import os.log

/// Ses bankasi.
///
/// Kural 40: ses dosyasi YOKSA oyun sessiz calisir, COKMEZ. Sesler PHASE
/// 13'te uretilecek (Android tarafiyla ayni durum); su an dosya yok ve bu
/// tamamen normal — her yukleme hatasi sessizce yutulur. (bkz. Audio.kt)
final class SoundBank {
    enum Sfx: String, CaseIterable {
        case button = "sfx_button"
        case sitSuccess = "sfx_sit_success"
        case sitPerfect = "sfx_sit_perfect"
        case fail = "sfx_fail"
        case coin = "sfx_coin"
        case levelComplete = "sfx_level_complete"
        case combo = "sfx_combo"
        case menu = "sfx_menu"
        case footstep = "sfx_footstep"
        case chairMove = "sfx_chair_move"
        case chairImpact = "sfx_chair_impact"
        case pop = "sfx_pop"
        case whoosh = "sfx_whoosh"
    }

    private let save: SaveRepository
    private var players: [Sfx: AVAudioPlayer] = [:]
    private static let logger = Logger(subsystem: "com.miktat55.sitdown", category: "SoundBank")

    init(save: SaveRepository) {
        self.save = save
        var missing = 0
        for s in Sfx.allCases {
            guard let url = Bundle.main.url(forResource: s.rawValue, withExtension: "caf")
                ?? Bundle.main.url(forResource: s.rawValue, withExtension: "wav")
                ?? Bundle.main.url(forResource: s.rawValue, withExtension: "mp3") else {
                missing += 1
                continue
            }
            if let p = try? AVAudioPlayer(contentsOf: url) {
                p.prepareToPlay()
                players[s] = p
            } else {
                missing += 1
            }
        }
        if missing > 0 {
            Self.logger.info("\(missing) ses dosyasi yok, sessiz devam ediliyor (PHASE 13)")
        }
    }

    func play(_ s: Sfx, volume: Float = 1, pitch: Float = 1) {
        guard save.data.soundEnabled, let p = players[s] else { return }
        p.volume = volume
        p.rate = pitch.clamped(0.5, 2.0)
        p.enableRate = true
        p.currentTime = 0
        p.play()
    }

    func release() { players.removeAll() }
}

/// Arka plan muzigi. Kural 40: dosya yoksa muzik sessizce atlanir.
final class Music {
    private let save: SaveRepository
    private var player: AVAudioPlayer?
    private static let logger = Logger(subsystem: "com.miktat55.sitdown", category: "Music")
    /// Muzik oynanisin onune gecmemeli - efektlerden belirgin sekilde kisik.
    private static let volume: Float = 0.38
    private static let fileBase = "music_main_loop"

    init(save: SaveRepository) { self.save = save }

    func start() {
        guard save.data.musicEnabled else { return }
        if player != nil { resume(); return }
        guard let url = Bundle.main.url(forResource: Self.fileBase, withExtension: "caf")
            ?? Bundle.main.url(forResource: Self.fileBase, withExtension: "mp3") else {
            Self.logger.info("Muzik dosyasi yok, sessiz devam ediliyor")
            return
        }
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        p.numberOfLoops = -1
        p.volume = Self.volume
        p.prepareToPlay()
        p.play()
        player = p
    }

    func pause() { player?.pause() }

    func resume() {
        guard save.data.musicEnabled else { return }
        player?.play()
    }

    /// Ayarlardan acilip kapatildiginda cagrilir.
    func syncWithSettings() {
        if save.data.musicEnabled {
            if player == nil { start() } else { resume() }
        } else {
            pause()
        }
    }

    func release() {
        player?.stop()
        player = nil
    }
}

/// Haptik geri bildirim. Desteklemeyen cihazda (Simulator) sessizce atlanir.
final class Haptics {
    private let save: SaveRepository
    private let notification = UINotificationFeedbackGenerator()
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)

    init(save: SaveRepository) { self.save = save }

    func success() {
        guard save.data.hapticEnabled else { return }
        notification.notificationOccurred(.success)
    }

    func fail() {
        guard save.data.hapticEnabled else { return }
        notification.notificationOccurred(.error)
    }

    func combo() {
        guard save.data.hapticEnabled else { return }
        impactMedium.impactOccurred()
    }

    func tap() {
        guard save.data.hapticEnabled else { return }
        impactLight.impactOccurred()
    }
}
