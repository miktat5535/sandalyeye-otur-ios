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
        gameView.screen = Self.initialScreen(services: services)

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

    /// Codemagic'in `simulator-preview` is akisi Mac'imiz olmadigi icin TEK
    /// gorsel dogrulama yontemimiz — o yuzden hangi ekranin acilacagini bir
    /// launch argument'i belirleyebiliyor: normalde SplashScreen, ama CI
    /// betigi `-uiTestGameplay` argumaniyla baslatirsa dogrudan gercek
    /// oynanisa (GameplayScreen) atlar. Boylece CI ekran goruntusunde sadece
    /// menu degil, Miko'nun sandalyeye oturdugu an da gorulebiliyor.
    private static func initialScreen(services: Services) -> Screen {
        if CommandLine.arguments.contains("-uiTestGameplay") {
            return GameplayScreen(services: services, levelNumber: 1)
        }
        // App Store ekran goruntuleri icin: magaza (COIN sekmesi) de gorsel
        // dogrulamaya/pazarlama gorsellerine dahil edilebilsin.
        if CommandLine.arguments.contains("-uiTestShop") {
            return ShopScreen(services: services, tab: .coins)
        }
        return SplashScreen(services: services)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
