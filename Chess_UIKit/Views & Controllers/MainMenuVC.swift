//
//  MainMenuVC.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.09.2022.
//

import UIKit

//VC that represents main menu view
class MainMenuVC: UIViewController {
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for subview in buttonsStack.arrangedSubviews {
            randomAnimationFor(view: subview)
        }
        if let backButton = view.subviews.first(where: {$0 == backButton}) {
            randomAnimationFor(view: backButton)
        }
    }
    
    // MARK: - Properties
    
    private typealias constants = MainMenuVC_Constants
    
    private let storage = Storage()
    
    var currentUser: User!
    
    // MARK: - Buttons Methods
    
    @objc private func makeGameMenu(_ sender: UIButton? = nil) {
        buttonsStack = UIStackView()
        buttonsStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        buttonsStack.addArrangedSubview(makeMainMenuButtonView(with: UIImage(named: "misc/createButtonBG"), text: "Create", and: #selector(makeCreateGameVC)))
        buttonsStack.addArrangedSubview(makeMainMenuButtonView(with: UIImage(named: "misc/joinButtonBG"), text: "Join", and: #selector(makeMultiplayerGamesList)))
        buttonsStack.addArrangedSubview(makeMainMenuButtonView(with: UIImage(named: "misc/loadButtonBG"), text: "Load", and: #selector(makeUserGamesList)))
        buttonsStack.addArrangedSubview(makeMainMenuButtonView(with: UIImage(systemName: "arrow.left"), text: "Back", and: #selector(makeMainMenu)))
        animateButtonsStack()
    }
    
    //TODO: -
    
    @objc private func makeInventoryMenu(_ sender: UIButton? = nil) {
        
    }
    
    @objc private func makeShopMenu(_ sender: UIButton? = nil) {
        
    }
    
    //
    
    @objc private func makeMainMenu(_ sender: UIButton? = nil) {
        buttonsStack = UIStackView()
        buttonsStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        buttonsStack.addArrangedSubview(makeMainMenuButtonView(with: UIImage(named: "misc/gameButtonBG"), text: "Game", and: #selector(makeGameMenu)))
        buttonsStack.addArrangedSubview(makeMainMenuButtonView(with: UIImage(named: "misc/inventoryButtonBG"), text: "Inventory", and: #selector(makeInventoryMenu)))
        buttonsStack.addArrangedSubview(makeMainMenuButtonView(with: UIImage(named: "misc/shopButtonBG"), text: "Shop", and: #selector(makeShopMenu)))
        animateButtonsStack(reversed: true)
    }
    
    //makes view for game creation
    @objc private func makeCreateGameVC(_ sender: UIButton? = nil) {
        //when we enter this view, we turn off all buttons, because its a sheet view and dont let user create
        //new view, without closing this one
        for subview in buttonsStack.arrangedSubviews {
            if let subview = subview.subviews.first as? UIButton {
                UIView.transition(with: subview, duration: constants.animationDuration, options: .transitionCrossDissolve, animations: {
                    subview.isHighlighted = false
                    subview.isEnabled = false
                })
            }
        }
        let createGameVC = CreateGameVC()
        createGameVC.currentUser = currentUser
        createGameVC.buttonsStack = buttonsStack
        if #available(iOS 15.0, *) {
            if let sheet = createGameVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.largestUndimmedDetentIdentifier = .medium
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersEdgeAttachedInCompactHeight = true
                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            }
        }
        present(createGameVC, animated: true, completion: nil)
    }
    
    //creates games for load, if they ended or in oneScreen mode
    @objc private func makeUserGamesList(_ sender: UIButton? = nil) {
        backButton = makeMainMenuButtonView(with: UIImage(systemName: "arrow.left"), text: "Back", and: #selector(makeGameMenu))
        view.addSubview(backButton)
        let backButtonConstraints = [backButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor), backButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor), backButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)]
        NSLayoutConstraint.activate(backButtonConstraints)
        buttonsStack = UIStackView()
        buttonsStack.setup(axis: .vertical, alignment: .fill, distribution: .fill, spacing: constants.optimalSpacing)
        for game in currentUser.games.sorted(by: {$0.startDate > $1.startDate}) {
            buttonsStack.addArrangedSubview(makeInfoView(of: game))
        }
        animateButtonsStack(reversed: Bool.random(), addBackButton: true)
    }
    
    //TODO: -
    
    @objc private func makeMultiplayerGamesList(_ sender: UIButton? = nil) {
        
    }
    
    //
    
    //shows/hides additional info about game with animation
    @objc private func toggleGameInfo(_ sender: UIButton? = nil) {
        if let sender = sender {
            if let gameInfoView = sender.superview?.superview?.superview {
                if let additionalInfo = gameInfoView.subviews.first(where: {$0 as? GameInfoTable != nil}) {
                    let heightConstraint = gameInfoView.constraints.first(where: {$0.firstAttribute == .height && $0.secondItem == nil})
                    if let heightConstraint = heightConstraint {
                        NSLayoutConstraint.deactivate([heightConstraint])
                        gameInfoView.removeConstraint(heightConstraint)
                        var heightConstraint: NSLayoutConstraint?
                        var newAlpha = 0.0
                        let isHidden = additionalInfo.isHidden
                        if additionalInfo.isHidden {
                            additionalInfo.isHidden = false
                            sender.transform = CGAffineTransform(rotationAngle: .pi)
                            newAlpha = 1
                            heightConstraint = gameInfoView.heightAnchor.constraint(equalToConstant: fontSize * constants.multiplierForButtonSize * constants.sizeMultiplayerForGameInfo)
                        }
                        else {
                            sender.transform = .identity
                            heightConstraint = gameInfoView.heightAnchor.constraint(equalToConstant: fontSize * constants.multiplierForButtonSize)
                        }
                        if let heightConstraint = heightConstraint {
                            UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
                                additionalInfo.alpha = newAlpha
                                NSLayoutConstraint.activate([heightConstraint])
                                //for some reason, when we animating first time, second header also shows with animation
                                //this is not bad, but it only work once and later on there is no such animation, which i dont like,
                                //so i just removed it like this
                                if isHidden {
                                    UIView.performWithoutAnimation {
                                        additionalInfo.layoutIfNeeded()
                                    }
                                }
                                self?.view.layoutIfNeeded()
                            }) {_ in
                                if !isHidden {
                                    additionalInfo.isHidden = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    //loads chosen game
    @objc private func loadGame(_ sender: UIButton? = nil) {
        if let sender = sender {
            if let game = sender.layer.value(forKey: constants.keyForGame) as? GameLogic {
                let gameVC = GameViewController()
                gameVC.currentUser = currentUser
                gameVC.gameLogic = game
                gameVC.modalPresentationStyle = .fullScreen
                present(gameVC, animated: true)
            }
        }
    }
    
    //deletes chosen game
    @objc private func deleteGame(_ sender: UIButton? = nil) {
        let alert = UIAlertController(title: "Delete game", message: "Are you sure?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            if let self = self {
                if let sender = sender {
                    if let game = sender.layer.value(forKey: constants.keyForGame) as? GameLogic {
                        self.currentUser.removeGame(game)
                        self.storage.saveUser(self.currentUser)
                        if let gameInfo = sender.superview?.superview?.superview {
                            UIView.animate(withDuration: constants.animationDuration, animations: {
                                gameInfo.isHidden = true
                            }) { _ in
                                gameInfo.removeFromSuperview()
                            }
                        }
                    }
                }
            }
        }))
        present(alert, animated: true)
    }
    
    // MARK: - Local Methods
    
    //random transition from left or right for view
    private func randomAnimationFor(view: UIView) {
        let sumOperation: (CGFloat, CGFloat) -> CGFloat = {$0 + $1}
        let subtractOperation: (CGFloat, CGFloat) -> CGFloat = {$0 - $1}
        let operations = [sumOperation, subtractOperation]
        let randomOperation = operations.randomElement()
        let endX = view.bounds.minX
        if let randomOperation = randomOperation {
            let startX = randomOperation(endX, self.view.frame.width)
            view.transform = CGAffineTransform(translationX: startX, y: 0)
            UIView.animate(withDuration: constants.animationDuration, animations: {
                view.transform = CGAffineTransform(translationX: endX, y: 0)
            })
        }
    }
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private lazy var fontSize = min(view.frame.width, view.frame.height) / constants.dividerForFont
    
    private var buttonsStack = UIStackView()
    private var scrollView = UIScrollView()
    private var scrollViewContent = UIView()
    private var backButton = UIImageView()
    
    // MARK: - UI Methods
    
    private func makeUI() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        makeBackground()
        makeMainMenu()
    }
    
    private func makeScrollView(backButtonOutside: Bool) {
        scrollView = CustomScrollView()
        scrollViewContent = UIView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollViewContent.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delaysContentTouches = false
        view.addSubview(scrollView)
        scrollView.addSubview(scrollViewContent)
        var scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.bottomAnchor)
        if backButtonOutside {
            scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(lessThanOrEqualTo: backButton.topAnchor)
        }
        let contentHeight = scrollViewContent.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        contentHeight.priority = .defaultLow
        let scrollViewConstraints = [scrollView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor), scrollView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor), scrollView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), scrollView.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor), scrollView.topAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.topAnchor), scrollViewBottomConstraint]
        let contentConstraints = [scrollViewContent.topAnchor.constraint(equalTo: scrollView.topAnchor), scrollViewContent.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor), scrollViewContent.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor), scrollViewContent.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor), scrollViewContent.widthAnchor.constraint(equalTo: scrollView.widthAnchor), contentHeight]
        NSLayoutConstraint.activate(scrollViewConstraints + contentConstraints)
    }
    
    //makes background of the view
    private func makeBackground() {
        let background = UIImageView()
        background.translatesAutoresizingMaskIntoConstraints = false
        background.image = UIImage(named: "misc/defaultBG")
        background.contentMode = .scaleAspectFill
        background.layer.masksToBounds = true
        view.addSubview(background)
        let backgroundConstraints = [background.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor), background.leadingAnchor.constraint(equalTo: view.leadingAnchor), background.trailingAnchor.constraint(equalTo: view.trailingAnchor), background.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        NSLayoutConstraint.activate(backgroundConstraints)
    }
    
    private func configureButtonsStack(backButtonOutside: Bool) {
        makeScrollView(backButtonOutside: backButtonOutside)
        scrollViewContent.addSubview(buttonsStack)
        let buttonsConstraints = [buttonsStack.leadingAnchor.constraint(equalTo: scrollViewContent.leadingAnchor), buttonsStack.trailingAnchor.constraint(equalTo: scrollViewContent.trailingAnchor), buttonsStack.topAnchor.constraint(equalTo: scrollViewContent.topAnchor), buttonsStack.bottomAnchor.constraint(equalTo: scrollViewContent.bottomAnchor)]
        NSLayoutConstraint.activate(buttonsConstraints)
    }
    
    //one buttonsStack goes up, another from down or vice versa
    //if backButton is not part of a stack it goes from left to right and vice versa
    private func animateButtonsStack(reversed: Bool = false, addBackButton: Bool = false) {
        let yForAnimation = reversed ? view.frame.height : -view.frame.height
        let xForBackButton = view.frame.width
        if let subview = view.subviews.first(where: {$0 as? UIScrollView != nil}) {
            UIView.animate(withDuration: constants.animationDuration, animations: {
                subview.transform = CGAffineTransform(translationX: 0, y: yForAnimation)
            }) { _ in
                subview.removeFromSuperview()
            }
        }
        if !addBackButton, let subview = view.subviews.first(where: {$0 == backButton}) {
            UIView.animate(withDuration: constants.animationDuration, animations: {
                subview.transform = CGAffineTransform(translationX: -xForBackButton, y: 0)
            }) { _ in
                subview.removeFromSuperview()
            }
        }
        else if addBackButton {
            backButton.transform = CGAffineTransform(translationX: -xForBackButton, y: 0)
        }
        configureButtonsStack(backButtonOutside: addBackButton)
        scrollView.transform = CGAffineTransform(translationX: 0, y: -yForAnimation)
        UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
            self?.scrollView.transform = .identity
            if addBackButton {
                self?.backButton.transform = .identity
            }
        })
    }
    
    //makes big round buttons to navigate through main menu
    private func makeMainMenuButtonView(with image: UIImage?, text: String, and action: Selector) -> UIImageView {
        let font = UIFont.systemFont(ofSize: fontSize)
        let buttonBG = UIImageView()
        buttonBG.defaultSettings()
        buttonBG.settingsForBackgroundOfTheButton(cornerRadius: constants.cornerRadiusForButton)
        buttonBG.image = image
        let button = MainMenuButton(type: .system)
        button.buttonWith(text: text, font: font, and: action)
        buttonBG.addSubview(button)
        let buttonConstraints = [buttonBG.heightAnchor.constraint(equalToConstant: fontSize * constants.multiplierForButtonSize), button.widthAnchor.constraint(equalTo: buttonBG.widthAnchor), button.heightAnchor.constraint(equalTo: buttonBG.heightAnchor)]
        NSLayoutConstraint.activate(buttonConstraints)
        return buttonBG
    }
    
    //creates view with basic and additional info about game
    private func makeInfoView(of game: GameLogic) -> UIImageView {
        let infoView = UIImageView()
        infoView.defaultSettings()
        infoView.settingsForBackgroundOfTheButton(cornerRadius: constants.cornerRadiusForButton)
        let date = game.startDate.toStringDateHMS
        let dateLabel = UILabel()
        dateLabel.setup(text: date, alignment: .left, font: UIFont.systemFont(ofSize: fontSize / constants.dividerForDateFont))
        let infoLabelScrollView = UIScrollView()
        infoLabelScrollView.translatesAutoresizingMaskIntoConstraints = false
        infoLabelScrollView.delaysContentTouches = false
        let infoLabel = makeInfoLabel(of: game)
        infoLabelScrollView.addSubview(infoLabel)
        let infoLabelWidth = infoLabel.widthAnchor.constraint(equalTo: infoLabelScrollView.widthAnchor)
        infoLabelWidth.priority = .defaultLow
        let additionalInfo = GameInfoTable(gameData: game, dataFont: UIFont.systemFont(ofSize: fontSize / constants.dividerForFontInAdditionalInfo))
        additionalInfo.isHidden = true
        additionalInfo.alpha = 0
        let helperButtons = makeHelperButtonsView(game: game)
        if game.gameEnded {
            if game.winner?.user.name == currentUser.name {
                infoView.backgroundColor = constants.gameWinnerColor
            }
            else if game.winner != nil {
                infoView.backgroundColor = constants.gameLoserColor
            }
            else {
                infoView.backgroundColor = constants.gameDrawColor
            }
        }
        else {
            infoView.backgroundColor = constants.gameNotEndedColor
        }
        infoView.addSubviews([dateLabel, infoLabelScrollView, additionalInfo, helperButtons])
        let infoViewConstraints = [infoView.heightAnchor.constraint(equalToConstant: fontSize * constants.multiplierForButtonSize)]
        let dateLabelConstraints = [dateLabel.leadingAnchor.constraint(equalTo: infoView.layoutMarginsGuide.leadingAnchor, constant: constants.optimalDistance), dateLabel.topAnchor.constraint(equalTo: infoView.layoutMarginsGuide.topAnchor)]
        let infoLabelScrollViewConstraints = [infoLabelScrollView.leadingAnchor.constraint(equalTo: infoView.layoutMarginsGuide.leadingAnchor), infoLabelScrollView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor), infoLabelScrollView.trailingAnchor.constraint(lessThanOrEqualTo: infoView.layoutMarginsGuide.trailingAnchor)]
        let infoLabelConstraints = [infoLabel.topAnchor.constraint(equalTo: infoLabelScrollView.topAnchor), infoLabel.bottomAnchor.constraint(equalTo: infoLabelScrollView.bottomAnchor), infoLabel.leadingAnchor.constraint(equalTo: infoLabelScrollView.leadingAnchor), infoLabel.trailingAnchor.constraint(equalTo: infoLabelScrollView.trailingAnchor), infoLabel.heightAnchor.constraint(equalTo: infoLabelScrollView.heightAnchor), infoLabelWidth]
        let additionalInfoConstraints = [additionalInfo.leadingAnchor.constraint(equalTo: infoView.layoutMarginsGuide.leadingAnchor), additionalInfo.trailingAnchor.constraint(equalTo: infoView.layoutMarginsGuide.trailingAnchor), additionalInfo.topAnchor.constraint(equalTo: infoLabel.bottomAnchor)]
        let helperButtonsConstraints = [helperButtons.topAnchor.constraint(equalTo: additionalInfo.bottomAnchor), helperButtons.bottomAnchor.constraint(equalTo: infoView.bottomAnchor), helperButtons.leadingAnchor.constraint(equalTo: infoView.leadingAnchor), helperButtons.trailingAnchor.constraint(equalTo: infoView.trailingAnchor), helperButtons.heightAnchor.constraint(equalToConstant: fontSize)]
        NSLayoutConstraint.activate(infoViewConstraints + dateLabelConstraints + infoLabelScrollViewConstraints + infoLabelConstraints + additionalInfoConstraints + helperButtonsConstraints)
        return infoView
    }
    
    private func makeInfoLabel(of game: GameLogic) -> UILabel {
        let gameInfoLabel = UILabel()
        var gameInfoText = game.players.first!.user.name + " " + String(game.players.first!.user.points) + "(" + String(game.players.first!.pointsForGame)
        gameInfoText += ")" + " " + "vs " + game.players.second!.user.name + " " + String(game.players.second!.user.points)
        gameInfoText += "(" + String(game.players.second!.pointsForGame) + ")"
        gameInfoLabel.setup(text: gameInfoText, alignment: .center, font: UIFont.systemFont(ofSize: fontSize))
        return gameInfoLabel
    }
    
    //makes buttons for additional actions
    private func makeHelperButtonsView(game: GameLogic) -> UIImageView {
        let helperButtonsView = UIImageView()
        helperButtonsView.defaultSettings()
        helperButtonsView.backgroundColor = helperButtonsView.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        helperButtonsView.isUserInteractionEnabled = true
        let helperButtonsStack = UIStackView()
        helperButtonsStack.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.spacingForHelperButtons)
        let deleteButton = UIButton()
        deleteButton.buttonWith(image: UIImage(systemName: "trash"), and: #selector(deleteGame))
        let expandButton = UIButton()
        expandButton.buttonWith(image: UIImage(systemName: "menubar.arrow.down.rectangle"), and: #selector(toggleGameInfo))
        let enterButton = UIButton()
        enterButton.buttonWith(image: UIImage(systemName: "arrow.right.to.line"), and: #selector(loadGame))
        enterButton.layer.setValue(game, forKey: constants.keyForGame)
        deleteButton.layer.setValue(game, forKey: constants.keyForGame)
        helperButtonsStack.addArrangedSubviews([deleteButton, expandButton, enterButton])
        helperButtonsView.addSubview(helperButtonsStack)
        let helperButtonsStackConstraints = [helperButtonsStack.centerXAnchor.constraint(equalTo: helperButtonsView.centerXAnchor), helperButtonsStack.centerYAnchor.constraint(equalTo: helperButtonsView.centerYAnchor), deleteButton.widthAnchor.constraint(equalTo: deleteButton.heightAnchor), helperButtonsStack.heightAnchor.constraint(equalTo: helperButtonsView.heightAnchor, multiplier: constants.sizeMultiplayerForHelperButtonsStack)]
        NSLayoutConstraint.activate(helperButtonsStackConstraints)
        return helperButtonsView
    }
    
}

// MARK: - Constants

private struct MainMenuVC_Constants {
    static let dividerForFont: CGFloat = 13
    static let optimalSpacing = 5.0
    static let spacingForHelperButtons = 15.0
    static let optimalAlpha = 0.5
    static let cornerRadiusForButton = 30.0
    static let multiplierForButtonSize = 3.0
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let gameWinnerColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let gameLoserColor = UIColor.red.withAlphaComponent(optimalAlpha)
    static let gameDrawColor = UIColor.yellow.withAlphaComponent(optimalAlpha)
    static let gameNotEndedColor = UIColor.orange.withAlphaComponent(optimalAlpha)
    static let animationDuration = 0.5
    static let sizeMultiplayerForGameInfo = 2.0
    static let sizeMultiplayerForHelperButtonsStack = 0.9
    static let dividerForDateFont = 3.0
    static let optimalDistance = 10.0
    static let dividerForFontInAdditionalInfo = 2.0
    static let keyForGame = "Game"
}

// MARK: - CustomScrollView

//allows to scroll buttons, which have isExclusiveTouch set to true and/or if user holds them
class CustomScrollView: UIScrollView {
    
    override func touchesShouldCancel(in view: UIView) -> Bool {
        true
    }
    
}
