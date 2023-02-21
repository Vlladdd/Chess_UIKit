//
//  GameView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 08.02.2023.
//

import UIKit

//class that represents view with basic and additional info about game
class GameView: MMButtonView {
    
    // MARK: - Properties
    
    weak var mainMenuViewDelegate: MainMenuViewDelegate?
    weak var mpGamesDelegate: MPGamesDelegate?
    
    private typealias constants = GameView_Constants
    
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    private let wsManager = WSManager.getSharedInstance()
    
    let game: GameLogic
    
    private var additionalInfo: GameInfoTable!
    
    // MARK: - Inits
    
    init(game: GameLogic, mainMenuViewDelegate: MainMenuViewDelegate) {
        self.mainMenuViewDelegate = mainMenuViewDelegate
        self.game = game
        super.init(backgroundImageItem: nil, buttonImageItem: nil, buttontext: "", action: nil, fontSize: mainMenuViewDelegate.font.pointSize, needHeightConstraint: true)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    //shows/hides additional info about game with animation
    @objc private func toggleGameInfo(_ sender: UIButton? = nil) {
        if let sender, let mainMenuViewDelegate {
            let heightConstraint = constraints.first(where: {$0.firstAttribute == .height && $0.secondItem == nil})
            if let heightConstraint {
                NSLayoutConstraint.deactivate([heightConstraint])
                removeConstraint(heightConstraint)
                var heightConstraint: NSLayoutConstraint?
                var newAlpha = 0.0
                let isHidden = additionalInfo.isHidden
                let height = MMButtonView.getOptimalHeight(with: mainMenuViewDelegate.font.pointSize)
                if isHidden {
                    additionalInfo.isHidden = false
                    sender.transform = CGAffineTransform(rotationAngle: .pi)
                    newAlpha = 1
                    heightConstraint = heightAnchor.constraint(equalToConstant: height * constants.sizeMultiplayerForGameInfo)
                }
                else {
                    sender.transform = .identity
                    heightConstraint = heightAnchor.constraint(equalToConstant: height)
                }
                if let heightConstraint {
                    UIView.animate(withDuration: constants.animationDuration, animations: { [weak self] in
                        guard let self else { return }
                        self.additionalInfo.alpha = newAlpha
                        NSLayoutConstraint.activate([heightConstraint])
                        //when we animating first time, first cell also shows with animation
                        //this is not bad, but it only work once and later on there is no such animation, which i dont like,
                        //so i just removed it like this
                        if isHidden {
                            UIView.performWithoutAnimation {
                                self.additionalInfo.layoutIfNeeded()
                            }
                        }
                        mainMenuViewDelegate.mainMenuDelegate?.view.layoutIfNeeded()
                    }) { [weak self] _ in
                        guard let self else { return }
                        if !isHidden {
                            self.additionalInfo.isHidden = true
                        }
                    }
                    audioPlayer.playSound(Sounds.moveSound2)
                }
            }
        }
    }
    
    //loads game
    @objc private func loadGame(_ sender: UIButton? = nil) {
        if let mainMenuViewDelegate {
            if game.gameMode == .multiplayer && !game.gameEnded {
                //if gameMode == .multiplayer, there is no way for wsManager to be nil
                if wsManager!.connectedToWSServer && mainMenuViewDelegate.mainMenuDelegate?.presentedViewController == nil {
                    game.addSecondPlayer(user: storage.currentUser)
                    wsManager?.writeObject(game)
                    //opponent on top
                    game.switchPlayers()
                    //we are saving game at the start for the case, where game will not be ended and
                    //to be able to take into account points from that game
                    //for example, if player will disconnect
                    storage.addGameToCurrentUserAndSave(game)
                }
                else if !wsManager!.connectedToWSServer {
                    mainMenuViewDelegate.mainMenuDelegate?.makeErrorAlert(with: "You are not connected to the server, will try to reconnect")
                    wsManager?.connectToWebSocketServer()
                    return
                }
                else {
                    mainMenuViewDelegate.mainMenuDelegate?.makeErrorAlert(with: "Close the pop-up window")
                    return
                }
                mainMenuViewDelegate.makeMenu(with: MMGameButtons(delegate: mainMenuViewDelegate), reversed: true)
            }
            audioPlayer.pauseSound(Music.menuBackgroundMusic)
            audioPlayer.playSound(Sounds.successSound)
            mainMenuViewDelegate.mainMenuDelegate?.showGameVC(with: game)
            mpGamesDelegate?.searchingForMPgames?.cancel()
        }
    }
    
    //deletes game
    @objc private func deleteGame(_ sender: UIButton? = nil) {
        let alert = UIAlertController(title: "Delete game", message: "Are you sure?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.storage.currentUser.removeGame(self.game)
            UIView.animate(withDuration: constants.animationDuration, animations: {
                self.isHidden = true
            }) { _ in
                self.removeFromSuperview()
            }
            self.audioPlayer.playSound(Sounds.removeSound)
        }))
        mainMenuViewDelegate?.mainMenuDelegate?.present(alert, animated: true)
        audioPlayer.playSound(Sounds.openPopUpSound)
    }
    
    // MARK: - Local Methods

    private func setup() {
        if let mainMenuViewDelegate {
            let date = game.startDate.toStringDateHMS
            let dateLabel = UILabel()
            let font = mainMenuViewDelegate.font
            dateLabel.setup(text: date, alignment: .left, font: font.withSize(font.pointSize / constants.dividerForDateFont))
            let infoLabelScrollView = UIScrollView()
            infoLabelScrollView.translatesAutoresizingMaskIntoConstraints = false
            infoLabelScrollView.delaysContentTouches = false
            let infoLabel = makeInfoLabel()
            infoLabelScrollView.addSubview(infoLabel)
            let infoLabelWidth = infoLabel.widthAnchor.constraint(equalTo: infoLabelScrollView.widthAnchor)
            infoLabelWidth.priority = .defaultLow
            additionalInfo = GameInfoTable(gameData: game, dataFont: font.withSize(font.pointSize / constants.dividerForFontInAdditionalInfo))
            additionalInfo.isHidden = true
            additionalInfo.alpha = 0
            let helperButtons = makeHelperButtonsView()
            if game.gameEnded {
                if game.winner?.user.nickname == storage.currentUser.nickname {
                    backgroundColor = constants.gameWinnerColor
                }
                else if game.winner != nil {
                    backgroundColor = constants.gameLoserColor
                }
                else {
                    backgroundColor = constants.gameDrawColor
                }
            }
            else {
                backgroundColor = constants.gameNotEndedColor
            }
            addSubviews([dateLabel, infoLabelScrollView, additionalInfo, helperButtons])
            let dateLabelConstraints = [dateLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: constants.optimalDistance), dateLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor)]
            let infoLabelScrollViewConstraints = [infoLabelScrollView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor), infoLabelScrollView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor), infoLabelScrollView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor)]
            let infoLabelConstraints = [infoLabel.topAnchor.constraint(equalTo: infoLabelScrollView.topAnchor), infoLabel.bottomAnchor.constraint(equalTo: infoLabelScrollView.bottomAnchor), infoLabel.leadingAnchor.constraint(equalTo: infoLabelScrollView.leadingAnchor), infoLabel.trailingAnchor.constraint(equalTo: infoLabelScrollView.trailingAnchor), infoLabel.heightAnchor.constraint(equalTo: infoLabelScrollView.heightAnchor), infoLabelWidth]
            let additionalInfoConstraints = [additionalInfo.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor), additionalInfo.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor), additionalInfo.topAnchor.constraint(equalTo: infoLabel.bottomAnchor)]
            let helperButtonsConstraints = [helperButtons.topAnchor.constraint(equalTo: additionalInfo.bottomAnchor), helperButtons.bottomAnchor.constraint(equalTo: bottomAnchor), helperButtons.leadingAnchor.constraint(equalTo: leadingAnchor), helperButtons.trailingAnchor.constraint(equalTo: trailingAnchor), helperButtons.heightAnchor.constraint(equalToConstant: mainMenuViewDelegate.font.pointSize)]
            NSLayoutConstraint.activate(dateLabelConstraints + infoLabelScrollViewConstraints + infoLabelConstraints + additionalInfoConstraints + helperButtonsConstraints)
        }
    }
    
    private func makeInfoLabel() -> UILabel {
        if let mainMenuViewDelegate {
            let gameInfoLabel = UILabel()
            let firstPlayerPointsSign = game.players.first?.pointsForGame ?? -1 > 0 ? "+" : ""
            let secondPlayerPointsSign = game.players.second?.pointsForGame ?? -1 > 0 ? "+" : ""
            var gameInfoText = game.players.first!.user.nickname + " " + String(game.players.first!.user.points) + "(" + firstPlayerPointsSign
            gameInfoText += String(game.players.first!.pointsForGame) + ")" + " " + "vs "
            if let secondPlayer = game.players.second {
                gameInfoText += secondPlayer.user.nickname + " " + String(secondPlayer.user.points)
                gameInfoText += "(" + secondPlayerPointsSign + String(secondPlayer.pointsForGame) + ")"
            }
            gameInfoLabel.setup(text: gameInfoText, alignment: .center, font: mainMenuViewDelegate.font)
            return gameInfoLabel
        }
        else {
            fatalError("mainMenuViewDelegate is nil")
        }
    }
    
    //makes buttons for additional actions
    private func makeHelperButtonsView() -> UIImageView {
        let helperButtonsView = UIImageView()
        helperButtonsView.defaultSettings()
        helperButtonsView.backgroundColor = helperButtonsView.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        helperButtonsView.isUserInteractionEnabled = true
        let helperButtonsStack = UIStackView()
        helperButtonsStack.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.spacingForHelperButtons)
        let deleteButton = UIButton()
        deleteButton.buttonWith(imageItem: SystemImages.deleteImage, and: #selector(deleteGame))
        deleteButton.isEnabled = game.gameMode == .oneScreen || game.gameEnded
        let expandButton = UIButton()
        expandButton.buttonWith(imageItem: SystemImages.expandImage, and: #selector(toggleGameInfo))
        let loadButton = UIButton()
        loadButton.buttonWith(imageItem: SystemImages.enterImage, and: #selector(loadGame))
        helperButtonsStack.addArrangedSubviews([deleteButton, expandButton, loadButton])
        helperButtonsView.addSubview(helperButtonsStack)
        let helperButtonsStackConstraints = [helperButtonsStack.centerXAnchor.constraint(equalTo: helperButtonsView.centerXAnchor), helperButtonsStack.centerYAnchor.constraint(equalTo: helperButtonsView.centerYAnchor), deleteButton.widthAnchor.constraint(equalTo: deleteButton.heightAnchor), helperButtonsStack.heightAnchor.constraint(equalTo: helperButtonsView.heightAnchor, multiplier: constants.sizeMultiplayerForHelperButtonsStack)]
        NSLayoutConstraint.activate(helperButtonsStackConstraints)
        return helperButtonsView
    }
    
}

// MARK: - Constants

private struct GameView_Constants {
    static let dividerForFontInAdditionalInfo = 2.0
    static let dividerForDateFont = 3.0
    static let animationDuration = 0.5
    static let sizeMultiplayerForGameInfo = 2.0
    static let sizeMultiplayerForHelperButtonsStack = 0.9
    static let spacingForHelperButtons = 15.0
    static let optimalDistance = 10.0
    static let optimalAlpha = 0.5
    static let gameWinnerColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let gameLoserColor = UIColor.red.withAlphaComponent(optimalAlpha)
    static let gameDrawColor = UIColor.yellow.withAlphaComponent(optimalAlpha)
    static let gameNotEndedColor = UIColor.orange.withAlphaComponent(optimalAlpha)
}
