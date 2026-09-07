import SwiftUI

/// Uygulamanin giris noktasi. Ekran akisi UIKit tarafinda (GameView, Android'deki
/// GameView/SurfaceView'in karsiligi) — SwiftUI burada yalnizca ince bir kabuk.
@main
struct SandalyeyeOturApp: App {
    var body: some Scene {
        WindowGroup {
            GameContainer()
                .ignoresSafeArea()
                .statusBar(hidden: true)
        }
    }
}

/// UIKit `GameViewController`'i SwiftUI agacina baglar.
struct GameContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GameViewController {
        GameViewController()
    }
    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {}
}
