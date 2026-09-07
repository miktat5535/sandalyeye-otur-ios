import UIKit

/// Android'deki `GameActivity`'nin karsiligi: tek bir `GameView`'i tam ekran
/// gosteren ince bir kabuk. Oyun mantiginin tamami GameView + Screen katmaninda.
final class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let gameView = GameView(frame: view.bounds)
        gameView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gameView)
        NSLayoutConstraint.activate([
            gameView.topAnchor.constraint(equalTo: view.topAnchor),
            gameView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gameView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
