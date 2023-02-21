//
//  MainMenuVC.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.09.2022.
//

import UIKit

//VC that represents main menu view
class MainMenuVC: UIViewController, WSManagerDelegate, MainMenuDelegate {

    // MARK: - MainMenuDelegate
    
    //going back to authorization vc
    func signOut() {
        if presentedViewController != nil {
            dismiss(animated: true) { [weak self] in
                guard let self else { return }
                self.dismiss(animated: true)
            }
        }
        else {
            dismiss(animated: true)
        }
    }
    
    //shows/hides view for redacting user profile
    func toggleUserProfileVC() {
        if (presentedViewController as? UserProfileVC) == nil {
            if let presentedViewController {
                presentedViewController.dismiss(animated: true) { [weak self] in
                    guard let self else { return }
                    self.makeUserProfileVC()
                }
            }
            else {
                makeUserProfileVC()
            }
        }
        else {
            presentedViewController?.dismiss(animated: true)
        }
    }
    
    //shows/hides view for game creation
    func toggleCreateGameVC() {
        if (presentedViewController as? CreateGameVC) == nil {
            if let presentedViewController {
                presentedViewController.dismiss(animated: true) { [weak self] in
                    guard let self else { return }
                    self.makeCreateGameVC()
                }
            }
            else {
                makeCreateGameVC()
            }
        }
        else {
            presentedViewController?.dismiss(animated: true)
        }
    }
    
    //shows game view with chosen game
    func showGameVC(with game: GameLogic) {
        if let presentedViewController {
            presentedViewController.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                self.makeGameVC(with: game)
            }
        }
        else {
            makeGameVC(with: game)
        }
    }
    
    func makeErrorAlert(with message: String) {
        print(message)
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        if let topVC = UIApplication.getTopMostViewController(), topVC as? GameViewController == nil && topVC as? UIAlertController == nil {
            topVC.present(alert, animated: true)
            audioPlayer.playSound(Sounds.errorSound)
        }
    }
    
    // MARK: - WSManagerDelegate
    
    func socketConnected(with headers: [String: String]) {
        wsManager?.writeText(storage.currentUser.email + Date().toStringDateHMS + "MainMenuVC")
    }
    
    func webSocketError(with message: String) {
        makeErrorAlert(with: message)
    }
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioPlayer.musicEnabled = storage.currentUser.musicEnabled
        audioPlayer.soundsEnabled = storage.currentUser.soundsEnabled
        makeUI()
        wsManager?.delegate = self
        wsManager?.connectToWebSocketServer()
        audioPlayer.playSound(Sounds.successSound)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        mainMenuView.animateTransition()
        mainMenuView.updateNotificationIcons()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if presentedViewController as? GameViewController == nil {
            mainMenuView.onRotate()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //if user disconnected from last game, we need to take into account points from that game
        if let lastGame = storage.currentUser.games.last {
            if lastGame.winner == nil && !lastGame.gameEnded && lastGame.gameMode == .multiplayer {
                if lastGame.players.first?.user.points == storage.currentUser.points {
                    lastGame.surrender(for: .player1)
                    storage.currentUser.addPoints(lastGame.players.first!.pointsForGame)
                    makeErrorAlert(with: "You lost last game")
                }
            }
        }
        audioPlayer.playSound(Music.menuBackgroundMusic, volume: constants.volumeForBackgroundMusic)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if UIApplication.getTopMostViewController() as? AuthorizationVC != nil {
            wsManager?.disconnectFromWebSocketServer()
        }
    }
    
    // MARK: - Properties
    
    private typealias constants = MainMenuVC_Constants
    
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    private let wsManager = WSManager.getSharedInstance()
    
    // MARK: - Methods
    
    //makes view for redacting user profile
    private func makeUserProfileVC() {
        let userProfileVC = UserProfileVC()
        configureSheetController(of: userProfileVC)
        present(userProfileVC, animated: true)
        audioPlayer.playSound(Sounds.openPopUpSound)
    }
    
    //makes view for game creation
    private func makeCreateGameVC() {
        let createGameVC = CreateGameVC()
        configureSheetController(of: createGameVC)
        present(createGameVC, animated: true)
        audioPlayer.playSound(Sounds.openPopUpSound)
    }
    
    //makes game view with chosen game
    private func makeGameVC(with game: GameLogic) {
        let gameVC = GameViewController()
        gameVC.gameLogic = game
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }
    
    private func configureSheetController(of viewController: UIViewController) {
        if #available(iOS 15.0, *) {
            if let sheet = viewController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.largestUndimmedDetentIdentifier = .medium
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersEdgeAttachedInCompactHeight = true
                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            }
        }
    }
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private(set) var mainMenuView: MainMenuView!
    
    // MARK: - UI Methods
    
    private func makeUI() {
        let fontSize = min(view.frame.width, view.frame.height) / constants.dividerForFont
        let widthForAvatar = min(view.frame.height, view.frame.width) / constants.sizeMultiplayerForAvatar
        mainMenuView = MainMenuView(widthForAvatar: widthForAvatar, fontSize: fontSize)
        mainMenuView.mainMenuDelegate = self
        view.addSubview(mainMenuView)
        let mainMenuViewConstraints = [mainMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor), mainMenuView.trailingAnchor.constraint(equalTo: view.trailingAnchor), mainMenuView.topAnchor.constraint(equalTo: view.topAnchor), mainMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        NSLayoutConstraint.activate(mainMenuViewConstraints)
    }
    
}

// MARK: - Constants

private struct MainMenuVC_Constants {
    static let dividerForFont: CGFloat = 13
    static let sizeMultiplayerForAvatar = 5.0
    static let volumeForBackgroundMusic: Float = 0.5
}
