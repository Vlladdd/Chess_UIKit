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
        if let additionalButtons = view.subviews.first(where: {$0 == additionalButtons}) {
            randomAnimationFor(view: additionalButtons)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if presentedViewController == nil {
            UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
                if let self = self {
                    for button in self.buttonsStack.arrangedSubviews {
                        for subview in button.subviews {
                            if let frame = subview as? PlayerFrame {
                                frame.setNeedsDisplay()
                            }
                        }
                    }
                }
            })
        }
    }
    
    // MARK: - Properties
    
    private typealias constants = MainMenuVC_Constants
    
    private let storage = Storage()
    
    var currentUser: User!
    
    // MARK: - Buttons Methods
    
    @objc private func makeGameMenu(_ sender: UIButton? = nil) {
        let createButton = makeMainMenuButtonView(with: UIImage(named: "misc/createButtonBG"), buttonImage: nil, buttontext: "Create", and: #selector(makeCreateGameVC))
        let joinButton = makeMainMenuButtonView(with: UIImage(named: "misc/joinButtonBG"), buttonImage: nil, buttontext: "Join", and: #selector(makeMultiplayerGamesList))
        let loadButton = makeMainMenuButtonView(with: UIImage(named: "misc/loadButtonBG"), buttonImage: nil, buttontext: "Load", and: #selector(makeUserGamesList))
        updateButtonsStack(with: [createButton, joinButton, loadButton], addBackButton: true)
        animateButtonsStack()
    }
    
    @objc private func makeInventoryMenu(_ sender: UIButton? = nil) {
        updateButtonsStack(with: makeInventoryOrShopButtons(isShopButtons: false), addBackButton: true)
        addNotificationIconsInButtonsStack()
        animateButtonsStack()
    }
    
    @objc private func makeShopMenu(_ sender: UIButton? = nil) {
        updateButtonsStack(with: makeInventoryOrShopButtons(isShopButtons: true), addBackButton: true)
        addNotificationIconsInButtonsStack()
        animateButtonsStack()
    }
    
    //for inventory or shop
    @objc private func makeListOfItems(_ sender: UIButton? = nil) {
        var buttons = [UIView]()
        if let sender = sender {
            if let isShopButtons = sender.superview?.layer.value(forKey: constants.keyForIsShopButton) as? Bool {
                if let items = sender.superview?.layer.value(forKey: constants.keyForItems) as? [Item], items.count > 0 {
                    switch items.first!.type {
                    case .squaresTheme:
                        if let squaresThemes = sender.superview?.layer.value(forKey: constants.keyForItems) as? [SquaresThemes] {
                            buttons = makeSquaresThemesView(squaresThemes: squaresThemes, isShopButtons: isShopButtons)
                        }
                    case .figuresTheme:
                        if let figuresThemes = sender.superview?.layer.value(forKey: constants.keyForItems) as? [FiguresThemes] {
                            buttons = makeFiguresView(figuresThemes: figuresThemes, isShopButtons: isShopButtons)
                        }
                    case .boardTheme:
                        if let boardThemes = sender.superview?.layer.value(forKey: constants.keyForItems) as? [BoardThemes] {
                            buttons = makeBoardThemesView(boardThemes: boardThemes, isShopButtons: isShopButtons)
                        }
                    case .frame:
                        if let frames = sender.superview?.layer.value(forKey: constants.keyForItems) as? [Frames] {
                            buttons = makeFramesView(frames: frames, isShopButtons: isShopButtons)
                        }
                    case .background:
                        if let backgroundThemes = sender.superview?.layer.value(forKey: constants.keyForItems) as? [Backgrounds] {
                            buttons = makeBackgroundThemesView(backgroundThemes: backgroundThemes, isShopButtons: isShopButtons)
                        }
                    case .title:
                        if let titles = sender.superview?.layer.value(forKey: constants.keyForItems) as? [Titles] {
                            buttons = makeTitlesView(titles: titles, isShopButtons: isShopButtons)
                        }
                    case .avatar:
                        break
                    }
                    updateButtonsStack(with: buttons, addBackButton: false)
                    addNotificationIconsInButtonsStack()
                    makeAdditionalButtonsForShopOrInventory(isShopButtons: isShopButtons)
                    updateItemsColor(inShop: isShopButtons)
                }
            }
        }
        animateButtonsStack(reversed: false, addAdditionalButtons: true)
    }
    
    //change current value of item of user
    @objc private func chooseItemInInventory(_ sender: UIButton? = nil) {
        if let sender = sender {
            if let item = sender.superview?.superview?.layer.value(forKey: constants.keyForItem) as? Item {
                currentUser.setValue(with: item)
                updateItemsColor(inShop: false)
                storage.saveUser(currentUser)
            }
        }
    }
    
    //highlight picked item and remove notification icon from him
    @objc private func pickitem(_ sender: UITapGestureRecognizer? = nil) {
        if let sender = sender {
            if let mainMenuButton = sender.view?.superview {
                if let item = mainMenuButton.layer.value(forKey: constants.keyForItem) as? Item {
                    currentUser.addSeenItem(item)
                    for button in buttonsStack.arrangedSubviews {
                        button.layer.borderColor = defaultTextColor.cgColor
                    }
                    mainMenuButton.layer.borderColor = constants.pickItemBorderColor
                    if let buttonsStack = mainMenuButton.superview {
                        if let notificationIcon = buttonsStack.subviews.first(where: {
                            if let parentView = $0.layer.value(forKey: constants.keyForParentView) as? UIView {
                                return parentView == mainMenuButton
                            }
                            return false
                        }) {
                            notificationIcon.removeFromSuperview()
                        }
                    }
                    storage.saveUser(currentUser)
                }
            }
        }
    }
    
    @objc private func showDescriptionForItemInInventory(_ sender: UIButton? = nil) {
        if let mainMenuButton = sender?.superview?.superview {
            let descriptionView = mainMenuButton.subviews[3]
            let newAlpha: CGFloat = descriptionView.alpha == 0 ? 1 : 0
            UIView.animate(withDuration: constants.animationDuration, animations: {
                descriptionView.alpha = newAlpha
            })
        }
    }
    
    @objc private func buyItem(_ sender: UIButton? = nil) {
        if let mainMenuButton = sender?.superview?.superview {
            if let item = mainMenuButton.layer.value(forKey: constants.keyForItem) as? Item {
                let itemName = item.name.replacingOccurrences(of: "_", with: " ").capitalizingFirstLetter()
                let alert = UIAlertController(title: "Buy \(itemName)", message: "Are you sure?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {[weak self] _ in
                    if let self = self {
                        self.currentUser.addAvailableItem(item)
                        var startCoins = self.currentUser.coins
                        self.currentUser.addCoins(-item.cost)
                        let endCoins = self.currentUser.coins
                        self.storage.saveUser(self.currentUser)
                        let snapshotOfShopitem = mainMenuButton.subviews.second!.snapshotView(afterScreenUpdates: true)!
                        self.view.addSubview(snapshotOfShopitem)
                        let snapshotConstraints = [snapshotOfShopitem.leadingAnchor.constraint(equalTo: snapshotOfShopitem.superview!.leadingAnchor), snapshotOfShopitem.topAnchor.constraint(equalTo: snapshotOfShopitem.superview!.topAnchor)]
                        NSLayoutConstraint.activate(snapshotConstraints)
                        let actualPosOfSnapshot = snapshotOfShopitem.convert(mainMenuButton.bounds, from: mainMenuButton)
                        snapshotOfShopitem.transform = CGAffineTransform(translationX: actualPosOfSnapshot.minX, y: actualPosOfSnapshot.minY)
                        let coinsBoundsForAnimation = snapshotOfShopitem.convert(self.coinsText.bounds, from: self.coinsText)
                        UIView.animate(withDuration: constants.animationDuration, animations: {
                            sender?.isEnabled = false
                            sender?.backgroundColor = constants.inInventoryColor
                            sender?.setTitleColor(self.defaultTextColor, for: .normal)
                            mainMenuButton.backgroundColor = constants.inInventoryColor
                            snapshotOfShopitem.transform = constants.transformForShopItemWhenBought.concatenating(snapshotOfShopitem.transform.translatedBy(x: coinsBoundsForAnimation.midX - snapshotOfShopitem.bounds.midX, y: coinsBoundsForAnimation.midY - snapshotOfShopitem.bounds.midY))
                        }) {  _ in
                            snapshotOfShopitem.removeFromSuperview()
                        }
                        let interval = constants.animationDuration / Double(startCoins - endCoins)
                        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { timer in
                            if startCoins == endCoins {
                                timer.invalidate()
                                return
                            }
                            startCoins -= 1
                            self.coinsText.text = String(startCoins)
                        })
                        RunLoop.main.add(timer, forMode: .common)
                    }
                }))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc private func makeMainMenu(_ sender: UIButton? = nil) {
        let gameButton = makeMainMenuButtonView(with: UIImage(named: "misc/gameButtonBG"), buttonImage: nil, buttontext: "Game", and: #selector(makeGameMenu))
        let inventoryButton = makeMainMenuButtonView(with: UIImage(named: "misc/inventoryButtonBG"), buttonImage: nil, buttontext: "Inventory", and: #selector(makeInventoryMenu))
        let shopButton = makeMainMenuButtonView(with: UIImage(named: "misc/shopButtonBG"), buttonImage: nil, buttontext: "Shop", and: #selector(makeShopMenu))
        updateButtonsStack(with: [gameButton, inventoryButton, shopButton], addBackButton: false)
        var haveNewInventoryItem = false
        var haveNewShopItem = false
        //right now only titles can be different in shop and inventory, but it might change in future
        for itemType in ItemTypes.allCases {
            switch itemType {
            case .squaresTheme:
                haveNewInventoryItem = currentUser.haveNewSquaresThemesInInventory()
                haveNewShopItem = currentUser.haveNewSquaresThemesInInventory()
            case .figuresTheme:
                haveNewInventoryItem = currentUser.haveNewFiguresThemesInInventory()
                haveNewShopItem = currentUser.haveNewFiguresThemesInInventory()
            case .boardTheme:
                haveNewInventoryItem = currentUser.haveNewBoardThemesInInventory()
                haveNewShopItem = currentUser.haveNewBoardThemesInInventory()
            case .frame:
                haveNewInventoryItem = currentUser.haveNewFramesInInventory()
                haveNewShopItem = currentUser.haveNewFramesInInventory()
            case .background:
                haveNewInventoryItem = currentUser.haveNewBackgroundsInInventory()
                haveNewShopItem = currentUser.haveNewBackgroundsInInventory()
            case .title:
                haveNewInventoryItem = currentUser.haveNewTitlesInInventory()
                haveNewShopItem = currentUser.haveNewTitlesInShop()
            case .avatar:
                break
            }
            if haveNewInventoryItem && haveNewShopItem {
                break
            }
        }
        if haveNewInventoryItem {
            addNotificationIconTo(view: inventoryButton)
        }
        if haveNewShopItem {
            addNotificationIconTo(view: shopButton)
        }
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
        let backButton = makeMainMenuButtonView(with: UIImage(systemName: "arrow.left"), buttonImage: nil, buttontext: "Back", and: #selector(makeGameMenu))
        makeAdditionalButtons(with: [backButton])
        updateButtonsStack(with: currentUser.games.sorted(by: {$0.startDate > $1.startDate}).map({makeInfoView(of: $0)}), addBackButton: false)
        animateButtonsStack(reversed: Bool.random(), addAdditionalButtons: true)
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
        var notificationIcon: UIView?
        if let superview = view.superview {
            if let notificationIconView = superview.subviews.first(where: {
                if let parentView = $0.layer.value(forKey: constants.keyForParentView) as? UIView {
                    return parentView == view
                }
                return false
            }) {
                notificationIcon = notificationIconView
            }
        }
        let sumOperation: (CGFloat, CGFloat) -> CGFloat = {$0 + $1}
        let subtractOperation: (CGFloat, CGFloat) -> CGFloat = {$0 - $1}
        let operations = [sumOperation, subtractOperation]
        let randomOperation = operations.randomElement()
        let endX = view.bounds.minX
        if let randomOperation = randomOperation {
            let startX = randomOperation(endX, self.view.frame.width)
            view.transform = CGAffineTransform(translationX: startX, y: 0)
            notificationIcon?.transform = CGAffineTransform(translationX: startX, y: 0)
            UIView.animate(withDuration: constants.animationDuration, animations: {
                view.transform = CGAffineTransform(translationX: endX, y: 0)
                notificationIcon?.transform = CGAffineTransform(translationX: endX, y: 0)
            })
        }
    }
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private lazy var fontSize = min(view.frame.width, view.frame.height) / constants.dividerForFont
    private lazy var defaultFont = UIFont.systemFont(ofSize: fontSize)
    private lazy var defaultBackgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
    private lazy var defaultTextColor = traitCollection.userInterfaceStyle == .dark ? constants.lightModeBackgroundColor : constants.darkModeBackgroundColor
    
    private var buttonsStack = UIStackView()
    //there is a bug, when animating scrollView, which leads to weird jump of first arrangedSubview subviews of buttonsStack
    //by putting scrollView inside a view, we are fixing this bug
    //other approach is to simply call view.setNeedsLayout() and view.layoutIfNeeded(), but that will also affect backButton,
    //which i don`t want to
    private var viewForScrollView = UIView()
    private var scrollViewContent = UIView()
    private var additionalButtons = UIStackView()
    private let coinsText = UILabel()
    
    // MARK: - UI Methods
    
    private func makeUI() {
        view.backgroundColor = defaultBackgroundColor
        makeBackground()
        makeMainMenu()
    }
    
    private func makeScrollView(withAdditionalButtons: Bool) {
        viewForScrollView = UIView()
        viewForScrollView.translatesAutoresizingMaskIntoConstraints = false
        let scrollView = CustomScrollView()
        scrollViewContent = UIView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollViewContent.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delaysContentTouches = false
        viewForScrollView.addSubview(scrollView)
        view.addSubview(viewForScrollView)
        scrollView.addSubview(scrollViewContent)
        var viewForScrollViewBottomConstraint = viewForScrollView.bottomAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.bottomAnchor)
        if withAdditionalButtons {
            viewForScrollViewBottomConstraint = viewForScrollView.bottomAnchor.constraint(lessThanOrEqualTo: additionalButtons.topAnchor)
        }
        let contentHeight = scrollViewContent.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        contentHeight.priority = .defaultLow
        let viewForScrollViewConstraints = [viewForScrollView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor), viewForScrollView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor), viewForScrollView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), viewForScrollView.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor), viewForScrollView.topAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.topAnchor), viewForScrollViewBottomConstraint]
        let scrollViewConstraints = [scrollView.leadingAnchor.constraint(equalTo: viewForScrollView.leadingAnchor), scrollView.trailingAnchor.constraint(equalTo: viewForScrollView.trailingAnchor), scrollView.topAnchor.constraint(equalTo: viewForScrollView.topAnchor), scrollView.bottomAnchor.constraint(equalTo: viewForScrollView.bottomAnchor)]
        let contentConstraints = [scrollViewContent.topAnchor.constraint(equalTo: scrollView.topAnchor), scrollViewContent.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor), scrollViewContent.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor), scrollViewContent.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor), scrollViewContent.widthAnchor.constraint(equalTo: scrollView.widthAnchor), contentHeight]
        NSLayoutConstraint.activate(viewForScrollViewConstraints + scrollViewConstraints + contentConstraints)
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
    
    private func configureButtonsStack(withAdditionalButtons: Bool) {
        makeScrollView(withAdditionalButtons: withAdditionalButtons)
        scrollViewContent.addSubview(buttonsStack)
        let buttonsConstraints = [buttonsStack.leadingAnchor.constraint(equalTo: scrollViewContent.leadingAnchor), buttonsStack.trailingAnchor.constraint(equalTo: scrollViewContent.trailingAnchor, constant: -constants.optimalDistance), buttonsStack.topAnchor.constraint(equalTo: scrollViewContent.topAnchor,  constant: constants.optimalDistance), buttonsStack.bottomAnchor.constraint(equalTo: scrollViewContent.bottomAnchor)]
        NSLayoutConstraint.activate(buttonsConstraints)
    }
    
    //one buttonsStack goes up, another from down or vice versa
    //if backButton is not part of a stack it goes from left to right and vice versa
    private func animateButtonsStack(reversed: Bool = false, addAdditionalButtons: Bool = false) {
        let yForAnimation = reversed ? view.frame.height : -view.frame.height
        let xForBackButton = view.frame.width
        if let subview = view.subviews.first(where: {$0.subviews.first as? UIScrollView != nil}) {
            UIView.animate(withDuration: constants.animationDuration, animations: {
                subview.subviews.first?.transform = CGAffineTransform(translationX: 0, y: yForAnimation)
            }) { _ in
                subview.removeFromSuperview()
            }
        }
        if !addAdditionalButtons, let subview = view.subviews.first(where: {$0 == additionalButtons}) {
            UIView.animate(withDuration: constants.animationDuration, animations: {
                subview.transform = CGAffineTransform(translationX: -xForBackButton, y: 0)
            }) { _ in
                subview.removeFromSuperview()
            }
        }
        else if addAdditionalButtons {
            additionalButtons.transform = CGAffineTransform(translationX: -xForBackButton, y: 0)
        }
        configureButtonsStack(withAdditionalButtons: addAdditionalButtons)
        viewForScrollView.subviews.first?.transform = CGAffineTransform(translationX: 0, y: -yForAnimation)
        UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
            self?.viewForScrollView.subviews.first?.transform = .identity
            if addAdditionalButtons {
                self?.additionalButtons.transform = .identity
            }
        })
    }
    
    //makes big round buttons to navigate through main menu
    private func makeMainMenuButtonView(with backgroundImage: UIImage?, buttonImage: UIImage?, buttontext: String, and action: Selector?, circleButton: Bool = false) -> UIImageView {
        let buttonBG = UIImageView()
        buttonBG.defaultSettings()
        buttonBG.settingsForBackgroundOfTheButton(cornerRadius: constants.cornerRadiusForButton)
        buttonBG.image = backgroundImage
        var buttonConstraints = [NSLayoutConstraint]()
        if let action = action {
            let button = MainMenuButton(type: .system)
            button.buttonWith(image: buttonImage, text: buttontext, font: defaultFont, and: action)
            buttonBG.addSubview(button)
            buttonConstraints += [button.widthAnchor.constraint(equalTo: buttonBG.widthAnchor), button.heightAnchor.constraint(equalTo: buttonBG.heightAnchor), button.centerXAnchor.constraint(equalTo: buttonBG.centerXAnchor), button.centerYAnchor.constraint(equalTo: buttonBG.centerYAnchor)]
            if buttonImage != nil {
                button.contentEdgeInsets = constants.insetsForCircleButton
            }
        }
        if !circleButton {
            buttonConstraints.append(buttonBG.heightAnchor.constraint(equalToConstant: fontSize * constants.multiplierForButtonSize))
        }
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
        gameInfoLabel.setup(text: gameInfoText, alignment: .center, font: defaultFont)
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
    
    private func updateButtonsStack(with views: [UIView], addBackButton: Bool) {
        buttonsStack = UIStackView()
        buttonsStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        buttonsStack.addArrangedSubviews(views)
        if addBackButton {
            buttonsStack.addArrangedSubview(makeMainMenuButtonView(with: UIImage(systemName: "arrow.left"), buttonImage: nil, buttontext: "Back", and: #selector(makeMainMenu)))
        }
    }
    
    private func addNotificationIconsInButtonsStack() {
        for button in buttonsStack.arrangedSubviews {
            if let inventoryItems = button.layer.value(forKey: constants.keyForItems) as? [Item] {
                if currentUser.containsNewItemIn(items: inventoryItems) {
                    addNotificationIconTo(view: button)
                }
            }
            else if let inventoryItem = button.layer.value(forKey: constants.keyForItem) as? Item {
                if currentUser.containsNewItemIn(items: [inventoryItem]) {
                    addNotificationIconTo(view: button)
                }
            }
        }
    }
    
    private func makeShopItemButton(with view: UIView, shopItem: Item, inInventory: Bool) -> UIImageView {
        let buttonBG = makeMainMenuButtonView(with: nil, buttonImage: nil, buttontext: "", and: nil)
        let buyButton = makeMainMenuButtonView(with: UIImage(named: "misc/coinsBG"), buttonImage: nil, buttontext: String(shopItem.cost), and: #selector(buyItem))
        buttonBG.addSubview(buyButton)
        buttonBG.addSubview(view)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pickitem))
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true
        let viewConstraints = [view.leadingAnchor.constraint(equalTo: buttonBG.leadingAnchor), view.trailingAnchor.constraint(equalTo: buyButton.leadingAnchor), view.topAnchor.constraint(equalTo: buttonBG.topAnchor), view.bottomAnchor.constraint(equalTo: buttonBG.bottomAnchor)]
        let buyButtonConstraints = [buyButton.trailingAnchor.constraint(equalTo: buttonBG.trailingAnchor), buyButton.widthAnchor.constraint(equalTo: buttonBG.widthAnchor, multiplier: constants.multiplierForAdditionalButtonsSizeInMainMenuButton), buyButton.centerYAnchor.constraint(equalTo: buttonBG.centerYAnchor)]
        NSLayoutConstraint.activate(buyButtonConstraints + viewConstraints)
        buttonBG.layer.setValue(shopItem, forKey: constants.keyForItem)
        return buttonBG
    }
    
    private func makeInventoryItemButton(with view: UIView, inventoryItem: Item, inInventory: Bool) -> UIImageView {
        let descriptionScrollView = UIScrollView()
        descriptionScrollView.translatesAutoresizingMaskIntoConstraints = false
        descriptionScrollView.delaysContentTouches = false
        descriptionScrollView.alpha = 0
        let itemDescription = UILabel()
        itemDescription.setup(text: inventoryItem.description, alignment: .center, font: defaultFont)
        itemDescription.numberOfLines = 0
        descriptionScrollView.backgroundColor = defaultBackgroundColor
        descriptionScrollView.addSubview(itemDescription)
        let descriptionHeightConstraint = itemDescription.heightAnchor.constraint(equalTo: descriptionScrollView.heightAnchor)
        descriptionHeightConstraint.priority = .defaultLow
        let buttonBG = makeMainMenuButtonView(with: nil, buttonImage: nil, buttontext: "", and: nil)
        let chooseButton = makeMainMenuButtonView(with: nil, buttonImage: UIImage(systemName: "checkmark"), buttontext: "", and: #selector(chooseItemInInventory), circleButton: true)
        let descriptionButton = makeMainMenuButtonView(with: nil, buttonImage: UIImage(systemName: "info"), buttontext: "", and: #selector(showDescriptionForItemInInventory), circleButton: true)
        buttonBG.addSubview(chooseButton)
        buttonBG.addSubview(descriptionButton)
        buttonBG.addSubview(view)
        buttonBG.addSubview(descriptionScrollView)
        buttonBG.layer.setValue(inventoryItem, forKey: constants.keyForItem)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pickitem))
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true
        let viewConstraints = [view.leadingAnchor.constraint(equalTo: buttonBG.leadingAnchor), view.trailingAnchor.constraint(equalTo: chooseButton.leadingAnchor), view.topAnchor.constraint(equalTo: buttonBG.topAnchor), view.bottomAnchor.constraint(equalTo: buttonBG.bottomAnchor)]
        let chooseButtonConstraints = [chooseButton.trailingAnchor.constraint(equalTo: descriptionButton.leadingAnchor), chooseButton.widthAnchor.constraint(equalTo: buttonBG.widthAnchor, multiplier: constants.multiplierForAdditionalButtonsSizeInMainMenuButton / 2), chooseButton.topAnchor.constraint(equalTo: buttonBG.topAnchor, constant: constants.optimalDistance), chooseButton.bottomAnchor.constraint(equalTo: buttonBG.bottomAnchor, constant: -constants.optimalDistance)]
        let descriptionConstraints = [descriptionButton.trailingAnchor.constraint(equalTo: buttonBG.trailingAnchor), descriptionButton.widthAnchor.constraint(equalTo: buttonBG.widthAnchor, multiplier: constants.multiplierForAdditionalButtonsSizeInMainMenuButton / 2), descriptionButton.topAnchor.constraint(equalTo: buttonBG.topAnchor, constant: constants.optimalDistance), descriptionButton.bottomAnchor.constraint(equalTo: buttonBG.bottomAnchor, constant: -constants.optimalDistance)]
        let itemDescriptionConstraint = [itemDescription.leadingAnchor.constraint(equalTo: descriptionScrollView.leadingAnchor), itemDescription.trailingAnchor.constraint(equalTo: descriptionScrollView.trailingAnchor), itemDescription.topAnchor.constraint(equalTo: descriptionScrollView.topAnchor), itemDescription.bottomAnchor.constraint(equalTo: descriptionScrollView.bottomAnchor), itemDescription.widthAnchor.constraint(equalTo: descriptionScrollView.widthAnchor), descriptionHeightConstraint]
        let descriptionScrollViewConstraints = [descriptionScrollView.leadingAnchor.constraint(equalTo: buttonBG.leadingAnchor), descriptionScrollView.trailingAnchor.constraint(equalTo: chooseButton.leadingAnchor), descriptionScrollView.topAnchor.constraint(equalTo: buttonBG.topAnchor), descriptionScrollView.bottomAnchor.constraint(equalTo: buttonBG.bottomAnchor)]
        NSLayoutConstraint.activate(chooseButtonConstraints + viewConstraints + descriptionConstraints + itemDescriptionConstraint + descriptionScrollViewConstraints)
        return buttonBG
    }
    
    private func makeShowcase(items: UIStackView, item: Item, inInventory: Bool, axis: NSLayoutConstraint.Axis, isShopButton: Bool) -> UIImageView {
        let showcaseScrollView = UIScrollView()
        showcaseScrollView.translatesAutoresizingMaskIntoConstraints = false
        showcaseScrollView.addSubview(items)
        let showCaseBG = isShopButton ? makeShopItemButton(with: showcaseScrollView, shopItem: item, inInventory: inInventory) : makeInventoryItemButton(with: showcaseScrollView, inventoryItem: item, inInventory: inInventory)
        let widthConstraint = items.widthAnchor.constraint(equalTo: showcaseScrollView.widthAnchor)
        let heightConstraint = items.heightAnchor.constraint(equalTo: showcaseScrollView.heightAnchor)
        var itemsConstraints = [NSLayoutConstraint]()
        if axis == .vertical {
            widthConstraint.priority = .defaultLow
            itemsConstraints += [items.leadingAnchor.constraint(equalTo: showcaseScrollView.leadingAnchor, constant: constants.optimalDistance), items.trailingAnchor.constraint(equalTo: showcaseScrollView.trailingAnchor, constant: -constants.optimalDistance), items.centerYAnchor.constraint(equalTo: showcaseScrollView.centerYAnchor), items.topAnchor.constraint(equalTo: showcaseScrollView.topAnchor, constant: constants.distanceForContentInHorizontalShowcase), items.bottomAnchor.constraint(equalTo: showcaseScrollView.bottomAnchor, constant: -constants.distanceForContentInHorizontalShowcase), widthConstraint]
        }
        else {
            heightConstraint.priority = .defaultLow
            itemsConstraints += [items.topAnchor.constraint(equalTo: showcaseScrollView.topAnchor, constant: constants.optimalDistance), items.bottomAnchor.constraint(equalTo: showcaseScrollView.bottomAnchor, constant: -constants.optimalDistance), items.leadingAnchor.constraint(equalTo: showcaseScrollView.leadingAnchor, constant: constants.optimalDistance), items.trailingAnchor.constraint(equalTo: showcaseScrollView.trailingAnchor, constant: -constants.optimalDistance), items.centerXAnchor.constraint(equalTo: showcaseScrollView.centerXAnchor), heightConstraint]
        }
        NSLayoutConstraint.activate(itemsConstraints)
        showCaseBG.layer.setValue(item, forKey: constants.keyForItem)
        return showCaseBG
    }
    
    private func makeColorData(text: String, color: Colors) -> UIStackView {
        let colorData = UIStackView()
        colorData.setup(axis: .horizontal, alignment: .fill, distribution: .fill, spacing: constants.optimalSpacing)
        let colorLabel = UILabel()
        colorLabel.setup(text: text, alignment: .center, font: defaultFont)
        let colorView = UIImageView()
        colorView.defaultSettings()
        colorView.backgroundColor = constants.convertLogicColor(color)
        let colorViewConstraints = [colorView.widthAnchor.constraint(equalTo: colorView.heightAnchor)]
        NSLayoutConstraint.activate(colorViewConstraints)
        colorData.addArrangedSubviews([colorLabel, colorView])
        return colorData
    }
    
    private func makeInventoryOrShopButtons(isShopButtons: Bool) -> [UIView] {
        let figuresButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: FiguresThemes.allCases, backgroundImage: UIImage(named: "misc/figuresBG"), buttonText: "Figures")
        let backgroundButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: Backgrounds.allCases, backgroundImage: UIImage(named: "misc/defaultBG"), buttonText: "Background")
        let titleButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: isShopButtons ? Titles.purchachableTitles : Titles.allCases, backgroundImage: nil, buttonText: "Title")
        let boardButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: BoardThemes.allCases, backgroundImage: UIImage(named: "misc/boardBG"), buttonText: "Board")
        let frameButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: Frames.allCases, backgroundImage: UIImage(named: "misc/frameBG"), buttonText: "Frame")
        let squaresButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: SquaresThemes.allCases, backgroundImage: UIImage(named: "misc/squaresBG"), buttonText: "Squares")
        return [figuresButton, backgroundButton, titleButton, boardButton, frameButton, squaresButton]
    }
    
    private func makeInventoryOrShopButton(isShopButton: Bool, items: [Item], backgroundImage: UIImage?, buttonText: String) -> UIView {
        let button = makeMainMenuButtonView(with: backgroundImage, buttonImage: nil, buttontext: buttonText, and: #selector(makeListOfItems))
        button.layer.setValue(items, forKey: constants.keyForItems)
        button.layer.setValue(isShopButton, forKey: constants.keyForIsShopButton)
        return button
    }
    
    private func makeFiguresView(figuresThemes: [FiguresThemes], isShopButtons: Bool) -> [UIView] {
        var figuresViews = [UIView]()
        for figuresTheme in figuresThemes {
            let figuresStack = UIStackView()
            figuresStack.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
            for figureName in Figures.allCases {
                for color in [GameColors.white, GameColors.black] {
                    let figureImage = UIImage(named: "figuresThemes/\(figuresTheme.rawValue)/\(color.rawValue)_\(figureName.rawValue)")
                    let figureView = makeSquareView(with: figureImage)
                    figuresStack.addArrangedSubview(figureView)
                }
            }
            let inInventory = currentUser.availableItems.contains(where: {$0 as? FiguresThemes == figuresTheme})
            let figuresThemeView = makeShowcase(items: figuresStack, item: figuresTheme, inInventory: inInventory, axis: .vertical, isShopButton: isShopButtons)
            figuresViews.append(figuresThemeView)
        }
        return figuresViews
    }
    
    private func makeBoardThemesView(boardThemes: [BoardThemes], isShopButtons: Bool) -> [UIView] {
        var boardThemesViews = [UIView]()
        for boardTheme in boardThemes {
            let boardItems = UIStackView()
            boardItems.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
            let emptySquare = makeSquareView(with: UIImage(named: "boardThemes/\(boardTheme.rawValue)/letter"))
            boardItems.addArrangedSubview(emptySquare)
            for file in BoardFiles.allCases {
                let fileImage = UIImage(named: "boardThemes/\(boardTheme.rawValue)/letter_\(file.rawValue)")
                let fileView = makeSquareView(with: fileImage)
                boardItems.addArrangedSubview(fileView)
            }
            for number in GameBoard.availableRows {
                let emptySquareImage = UIImage(named: "boardThemes/\(boardTheme.rawValue)/letter")
                let numberImage = UIImage(named: "boardThemes/\(boardTheme.rawValue)/number_\(number)")
                let numberSquare = makeSpecialSquareView(with: emptySquareImage, and: numberImage)
                boardItems.addArrangedSubview(numberSquare)
            }
            let inInventory = currentUser.availableItems.contains(where: {$0 as? BoardThemes == boardTheme})
            let boardThemeView = makeShowcase(items: boardItems, item: boardTheme, inInventory: inInventory, axis: .vertical, isShopButton: isShopButtons)
            boardThemesViews.append(boardThemeView)
        }
        return boardThemesViews
    }
    
    private func makeBackgroundThemesView(backgroundThemes: [Backgrounds], isShopButtons: Bool) -> [UIView] {
        var backgroundThemesViews = [UIView]()
        for backgroundTheme in backgroundThemes {
            let backgroundView = UIImageView()
            backgroundView.defaultSettings()
            backgroundView.image = UIImage(named: "backgrounds/\(backgroundTheme)")
            let backgroundLabel = UILabel()
            backgroundLabel.setup(text: backgroundTheme.rawValue.replacingOccurrences(of: "_", with: " ").capitalizingFirstLetter(), alignment: .center, font: defaultFont)
            backgroundView.addSubview(backgroundLabel)
            backgroundLabel.backgroundColor = backgroundView.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
            let backgroundLabelConstraints = [backgroundLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor), backgroundLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor), backgroundLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor), backgroundLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)]
            NSLayoutConstraint.activate(backgroundLabelConstraints)
            let inInventory = currentUser.availableItems.contains(where: {$0 as? Backgrounds == backgroundTheme})
            let backgroundThemeView = isShopButtons ? makeShopItemButton(with: backgroundView, shopItem: backgroundTheme, inInventory: inInventory) : makeInventoryItemButton(with: backgroundView, inventoryItem: backgroundTheme, inInventory: inInventory)
            backgroundThemesViews.append(backgroundThemeView)
        }
        return backgroundThemesViews
    }
    
    private func makeTitlesView(titles: [Titles], isShopButtons: Bool) -> [UIView] {
        var titlesViews = [UIView]()
        for title in titles {
            let titleLabel = UILabel()
            titleLabel.setup(text: title.rawValue.replacingOccurrences(of: "_", with: " ").capitalizingFirstLetter(), alignment: .center, font: defaultFont)
            let inInventory = currentUser.availableItems.contains(where: {$0 as? Titles == title})
            let titleView = isShopButtons ? makeShopItemButton(with: titleLabel, shopItem: title, inInventory: inInventory) : makeInventoryItemButton(with: titleLabel, inventoryItem: title, inInventory: inInventory)
            titlesViews.append(titleView)
        }
        return titlesViews
    }
    
    private func makeFramesView(frames: [Frames], isShopButtons: Bool) -> [UIView] {
        var framesViews = [UIView]()
        for frame in frames {
            let frameLabel = UILabel()
            frameLabel.setup(text: frame.rawValue.replacingOccurrences(of: "_", with: " ").capitalizingFirstLetter(), alignment: .center, font: defaultFont)
            let frameView = PlayerFrame(background: currentUser.playerBackground, playerFrame: frame, data: frameLabel)
            let inInventory = currentUser.availableItems.contains(where: {$0 as? Frames == frame})
            let itemView = isShopButtons ? makeShopItemButton(with: frameView, shopItem: frame, inInventory: inInventory) : makeInventoryItemButton(with: frameView, inventoryItem: frame, inInventory: inInventory)
            framesViews.append(itemView)
        }
        return framesViews
    }
    
    private func makeSquaresThemesView(squaresThemes: [SquaresThemes], isShopButtons: Bool) -> [UIView] {
        var squaresThemesView = [UIView]()
        for squaresThemeName in squaresThemes {
            let squareTheme = squaresThemeName.getTheme()
            let dataStack = UIStackView()
            dataStack.setup(axis: .vertical, alignment: .fill, distribution: .fill, spacing: constants.optimalSpacing)
            dataStack.addArrangedSubview(makeColorData(text: "First Color", color: squareTheme.firstColor))
            dataStack.addArrangedSubview(makeColorData(text: "Second Color", color: squareTheme.secondColor))
            dataStack.addArrangedSubview(makeColorData(text: "Turn Color", color: squareTheme.turnColor))
            dataStack.addArrangedSubview(makeColorData(text: "Available squares Color", color: squareTheme.availableSquaresColor))
            dataStack.addArrangedSubview(makeColorData(text: "Pick Color", color: squareTheme.pickColor))
            dataStack.addArrangedSubview(makeColorData(text: "Check Color", color: squareTheme.checkColor))
            let inInventory = currentUser.availableItems.contains(where: {$0 as? SquaresThemes == squaresThemeName})
            let itemView = makeShowcase(items: dataStack, item: squaresThemeName, inInventory: inInventory, axis: .horizontal, isShopButton: isShopButtons)
            squaresThemesView.append(itemView)
        }
        return squaresThemesView
    }
    
    private func makeSquareView(with image: UIImage?) -> UIView {
        let squareView = UIImageView()
        squareView.translatesAutoresizingMaskIntoConstraints = false
        squareView.image = image
        let squareViewConstraints = [squareView.widthAnchor.constraint(equalTo: squareView.heightAnchor)]
        NSLayoutConstraint.activate(squareViewConstraints)
        return squareView
    }
    
    //in case if square and element in square is 2 different images
    //right now only used for gameBoard showcase, cuz default numbers is not part of square image
    private func makeSpecialSquareView(with firstImage: UIImage?, and secondImage: UIImage?) -> UIView {
        let firstView = makeSquareView(with: firstImage)
        let secondView = makeSquareView(with: secondImage)
        firstView.addSubview(secondView)
        let secondViewConstraints = [secondView.centerXAnchor.constraint(equalTo: firstView.centerXAnchor), secondView.centerYAnchor.constraint(equalTo: firstView.centerYAnchor), secondView.widthAnchor.constraint(equalTo: firstView.widthAnchor, multiplier: constants.multiplierForSpecialSquareViewSize), secondView.heightAnchor.constraint(equalTo: firstView.heightAnchor, multiplier: constants.multiplierForSpecialSquareViewSize)]
        NSLayoutConstraint.activate(secondViewConstraints)
        return firstView
    }
    
    private func makeAdditionalButtonsForShopOrInventory(isShopButtons: Bool) {
        let coinsView = UIImageView()
        coinsView.defaultSettings()
        coinsView.settingsForBackgroundOfTheButton(cornerRadius: constants.cornerRadiusForButton)
        coinsView.image = UIImage(named: "misc/coinsBG")
        coinsText.setup(text: String(currentUser.coins), alignment: .center, font: defaultFont)
        coinsText.backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        coinsView.addSubview(coinsText)
        let coinsTextConstraints = [coinsText.topAnchor.constraint(equalTo: coinsView.topAnchor), coinsText.bottomAnchor.constraint(equalTo: coinsView.bottomAnchor), coinsText.leadingAnchor.constraint(equalTo: coinsView.leadingAnchor), coinsText.trailingAnchor.constraint(equalTo: coinsView.trailingAnchor)]
        NSLayoutConstraint.activate(coinsTextConstraints)
        let backButton = makeMainMenuButtonView(with: UIImage(systemName: "arrow.left"), buttonImage: nil, buttontext: "Back", and: isShopButtons ? #selector(makeShopMenu) : #selector(makeInventoryMenu))
        makeAdditionalButtons(with: [backButton, coinsView])
    }
    
    private func makeAdditionalButtons(with views: [UIView]) {
        additionalButtons = UIStackView()
        additionalButtons.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        additionalButtons.addArrangedSubviews(views)
        view.addSubview(additionalButtons)
        let additionalButtonsConstraints = [additionalButtons.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor), additionalButtons.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor), additionalButtons.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)]
        NSLayoutConstraint.activate(additionalButtonsConstraints)
    }
    
    private func updateItemsColor(inShop: Bool) {
        for button in buttonsStack.arrangedSubviews {
            if let shopItem = button.layer.value(forKey: constants.keyForItem) as? Item {
                var inInventory = false
                var chosen = false
                let available = shopItem.cost < currentUser.coins
                switch shopItem.type {
                case .squaresTheme:
                    if let squaresTheme = shopItem as? SquaresThemes {
                        inInventory = currentUser.availableItems.contains(where: {$0 as? SquaresThemes == squaresTheme})
                        chosen = squaresTheme == currentUser.squaresTheme
                    }
                case .figuresTheme:
                    if let figuresTheme = shopItem as? FiguresThemes {
                        inInventory = currentUser.availableItems.contains(where: {$0 as? FiguresThemes == figuresTheme})
                        chosen = figuresTheme == currentUser.figuresTheme
                    }
                case .boardTheme:
                    if let boardTheme = shopItem as? BoardThemes {
                        inInventory = currentUser.availableItems.contains(where: {$0 as? BoardThemes == boardTheme})
                        chosen = boardTheme == currentUser.boardTheme
                    }
                case .frame:
                    if let frame = shopItem as? Frames {
                        inInventory = currentUser.availableItems.contains(where: {$0 as? Frames == frame})
                        chosen = frame == currentUser.frame
                    }
                case .background:
                    if let background = shopItem as? Backgrounds {
                        inInventory = currentUser.availableItems.contains(where: {$0 as? Backgrounds == background})
                        chosen = background == currentUser.playerBackground
                    }
                case .title:
                    if let title = shopItem as? Titles {
                        inInventory = currentUser.availableItems.contains(where: {$0 as? Titles == title})
                        chosen = title == currentUser.title
                    }
                case .avatar:
                    if let avatar = shopItem as? Avatars {
                        inInventory = currentUser.availableItems.contains(where: {$0 as? Avatars == avatar})
                        chosen = avatar == currentUser.playerAvatar
                    }
                }
                var color = defaultBackgroundColor
                let textColor = defaultTextColor
                var isEnabled = false
                if inShop {
                    if inInventory {
                        color = constants.inInventoryColor
                    }
                    else if !available {
                        color = constants.notAvailableColor
                    }
                    isEnabled = !inInventory && available
                }
                else {
                    if chosen {
                        color = constants.chosenItemColor
                    }
                    else if !inInventory {
                        color = constants.notAvailableColor
                    }
                    isEnabled = inInventory && !chosen
                }
                UIView.animate(withDuration: constants.animationDuration, animations: {
                    button.backgroundColor = color
                    button.subviews.first?.subviews.first?.backgroundColor = color
                    (button.subviews.first?.subviews.first as? UIButton)?.isEnabled = isEnabled
                    if inShop && !isEnabled {
                        (button.subviews.first?.subviews.first as? UIButton)?.setTitleColor(textColor, for: .normal)
                    }
                })
            }
        }
    }
    
    private func addNotificationIconTo(view: UIView) {
        let notificationView = UIImageView()
        notificationView.defaultSettings()
        notificationView.settingsForBackgroundOfTheButton(cornerRadius: constants.cornerRadiusForButton)
        notificationView.isUserInteractionEnabled = false
        notificationView.backgroundColor = constants.notificationIconBackgroundColor
        //we are doing it like so, cuz superview could have masksToBounds = true and in that case
        //notification icon will be showed improperly
        notificationView.layer.setValue(view, forKey: constants.keyForParentView)
        view.superview?.addSubview(notificationView)
        let notificationViewConstraints = [notificationView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: constants.sizeMultiplierForNotificationIcon), notificationView.widthAnchor.constraint(equalTo: notificationView.heightAnchor), notificationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: constants.optimalDistance), notificationView.topAnchor.constraint(equalTo: view.topAnchor, constant: -constants.optimalDistance)]
        NSLayoutConstraint.activate(notificationViewConstraints)
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
    static let keyForIsShopButton = "isShopButton"
    static let keyForItems = "Items"
    static let keyForItem = "Item"
    static let keyForParentView = "parentView"
    static let chosenItemColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let inInventoryColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let notAvailableColor = UIColor.red.withAlphaComponent(optimalAlpha)
    static let transformForShopItemWhenBought = CGAffineTransform(scaleX: 0.01, y: 0.01)
    static let insetsForCircleButton = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    static let multiplierForAdditionalButtonsSizeInMainMenuButton = 0.3
    static let distanceForContentInHorizontalShowcase = 20.0
    static let multiplierForSpecialSquareViewSize = 0.6
    static let sizeMultiplierForNotificationIcon = 0.5
    static let pickItemBorderColor = UIColor.yellow.cgColor
    static let notificationIconBackgroundColor = UIColor.red
    
    static func convertLogicColor(_ color: Colors) -> UIColor {
        switch color {
        case .white:
            return .white
        case .black:
            return .black
        case .blue:
            return .blue
        case .orange:
            return .orange
        case .red:
            return .red
        case .green:
            return .green
        }
    }
}

// MARK: - CustomScrollView

//allows to scroll buttons, which have isExclusiveTouch set to true and/or if user holds them
class CustomScrollView: UIScrollView {
    
    override func touchesShouldCancel(in view: UIView) -> Bool {
        true
    }
    
}
