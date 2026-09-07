import UIKit

/// Android'deki `GameActivity`'nin karsiligi: tek bir `GameView`'i tam ekran
/// gosteren ince bir kabuk. Oyun mantiginin tamami GameView + Screen katmaninda.
final class GameViewController: UIViewController {

    private var gameView: GameView!
    private let services = Services.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let gameView = GameView(frame: view.bounds)
        gameView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gameView)
        NSLayoutConstraint.activate([
            gameView.topAnchor.constraint(equalTo: view.topAnchor),
            gameView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gameView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        self.gameView = gameView
        gameView.screen = MainMenuScreen(services: services)

        services.onAppLaunched(presenter: self)

        UIApplication.shared.isIdleTimerDisabled = true

        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc private func appDidBecomeActive() {
        services.onAppForeground()
        gameView.resumeLoop()
    }

    @objc private func appWillResignActive() {
        gameView.pauseLoop()
        services.onAppBackground()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
