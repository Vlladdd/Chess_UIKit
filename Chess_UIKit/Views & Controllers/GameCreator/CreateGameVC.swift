//
//  CreateGameVC.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 15.09.2022.
//

import UIKit

//VC that represents view to create game
class CreateGameVC: UIViewController {
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        wsManager?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayer.playSound(Sounds.closePopUpSound)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioPlayer.pauseSound(Music.waitingMusic)
        wsManager?.stopReconnecting()
        if let gameID {
            storage.deleteMultiplayerGame(with: gameID)
        }
        if let mainMenuVC = UIApplication.getTopMostViewController() as? MainMenuVC {
            wsManager?.delegate = mainMenuVC
        }
    }
    
    // MARK: - Properties
    
    private typealias constants = CreateGameVC_Constants
    
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    private let wsManager = WSManager.getSharedInstance()
    
    //useful for multiplayer game
    private var gameID: String? = nil

    // MARK: - Methods

    private func makeErrorAlert(with message: String) {
        toggleSpinner(show: false)
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        UIApplication.getTopMostViewController()?.present(alert, animated: true)
        audioPlayer.playSound(Sounds.errorSound)
        if let gameID {
            storage.deleteMultiplayerGame(with: gameID)
        }
    }
    
    private func toggleSpinner(show: Bool) {
        createGameView.toolbar.createGameButton.isEnabled = !show
        createGameView.gameInfoView.isHidden = show
        if show {
            createGameView.makeLoadingSpinner()
            createGameView.loadingSpinner?.delegate = self
            audioPlayer.playSound(Music.waitingMusic, volume: constants.volumeForWaitingMusic)
        }
        else {
            createGameView.removeLoadingSpinner()
        }
    }
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private lazy var fontSize = min(view.frame.width, view.frame.height) / constants.dividerForFont
    private lazy var font = UIFont.systemFont(ofSize: fontSize)
    
    private var createGameView: CreateGameView!
    private var reconnectAlert: CustomAlert?
    
    // MARK: - UI Methods
    
    private func makeUI() {
        createGameView = CreateGameView(font: font, isGuestMode: storage.currentUser.guestMode)
        createGameView.toolbar.cgToolbarDelegate = self
        createGameView.gameInfoView.gameInfoViewDelegate = self
        view.addSubview(createGameView)
        let createGameViewConstraints = [createGameView.leadingAnchor.constraint(equalTo: view.leadingAnchor), createGameView.trailingAnchor.constraint(equalTo: view.trailingAnchor), createGameView.topAnchor.constraint(equalTo: view.topAnchor), createGameView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        NSLayoutConstraint.activate(createGameViewConstraints)
    }
    
    
}

// MARK: - Constants

private struct CreateGameVC_Constants {
    static let animationDuration = 0.5
    static let optimalDistance = 10.0
    static let volumeForWaitingMusic: Float = 0.3
    static let dividerForFont: CGFloat = 13
    static let defaultNicknameForSecondPlayer = "Player2"
}

// MARK: - WSManagerDelegate

extension CreateGameVC: WSManagerDelegate {
    
    func managerDidLostInternetConnection(_ manager: WSManager) {
        makeErrorAlert(with: "Lost internet connection")
    }
    
    func managerDidConnectSocket(_ manager: WSManager, with headers: [String: String]) {
        wsManager?.writeText(storage.currentUser.email + Date().toStringDateHMS + "CreateGameVC")
        reconnectAlert?.removeWithAnimation()
    }
    
    func managerDidReceive(_ manager: WSManager, data: Data) {
        if let game = try? JSONDecoder().decode(GameLogic.self, from: data), game.gameID == gameID {
            audioPlayer.pauseSound(Music.menuBackgroundMusic)
            audioPlayer.playSound(Sounds.successSound)
            //we are saving game at the start for the case, where game will not be ended and
            //to be able to take into account points from that game
            //for example, if player will disconnect
            storage.addGameToCurrentUserAndSave(game)
            let gameVC = GameViewController()
            gameVC.gameLogic = game
            gameVC.modalPresentationStyle = .fullScreen
            dismiss(animated: true) {
                UIApplication.getTopMostViewController()?.present(gameVC, animated: true)
            }
        }
    }
    
    func managerDidEncounterError(_ manager: WSManager, with message: String) {
        makeErrorAlert(with: message)
    }
    
}

// MARK: - CGToolbarDelegate

extension CreateGameVC: CGToolbarDelegate {
    
    func toolbarDidTriggerCloseAction(_ cgToolbar: CGToolbar) {
        dismiss(animated: true)
    }
    
    func toolbarDidTriggerCreateGameAction(_ cgToolbar: CGToolbar) {
        let modePicker = createGameView.gameInfoView.modePicker
        let colorPicker = createGameView.gameInfoView.colorPicker
        if let modePicker, let colorPicker, modePicker.pickedData != nil && colorPicker.pickedData != nil {
            var totalTime = 0
            var additionalTime = 0
            if createGameView.gameInfoView.timerSwitch.isOn {
                totalTime = createGameView.gameInfoView.getTotalTime()
                additionalTime = createGameView.gameInfoView.getAdditionalTime()
            }
            let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? ""
            switch modePicker.pickedData! {
            case .oneScreen:
                wsManager?.deactivatePingTimer()
                audioPlayer.pauseSound(Music.menuBackgroundMusic)
                audioPlayer.playSound(Sounds.successSound)
                let rewindEnabled = (createGameView.gameInfoView.rewindLine.data as? UISwitch)?.isOn ?? false
                let secondUser = User(email: "", nickname: constants.defaultNicknameForSecondPlayer)
                let gameLogic = GameLogic(firstUser: storage.currentUser, secondUser: secondUser, gameMode: .oneScreen, firstPlayerColor: colorPicker.pickedData!, rewindEnabled: rewindEnabled, totalTime: totalTime, additionalTime: additionalTime, gameID: deviceID + Date().toStringDateHMS)
                let gameVC = GameViewController()
                gameVC.gameLogic = gameLogic
                gameVC.modalPresentationStyle = .fullScreen
                dismiss(animated: true) {
                    UIApplication.getTopMostViewController()?.present(gameVC, animated: true)
                }
            case .multiplayer:
                if wsManager!.connectedToWSServer {
                    toggleSpinner(show: true)
                    if let gameID {
                        storage.deleteMultiplayerGame(with: gameID)
                    }
                    //we are using device uuid as gameID
                    //this way gameID will always be unique, cuz user can`t create multiple games from one device
                    //in some cases gameID is not enough to identify game
                    //for example, if user will disconect by force exiting app and then connect again
                    //and create new game. In this case, opponent won`t know, that game was ended and
                    //gameId of both of this games will be equal, cuz gameId == device uuid of game creator, so we adding date to it,
                    //cuz obv it is not possible to create 2 games with same date on same device
                    let gameLogic = GameLogic(firstUser: storage.currentUser, secondUser: nil, gameMode: .multiplayer, firstPlayerColor: colorPicker.pickedData!, totalTime: totalTime, additionalTime: additionalTime, gameID: deviceID + Date().toStringDateHMS)
                    storage.saveGameForMultiplayer(gameLogic)
                    gameID = gameLogic.gameID
                }
                else {
                    makeReconnectAlert(with: "Error", and: "You are not connected to the server, reconnecting...")
                    wsManager?.connectToWebSocketServer()
                }
            }
        }
        else {
            makeErrorAlert(with: "Pick data for all fields!")
        }
    }
    
    private func makeReconnectAlert(with title: String, and message: String) {
        let alertData = CustomAlert.Data(type: .error, title: title, message: message, closeButtonText: "Cancel")
        reconnectAlert = CustomAlert(font: font, data: alertData, needLoadingSpinner: true)
        if let reconnectAlert {
            reconnectAlert.delegate = self
            reconnectAlert.loadingSpinner?.delegate = self
            audioPlayer.playSound(Music.waitingMusic, volume: constants.volumeForWaitingMusic)
            createGameView.applyBlurEffect(withAnimation: true, duration: constants.animationDuration)
            reconnectAlert.alpha = 0
            view.addSubview(reconnectAlert)
            let reconnectAlertConstraints = [reconnectAlert.centerXAnchor.constraint(equalTo: view.centerXAnchor), reconnectAlert.centerYAnchor.constraint(equalTo: view.centerYAnchor), reconnectAlert.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: constants.optimalDistance), reconnectAlert.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -constants.optimalDistance)]
            NSLayoutConstraint.activate(reconnectAlertConstraints)
            UIView.animate(withDuration: constants.animationDuration, animations: {
                reconnectAlert.alpha = 1
            })
            audioPlayer.playSound(Sounds.errorSound)
            wsManager?.startReconnecting()
        }
    }
    
}

// MARK: - GameInfoViewDelegate

extension CreateGameVC: GameInfoViewDelegate {
    
    func gameInfoViewDidToggleSwitchOrStepper(_ gameInfoView: GameInfoView) {
        audioPlayer.playSound(Sounds.toggleSound)
    }
    
    func gameInfoViewDidToggleViews(_ gameInfoView: GameInfoView) {
        audioPlayer.playSound(Sounds.moveSound2)
    }
    
}

// MARK: - LoadingSpinnerDelegate

extension CreateGameVC: LoadingSpinnerDelegate {
    
    func loadingSpinnerDidRemoveFromSuperview(_ loadingSpinner: LoadingSpinner) {
        audioPlayer.pauseSound(Music.waitingMusic)
    }
    
}

// MARK: - CustomAlertDelegate

extension CreateGameVC: CustomAlertDelegate {
    
    func customAlertWillRemoveFromSuperview(_ customAlert: CustomAlert) {
        if customAlert == reconnectAlert {
            stopReconnecting()
        }
    }
    
    func customAlertDidRemoveFromSuperview(_ customAlert: CustomAlert) {
        if customAlert == reconnectAlert {
            stopReconnecting()
        }
    }
    
    private func stopReconnecting() {
        reconnectAlert = nil
        createGameView.removeBlurEffects(withAnimation: true, duration: constants.animationDuration)
        wsManager?.stopReconnecting()
    }
    
}
