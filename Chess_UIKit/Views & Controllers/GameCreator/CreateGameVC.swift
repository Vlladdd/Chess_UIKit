//
//  CreateGameVC.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 15.09.2022.
//

import UIKit

//VC that represents view to create game
class CreateGameVC: UIViewController, CreateGameDelegate {
    
    // MARK: - CreateGameDelegate
    
    func lostInternet() {
        makeErrorAlert(with: "Lost internet connection")
    }
    
    func socketConnected(with headers: [String: String]) {
        wsManager?.writeText(storage.currentUser.email + Date().toStringDateHMS + "CreateGameVC")
    }
    
    func socketReceivedData(_ data: Data) {
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
    
    func webSocketError(with message: String) {
        makeErrorAlert(with: message)
    }
    
    func createGame() {
        let modePicker = createGameView.gameInfoView.modePicker
        let colorPicker = createGameView.gameInfoView.colorPicker
        if let modePicker, let colorPicker, modePicker.pickedData != nil && colorPicker.pickedData != nil {
            var totalTime = 0
            var additionalTime = 0
            if createGameView.gameInfoView.timerSwitch.isOn {
                totalTime = createGameView.gameInfoView.getTotalTime()
                additionalTime = createGameView.gameInfoView.getAdditionalTime()
            }
            switch modePicker.pickedData! {
            case .oneScreen:
                wsManager?.deactivatePingTimer()
                audioPlayer.pauseSound(Music.menuBackgroundMusic)
                audioPlayer.playSound(Sounds.successSound)
                let rewindEnabled = (createGameView.gameInfoView.rewindLine.data as? UISwitch)?.isOn ?? false
                let secondUser = User(email: "", nickname: constants.defaultNicknameForSecondPlayer)
                let gameLogic = GameLogic(firstUser: storage.currentUser, secondUser: secondUser, gameMode: .oneScreen, firstPlayerColor: colorPicker.pickedData!, rewindEnabled: rewindEnabled, totalTime: totalTime, additionalTime: additionalTime)
                let gameVC = GameViewController()
                gameVC.gameLogic = gameLogic
                gameVC.modalPresentationStyle = .fullScreen
                dismiss(animated: true) {
                    UIApplication.getTopMostViewController()?.present(gameVC, animated: true)
                }
            case .multiplayer:
                if wsManager!.connectedToWSServer {
                    if let gameID {
                        storage.deleteMultiplayerGame(with: gameID)
                    }
                    createGameView.toolbar.createGameButton.isEnabled = false
                    createGameView.gameInfoView.isHidden.toggle()
                    createGameView.makeLoadingSpinner()
                    let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? ""
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
                    makeErrorAlert(with: "You are not connected to the server, will try to reconnect")
                    wsManager?.connectToWebSocketServer()
                }
            }
        }
        else {
            makeErrorAlert(with: "Pick data for all fields!")
        }
    }
    
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
        createGameView.toolbar.createGameButton.isEnabled = true
        createGameView.gameInfoView.isHidden = false
        createGameView.removeLoadingSpinner()
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        UIApplication.getTopMostViewController()?.present(alert, animated: true)
        audioPlayer.playSound(Sounds.errorSound)
        if let gameID {
            storage.deleteMultiplayerGame(with: gameID)
        }
    }
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private var createGameView: CreateGameView!
    
    // MARK: - UI Methods
    
    private func makeUI() {
        createGameView = CreateGameView(fontSize: min(view.frame.width, view.frame.height) / constants.dividerForFont)
        createGameView.toolbar.createGameDelegate = self
        view.addSubview(createGameView)
        let createGameViewConstraints = [createGameView.leadingAnchor.constraint(equalTo: view.leadingAnchor), createGameView.trailingAnchor.constraint(equalTo: view.trailingAnchor), createGameView.topAnchor.constraint(equalTo: view.topAnchor), createGameView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        NSLayoutConstraint.activate(createGameViewConstraints)
    }
    
    
}

// MARK: - Constants

private struct CreateGameVC_Constants {
    static let dividerForFont: CGFloat = 13
    static let defaultNicknameForSecondPlayer = "Player2"
}
