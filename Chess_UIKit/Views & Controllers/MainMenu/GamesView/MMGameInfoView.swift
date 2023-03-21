//
//  MMGameInfoView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 08.02.2023.
//

import UIKit

// MARK: - MMGameInfoViewDelegate

protocol MMGameInfoViewDelegate: AnyObject {
    func gameInfoViewDidTriggerLoadGame(_ gameInfoView: MMGameInfoView) -> Void
    func gameInfoViewDidTriggerDeleteGame(_ gameInfoView: MMGameInfoView) -> Void
    func gameInfoViewDidToggleAdditionalInfo(_ gameInfoView: MMGameInfoView) -> Void
}

// MARK: - MMGameInfoView

//class that represents view with basic and additional info about game in main menu
class MMGameInfoView: MMButtonView {
    
    // MARK: - Properties
    
    //just to simplify init
    struct Data {
        
        struct PlayerInfo {
            
            let nickname: String
            let points: Int
            let pointsForGame: Int
            
        }
        
        var id = ""
        var startDate = Date()
        var ended = false
        var winnerInfo: PlayerInfo?
        var firstPlayerInfo = PlayerInfo(nickname: "", points: 0, pointsForGame: 0)
        var secondPlayerInfo: PlayerInfo?
        var mode = GameModes.oneScreen
        var rewindEnabled = false
        var timerEnabled = false
        var totalTime = 0
        var additionalTime = 0
        
        //to prevent big inits
        init() {}
        
    }
    
    weak var delegate: MMGameInfoViewDelegate?
    
    private typealias constants = MMGameInfoView_Constants

    private let loadButton = UIButton()
    
    let gameID: String
    
    private var additionalInfo: GameInfoTable!
    
    // MARK: - Inits
    
    init(gameInfo: MMGameInfoView.Data, font: UIFont, currentUserNickname: String) {
        gameID = gameInfo.id
        super.init(backgroundImageItem: nil, buttonImageItem: nil, buttontext: "", action: nil, font: font, needHeightConstraint: true)
        setup(with: gameInfo, and: currentUserNickname)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    //shows/hides additional info about game with animation
    @objc private func toggleAdditionalInfo(_ sender: UIButton? = nil) {
        if let sender {
            let heightConstraint = constraints.first(where: {$0.firstAttribute == .height && $0.secondItem == nil})
            if let heightConstraint {
                NSLayoutConstraint.deactivate([heightConstraint])
                removeConstraint(heightConstraint)
                var heightConstraint: NSLayoutConstraint?
                var newAlpha = 0.0
                let isHidden = additionalInfo.isHidden
                let height = MMButtonView.getOptimalHeight(with: font.pointSize)
                if isHidden {
                    additionalInfo.isHidden = false
                    sender.transform = CGAffineTransform(rotationAngle: .pi)
                    newAlpha = 1
                    heightConstraint = heightAnchor.constraint(equalToConstant: height * constants.sizeMultiplayerForAdditionalInfo)
                }
                else {
                    sender.transform = .identity
                    heightConstraint = heightAnchor.constraint(equalToConstant: height)
                }
                if let heightConstraint {
                    NSLayoutConstraint.activate([heightConstraint])
                    //when we animating for the first time, first cell also shows with animation
                    //this is not bad, but it only works once and later on there is no such animation, which i dont like,
                    //so we perform it without animation
                    if isHidden {
                        additionalInfo.layoutIfNeeded()
                    }
                    UIView.animate(withDuration: constants.animationDuration, animations: { [weak self] in
                        guard let self else { return }
                        self.additionalInfo.alpha = newAlpha
                        self.delegate?.gameInfoViewDidToggleAdditionalInfo(self)
                    }) { [weak self] _ in
                        guard let self else { return }
                        if !isHidden {
                            self.additionalInfo.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    //loads game
    @objc private func loadGame(_ sender: UIButton? = nil) {
        delegate?.gameInfoViewDidTriggerLoadGame(self)
    }
    
    //deletes game
    @objc private func deleteGame(_ sender: UIButton? = nil) {
        delegate?.gameInfoViewDidTriggerDeleteGame(self)
    }
    
    // MARK: - Local Methods

    private func setup(with gameInfo: MMGameInfoView.Data, and currentUserNickname: String) {
        let date = gameInfo.startDate.toStringDateHMS
        let dateLabel = UILabel()
        dateLabel.setup(text: date, alignment: .left, font: font.withSize(font.pointSize / constants.dividerForDateFont))
        let infoLabelScrollView = UIScrollView()
        infoLabelScrollView.translatesAutoresizingMaskIntoConstraints = false
        infoLabelScrollView.delaysContentTouches = false
        let infoLabel = makeInfoLabel(with: gameInfo)
        infoLabelScrollView.addSubview(infoLabel)
        let infoLabelWidth = infoLabel.widthAnchor.constraint(equalTo: infoLabelScrollView.widthAnchor)
        infoLabelWidth.priority = .defaultLow
        var additionalGameInfo = GameInfoTable.Data()
        additionalGameInfo.mode = gameInfo.mode
        additionalGameInfo.rewindEnabled = gameInfo.rewindEnabled
        additionalGameInfo.timerEnabled = gameInfo.timerEnabled
        additionalGameInfo.totalTime = gameInfo.totalTime
        additionalGameInfo.additionalTime = gameInfo.additionalTime
        additionalInfo = GameInfoTable(additionalGameInfo: additionalGameInfo, dataFont: font.withSize(font.pointSize / constants.dividerForFontInAdditionalInfo))
        additionalInfo.isHidden = true
        additionalInfo.alpha = 0
        let helperButtons = makeHelperButtonsView(for: gameInfo.mode, gameEnded: gameInfo.ended)
        if gameInfo.ended {
            if gameInfo.winnerInfo?.nickname == currentUserNickname {
                backgroundColor = constants.gameWinnerColor
            }
            else if gameInfo.winnerInfo != nil {
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
        let helperButtonsConstraints = [helperButtons.topAnchor.constraint(equalTo: additionalInfo.bottomAnchor), helperButtons.bottomAnchor.constraint(equalTo: bottomAnchor), helperButtons.leadingAnchor.constraint(equalTo: leadingAnchor), helperButtons.trailingAnchor.constraint(equalTo: trailingAnchor), helperButtons.heightAnchor.constraint(equalToConstant: font.pointSize)]
        NSLayoutConstraint.activate(dateLabelConstraints + infoLabelScrollViewConstraints + infoLabelConstraints + additionalInfoConstraints + helperButtonsConstraints)
    }
    
    private func makeInfoLabel(with gameInfo: MMGameInfoView.Data) -> UILabel {
        let gameInfoLabel = UILabel()
        let firstPlayerPointsSign = gameInfo.firstPlayerInfo.pointsForGame > 0 ? "+" : ""
        let secondPlayerPointsSign = gameInfo.secondPlayerInfo?.pointsForGame ?? -1 > 0 ? "+" : ""
        var gameInfoText = gameInfo.firstPlayerInfo.nickname + " " + String(gameInfo.firstPlayerInfo.points) + "(" + firstPlayerPointsSign
        gameInfoText += String(gameInfo.firstPlayerInfo.pointsForGame) + ")" + " " + "vs "
        if let secondPlayerInfo = gameInfo.secondPlayerInfo {
            gameInfoText += secondPlayerInfo.nickname + " " + String(secondPlayerInfo.points)
            gameInfoText += "(" + secondPlayerPointsSign + String(secondPlayerInfo.pointsForGame) + ")"
        }
        gameInfoLabel.setup(text: gameInfoText, alignment: .center, font: font)
        return gameInfoLabel
    }
    
    //makes buttons for additional actions
    private func makeHelperButtonsView(for gameMode: GameModes, gameEnded: Bool) -> UIImageView {
        let helperButtonsView = UIImageView()
        helperButtonsView.defaultSettings()
        helperButtonsView.backgroundColor = helperButtonsView.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        helperButtonsView.isUserInteractionEnabled = true
        let helperButtonsStack = UIStackView()
        helperButtonsStack.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.spacingForHelperButtons)
        let deleteButton = UIButton()
        deleteButton.buttonWith(imageItem: SystemImages.deleteImage, and: #selector(deleteGame))
        deleteButton.isEnabled = gameMode == .oneScreen || gameEnded
        let expandButton = UIButton()
        expandButton.buttonWith(imageItem: SystemImages.expandImage, and: #selector(toggleAdditionalInfo))
        loadButton.buttonWith(imageItem: SystemImages.enterImage, and: #selector(loadGame))
        helperButtonsStack.addArrangedSubviews([deleteButton, expandButton, loadButton])
        helperButtonsView.addSubview(helperButtonsStack)
        let helperButtonsStackConstraints = [helperButtonsStack.centerXAnchor.constraint(equalTo: helperButtonsView.centerXAnchor), helperButtonsStack.centerYAnchor.constraint(equalTo: helperButtonsView.centerYAnchor), deleteButton.widthAnchor.constraint(equalTo: deleteButton.heightAnchor), helperButtonsStack.heightAnchor.constraint(equalTo: helperButtonsView.heightAnchor, multiplier: constants.sizeMultiplayerForHelperButtonsStack)]
        NSLayoutConstraint.activate(helperButtonsStackConstraints)
        return helperButtonsView
    }
    
    func makeUnavailable() {
        UIView.animate(withDuration: constants.animationDuration, animations: { [weak self] in
            guard let self else { return }
            self.backgroundColor = constants.gameLoserColor
            self.loadButton.isEnabled = false
        })
    }
    
}

// MARK: - Constants

private struct MMGameInfoView_Constants {
    static let dividerForFontInAdditionalInfo = 2.0
    static let dividerForDateFont = 3.0
    static let animationDuration = 0.5
    static let sizeMultiplayerForAdditionalInfo = 2.0
    static let sizeMultiplayerForHelperButtonsStack = 0.9
    static let spacingForHelperButtons = 15.0
    static let optimalDistance = 10.0
    static let optimalAlpha = 0.5
    static let gameWinnerColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let gameLoserColor = UIColor.red.withAlphaComponent(optimalAlpha)
    static let gameDrawColor = UIColor.yellow.withAlphaComponent(optimalAlpha)
    static let gameNotEndedColor = UIColor.orange.withAlphaComponent(optimalAlpha)
}
