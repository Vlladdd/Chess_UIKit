//
//  MainMenuVC.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.09.2022.
//

import UIKit

//VC that represents main menu view
class MainMenuVC: UIViewController, WSManagerDelegate {
    
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
        for subview in buttonsStack.arrangedSubviews {
            randomAnimationFor(view: subview)
        }
        if let additionalButtons = view.subviews.first(where: {$0 == additionalButtons}) {
            randomAnimationFor(view: additionalButtons)
        }
        randomAnimationFor(view: userDataView)
        audioPlayer.playSound(Sounds.moveSound2)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if presentedViewController == nil {
            for button in buttonsStack.arrangedSubviews {
                if let viewWithNotif = button as? ViewWithNotifIcon {
                    if let frame = viewWithNotif.mainView.subviews.first(where: {$0 as? PlayerFrame != nil}) {
                        frame.setNeedsDisplay()
                    }
                }
                else {
                    if let frame = button.subviews.first(where: {$0 as? PlayerFrame != nil}) {
                        frame.setNeedsDisplay()
                    }
                }
            }
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
    
    // MARK: - Buttons Methods
    
    @objc private func signOut(_ sender: UIButton? = nil) {
        let exitAlert = UIAlertController(title: "Exit", message: "Are you sure?", preferredStyle: .alert)
        exitAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            if let self = self {
                self.storage.signOut()
                if self.presentedViewController != nil {
                    self.dismiss(animated: true) {
                        self.dismiss(animated: true)
                    }
                }
                else {
                    self.dismiss(animated: true)
                }
                self.audioPlayer.playSound(Sounds.closePopUpSound)
            }
        }))
        exitAlert.addAction(UIAlertAction(title: "No", style: .cancel))
        UIApplication.getTopMostViewController()?.present(exitAlert, animated: true)
        audioPlayer.playSound(Sounds.openPopUpSound)
    }
    
    @objc private func makeGameMenu(_ sender: UIButton? = nil) {
        storage.removeMultiplayerGamesObservers()
        let createButton = makeMainMenuButtonView(with: MiscImages.createButtonBG, buttonImageItem: nil, buttontext: "Create", and: #selector(showCreateGameVC))
        let joinButton = makeMainMenuButtonView(with: MiscImages.joinButtonBG, buttonImageItem: nil, buttontext: "Join", and: #selector(makeMultiplayerGamesList))
        let loadButton = makeMainMenuButtonView(with: MiscImages.loadButtonBG, buttonImageItem: nil, buttontext: "Load", and: #selector(makeUserGamesList))
        if storage.currentUser.guestMode {
            (joinButton.subviews.first as! UIButton).isEnabled = false
        }
        updateButtonsStack(with: [createButton, joinButton, loadButton], addBackButton: true, distribution: .fillEqually)
        animateButtonsStack()
    }
    
    @objc private func makeInventoryMenu(_ sender: UIButton? = nil) {
        updateButtonsStack(with: makeInventoryOrShopButtons(isShopButtons: false), addBackButton: true, distribution: .fillEqually)
        animateButtonsStack()
    }
    
    @objc private func makeShopMenu(_ sender: UIButton? = nil) {
        updateButtonsStack(with: makeInventoryOrShopButtons(isShopButtons: true), addBackButton: true, distribution: .fillEqually)
        animateButtonsStack()
    }
    
    //for inventory or shop
    @objc private func makeListOfItems(_ sender: UIButton? = nil) {
        var buttons = [UIView]()
        if let sender = sender {
            if let isShopButtons = sender.superview?.layer.value(forKey: constants.keyForIsShopButton) as? Bool {
                if let items = sender.superview?.layer.value(forKey: constants.keyForItems) as? [GameItem], items.count > 0 {
                    switch items.first!.type {
                    case .squaresThemes:
                        if let squaresThemes = sender.superview?.layer.value(forKey: constants.keyForItems) as? [SquaresThemes] {
                            buttons = makeSquaresThemesView(squaresThemes: squaresThemes, isShopButtons: isShopButtons)
                        }
                    case .figuresThemes:
                        if let figuresThemes = sender.superview?.layer.value(forKey: constants.keyForItems) as? [FiguresThemes] {
                            buttons = makeFiguresView(figuresThemes: figuresThemes, isShopButtons: isShopButtons)
                        }
                    case .boardThemes:
                        if let boardThemes = sender.superview?.layer.value(forKey: constants.keyForItems) as? [BoardThemes] {
                            buttons = makeBoardThemesView(boardThemes: boardThemes, isShopButtons: isShopButtons)
                        }
                    case .frames:
                        if let frames = sender.superview?.layer.value(forKey: constants.keyForItems) as? [Frames] {
                            buttons = makeFramesView(frames: frames, isShopButtons: isShopButtons)
                        }
                    case .backgrounds:
                        if let backgroundThemes = sender.superview?.layer.value(forKey: constants.keyForItems) as? [Backgrounds] {
                            buttons = makeBackgroundThemesView(backgroundThemes: backgroundThemes, isShopButtons: isShopButtons)
                        }
                    case .titles:
                        if let titles = sender.superview?.layer.value(forKey: constants.keyForItems) as? [Titles] {
                            buttons = makeTitlesView(titles: titles, isShopButtons: isShopButtons)
                        }
                    case .avatars:
                        if let avatars = sender.superview?.layer.value(forKey: constants.keyForItems) as? [Avatars] {
                            buttons = makeAvatarsViews(avatars: avatars)
                        }
                    }
                    updateButtonsStack(with: buttons, addBackButton: false, distribution: .fillEqually)
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
            if let item = sender.superview?.superview?.layer.value(forKey: constants.keyForItem) as? GameItem {
                audioPlayer.playSound(Sounds.chooseItemSound)
                storage.currentUser.setValue(with: item)
                updateItemsColor(inShop: false)
            }
        }
    }
    
    //highlight picked item and remove notification icon from him
    @objc private func pickitem(_ sender: UITapGestureRecognizer? = nil) {
        if let sender = sender {
            if let mainMenuButton = sender.view?.superview {
                if let item = mainMenuButton.layer.value(forKey: constants.keyForItem) as? GameItem {
                    audioPlayer.playSound(Sounds.pickItemSound)
                    storage.currentUser.addSeenItem(item)
                    for button in buttonsStack.arrangedSubviews {
                        if let viewWithNotif = button as? ViewWithNotifIcon {
                            viewWithNotif.mainView.layer.borderColor = defaultTextColor.cgColor
                        }
                        else {
                            button.layer.borderColor = defaultTextColor.cgColor
                        }
                    }
                    mainMenuButton.layer.borderColor = constants.pickItemBorderColor
                    if let viewWithNotif = mainMenuButton.superview as? ViewWithNotifIcon {
                        viewWithNotif.removeNotificationIcon()
                    }
                    removeNotificationIconsIfNeeded()
                    if let frame = sender.view as? PlayerFrame {
                        frame.setNeedsDisplay()
                    }
                    if let userProfileVC = presentedViewController as? UserProfileVC {
                        userProfileVC.removeNotificationIconsIfNeeded()
                    }
                }
            }
        }
    }
    
    @objc private func showDescriptionForItemInInventory(_ sender: UIButton? = nil) {
        if let mainMenuButton = sender?.superview?.superview {
            audioPlayer.playSound(Sounds.toggleSound)
            let descriptionView = mainMenuButton.subviews[3]
            let newAlpha: CGFloat = descriptionView.alpha == 0 ? 1 : 0
            UIView.animate(withDuration: constants.animationDuration, animations: {
                descriptionView.alpha = newAlpha
            })
        }
    }
    
    @objc private func buyItem(_ sender: UIButton? = nil) {
        if let mainMenuButton = sender?.superview?.superview {
            if let item = mainMenuButton.layer.value(forKey: constants.keyForItem) as? GameItem {
                let itemName = item.getHumanReadableName()
                let alert = UIAlertController(title: "Buy \(itemName)", message: "Are you sure?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {[weak self] _ in
                    if let self = self {
                        self.audioPlayer.playSound(Sounds.buyItemSound)
                        self.storage.currentUser.addAvailableItem(item)
                        var startCoins = self.storage.currentUser.coins
                        self.storage.currentUser.addCoins(-item.cost)
                        let endCoins = self.storage.currentUser.coins
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
                        let timer = Timer(timeInterval: interval, repeats: true, block: { timer in
                            if startCoins == endCoins {
                                timer.invalidate()
                                return
                            }
                            startCoins -= 1
                            self.coinsText.text = String(startCoins)
                        })
                        timer.fire()
                        RunLoop.main.add(timer, forMode: .common)
                    }
                }))
                present(alert, animated: true)
                audioPlayer.playSound(Sounds.openPopUpSound)
            }
        }
    }
    
    @objc private func makeMainMenu(_ sender: UIButton? = nil) {
        let haveNewInventoryItem = storage.currentUser.haveNewItemsInInventory()
        let haveNewShopItem = storage.currentUser.haveNewItemsInShop()
        let gameButton = makeMainMenuButtonView(with: MiscImages.gameButtonBG, buttonImageItem: nil, buttontext: "Game", and: #selector(makeGameMenu))
        let inventoryButton = makeMainMenuButtonView(with: MiscImages.inventoryButtonBG, buttonImageItem: nil, buttontext: "Inventory", and: #selector(makeInventoryMenu), addNotificationIcon: haveNewInventoryItem)
        let shopButton = makeMainMenuButtonView(with: MiscImages.shopButtonBG, buttonImageItem: nil, buttontext: "Shop", and: #selector(makeShopMenu), addNotificationIcon: haveNewShopItem)
        updateButtonsStack(with: [gameButton, inventoryButton, shopButton], addBackButton: false, distribution: .fillEqually)
        animateButtonsStack(reversed: true)
    }
    
    //shows view for game creation
    @objc private func showCreateGameVC(_ sender: UIButton? = nil) {
        if (presentedViewController as? CreateGameVC) == nil {
            if let presentedViewController = presentedViewController {
                presentedViewController.dismiss(animated: true) {[weak self] in
                    self?.makeCreateGameVC()
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
    
    //shows view for redacting user profile
    @objc private func showUserProfileVC(_ sender: UITapGestureRecognizer? = nil) {
        if (presentedViewController as? UserProfileVC) == nil {
            if let presentedViewController = presentedViewController {
                presentedViewController.dismiss(animated: true) {[weak self] in
                    self?.makeUserProfileVC()
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
    
    //creates games for load, if they ended or in oneScreen mode
    @objc private func makeUserGamesList(_ sender: UIButton? = nil) {
        makeGamesList(with: storage.currentUser.games)
    }
    
    @objc private func makeMultiplayerGamesList(_ sender: UIButton? = nil) {
        var firstTime = true
        sender?.isEnabled = false
        storage.getMultiplayerGames(callback: { [weak self] error, games in
            if let self = self {
                sender?.isEnabled = true
                guard error == nil else {
                    self.makeErrorAlert(with: error!.localizedDescription)
                    self.makeGameMenu()
                    return
                }
                if let games = games {
                    if firstTime {
                        firstTime = false
                        self.makeGamesList(with: games)
                    }
                    else {
                        self.updateMultiplayerGamesList(with: games)
                    }
                }
                else {
                    self.makeErrorAlert(with: "No games available")
                    self.makeGameMenu()
                }
            }
        })
    }
    
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
                            audioPlayer.playSound(Sounds.moveSound2)
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
                if game.gameMode == .multiplayer && !game.gameEnded {
                    //if gameMode == .multiplayer, there is no way for wsManager to be nil
                    if wsManager!.connectedToWSServer && presentedViewController == nil {
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
                        makeErrorAlert(with: "You are not connected to the server, will try to reconnect")
                        wsManager?.connectToWebSocketServer()
                        return
                    }
                    else {
                        makeErrorAlert(with: "Close the pop-up window")
                        return
                    }
                    makeGameMenu()
                }
                audioPlayer.pauseSound(Music.menuBackgroundMusic)
                audioPlayer.playSound(Sounds.successSound)
                if let presentedViewController = presentedViewController {
                    presentedViewController.dismiss(animated: true) {[weak self] in
                        self?.makeGameVC(with: game)
                    }
                }
                else {
                    makeGameVC(with: game)
                }
                storage.removeMultiplayerGamesObservers()
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
                        self.storage.currentUser.removeGame(game)
                        if let gameInfo = sender.superview?.superview?.superview {
                            UIView.animate(withDuration: constants.animationDuration, animations: {
                                gameInfo.isHidden = true
                            }) { _ in
                                gameInfo.removeFromSuperview()
                            }
                            self.audioPlayer.playSound(Sounds.removeSound)
                        }
                    }
                }
            }
        }))
        present(alert, animated: true)
        audioPlayer.playSound(Sounds.openPopUpSound)
    }
    
    // MARK: - Local Methods
    
    private func makeGamesList(with games: [GameLogic]) {
        let backButton = makeMainMenuButtonView(with: SystemImages.backImage, buttonImageItem: nil, buttontext: "Back", and: #selector(makeGameMenu))
        makeAdditionalButtons(with: [backButton])
        updateButtonsStack(with: games.sorted(by: {$0.startDate > $1.startDate}).map({makeInfoView(of: $0)}), addBackButton: false, distribution: .fill)
        animateButtonsStack(reversed: Bool.random(), addAdditionalButtons: true)
    }
    
    private func updateMultiplayerGamesList(with games: [GameLogic]) {
        for button in buttonsStack.arrangedSubviews {
            let loadButton = button.subviews[3].subviews.last!.subviews.last!
            if let game = loadButton.layer.value(forKey: constants.keyForGame) as? GameLogic {
                if !games.contains(where: {$0.gameID == game.gameID}) {
                    UIView.animate(withDuration: constants.animationDuration, animations: {
                        button.isHidden = true
                    }) { _ in
                        button.removeFromSuperview()
                    }
                }
            }
        }
        for game in games {
            if !buttonsStack.arrangedSubviews.contains(where: {
                let loadButton = $0.subviews[3].subviews.last!.subviews.last!
                if let gameToCompare = loadButton.layer.value(forKey: constants.keyForGame) as? GameLogic {
                    return gameToCompare.gameID == game.gameID
                }
                return false
            }) {
                buttonsStack.addArrangedSubview(makeInfoView(of: game))
                UIView.animate(withDuration: constants.animationDuration, animations: { [weak self] in
                    self?.view.layoutIfNeeded()
                })
            }
        }
    }
    
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
    
    private func makeErrorAlert(with message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        if let topVC = UIApplication.getTopMostViewController(), topVC as? GameViewController == nil && topVC as? UIAlertController == nil {
            topVC.present(alert, animated: true)
            audioPlayer.playSound(Sounds.errorSound)
        }
    }
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private lazy var fontSize = min(view.frame.width, view.frame.height) / constants.dividerForFont
    private lazy var defaultFont = UIFont.systemFont(ofSize: fontSize)
    private lazy var defaultBackgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
    private lazy var defaultTextColor = traitCollection.userInterfaceStyle == .dark ? constants.lightModeTextColor : constants.darkModeTextColor
    
    private var buttonsStack = UIStackView()
    //there is a bug, when animating scrollView, which leads to weird jump of first arrangedSubview subviews of buttonsStack
    //by putting scrollView inside a view, we are fixing this bug
    //other approach is to simply call view.setNeedsLayout() and view.layoutIfNeeded(), but that will also affect backButton,
    //which i don`t want to
    private var viewForScrollView = UIView()
    private var scrollViewContent = UIView()
    private var additionalButtons = UIStackView()
    private var userDataView = ViewWithNotifIcon()
    
    private let coinsText = UILabel()
    
    // MARK: - UI Methods
    
    private func makeUI() {
        view.backgroundColor = defaultBackgroundColor
        makeBackground()
        makeUserData()
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
        let centerXForViewForScrollView = viewForScrollView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor)
        centerXForViewForScrollView.priority = .defaultLow
        let centerYForViewForScrollView = viewForScrollView.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor)
        centerYForViewForScrollView.priority = .defaultLow
        let viewForScrollViewConstraints = [viewForScrollView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor), viewForScrollView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor), viewForScrollView.topAnchor.constraint(greaterThanOrEqualTo: userDataView.bottomAnchor), centerXForViewForScrollView, centerYForViewForScrollView, viewForScrollViewBottomConstraint]
        let scrollViewConstraints = [scrollView.leadingAnchor.constraint(equalTo: viewForScrollView.leadingAnchor), scrollView.trailingAnchor.constraint(equalTo: viewForScrollView.trailingAnchor), scrollView.topAnchor.constraint(equalTo: viewForScrollView.topAnchor), scrollView.bottomAnchor.constraint(equalTo: viewForScrollView.bottomAnchor)]
        let contentConstraints = [scrollViewContent.topAnchor.constraint(equalTo: scrollView.topAnchor), scrollViewContent.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor), scrollViewContent.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor), scrollViewContent.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor), scrollViewContent.widthAnchor.constraint(equalTo: scrollView.widthAnchor), contentHeight]
        NSLayoutConstraint.activate(viewForScrollViewConstraints + scrollViewConstraints + contentConstraints)
    }
    
    //makes background of the view
    private func makeBackground() {
        let background = UIImageView()
        background.translatesAutoresizingMaskIntoConstraints = false
        background.setImage(with: MiscImages.defaultBG)
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
        audioPlayer.playSound(Sounds.moveSound1)
    }
    
    //makes big round buttons to navigate through main menu
    private func makeMainMenuButtonView(with backgroundImageItem: ImageItem?, buttonImageItem: ImageItem?, buttontext: String, and action: Selector?, addNotificationIcon: Bool = false, needHeightConstraint: Bool = true) -> UIImageView {
        let buttonBG = UIImageView()
        buttonBG.defaultSettings()
        buttonBG.settingsForBackgroundOfTheButton(cornerRadius: fontSize * constants.multiplierForButtonSize / constants.optimalDividerForCornerRadius)
        if let backgroundImageItem {
            buttonBG.setImage(with: backgroundImageItem)
        }
        var buttonConstraints = [NSLayoutConstraint]()
        if let action = action {
            let button = MainMenuButton(type: .system)
            button.buttonWith(imageItem: buttonImageItem, text: buttontext, font: defaultFont, and: action)
            buttonBG.addSubview(button)
            buttonConstraints += [button.widthAnchor.constraint(equalTo: buttonBG.widthAnchor), button.heightAnchor.constraint(equalTo: buttonBG.heightAnchor), button.centerXAnchor.constraint(equalTo: buttonBG.centerXAnchor), button.centerYAnchor.constraint(equalTo: buttonBG.centerYAnchor)]
            if buttonImageItem != nil {
                button.contentEdgeInsets = constants.insetsForCircleButton
            }
        }
        if needHeightConstraint && !addNotificationIcon {
            buttonConstraints.append(buttonBG.heightAnchor.constraint(equalToConstant: fontSize * constants.multiplierForButtonSize))
        }
        var buttonView: ViewWithNotifIcon?
        if addNotificationIcon {
            buttonView = ViewWithNotifIcon(mainView: buttonBG, cornerRadius: fontSize * constants.multiplierForButtonSize / constants.optimalDividerForCornerRadius)
            if needHeightConstraint {
                buttonConstraints.append(buttonView!.heightAnchor.constraint(equalToConstant: fontSize * constants.multiplierForButtonSize))
            }
        }
        NSLayoutConstraint.activate(buttonConstraints)
        return buttonView ?? buttonBG
    }
    
    //creates view with basic and additional info about game
    private func makeInfoView(of game: GameLogic) -> UIImageView {
        let infoView = UIImageView()
        infoView.defaultSettings()
        infoView.settingsForBackgroundOfTheButton(cornerRadius: fontSize * constants.multiplierForButtonSize / constants.optimalDividerForCornerRadius)
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
            if game.winner?.user.nickname == storage.currentUser.nickname {
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
        let firstPlayerPointsSign = game.players.first?.pointsForGame ?? -1 > 0 ? "+" : ""
        let secondPlayerPointsSign = game.players.second?.pointsForGame ?? -1 > 0 ? "+" : ""
        var gameInfoText = game.players.first!.user.nickname + " " + String(game.players.first!.user.points) + "(" + firstPlayerPointsSign
        gameInfoText += String(game.players.first!.pointsForGame) + ")" + " " + "vs "
        if let secondPlayer = game.players.second {
            gameInfoText += secondPlayer.user.nickname + " " + String(secondPlayer.user.points)
            gameInfoText += "(" + secondPlayerPointsSign + String(secondPlayer.pointsForGame) + ")"
        }
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
        deleteButton.buttonWith(imageItem: SystemImages.deleteImage, and: #selector(deleteGame))
        deleteButton.isEnabled = game.gameMode == .oneScreen || game.gameEnded
        let expandButton = UIButton()
        expandButton.buttonWith(imageItem: SystemImages.expandImage, and: #selector(toggleGameInfo))
        let enterButton = UIButton()
        enterButton.buttonWith(imageItem: SystemImages.enterImage, and: #selector(loadGame))
        enterButton.layer.setValue(game, forKey: constants.keyForGame)
        deleteButton.layer.setValue(game, forKey: constants.keyForGame)
        helperButtonsStack.addArrangedSubviews([deleteButton, expandButton, enterButton])
        helperButtonsView.addSubview(helperButtonsStack)
        let helperButtonsStackConstraints = [helperButtonsStack.centerXAnchor.constraint(equalTo: helperButtonsView.centerXAnchor), helperButtonsStack.centerYAnchor.constraint(equalTo: helperButtonsView.centerYAnchor), deleteButton.widthAnchor.constraint(equalTo: deleteButton.heightAnchor), helperButtonsStack.heightAnchor.constraint(equalTo: helperButtonsView.heightAnchor, multiplier: constants.sizeMultiplayerForHelperButtonsStack)]
        NSLayoutConstraint.activate(helperButtonsStackConstraints)
        return helperButtonsView
    }
    
    private func updateButtonsStack(with views: [UIView], addBackButton: Bool, distribution: UIStackView.Distribution) {
        buttonsStack = UIStackView()
        buttonsStack.setup(axis: .vertical, alignment: .fill, distribution: distribution, spacing: constants.optimalSpacing)
        buttonsStack.addArrangedSubviews(views)
        if addBackButton {
            let backButton = makeMainMenuButtonView(with: nil, buttonImageItem: nil, buttontext: "Back", and: #selector(makeMainMenu))
            addBackButtonSFImageTo(view: backButton)
            buttonsStack.addArrangedSubview(backButton)
        }
    }
    
    private func makeShopItemButton(with view: UIView, shopItem: GameItem, inInventory: Bool) -> UIImageView {
        let addNotificationIcon = storage.currentUser.containsNewItemIn(items: [shopItem])
        let buttonView = makeMainMenuButtonView(with: nil, buttonImageItem: nil, buttontext: "", and: nil, addNotificationIcon: addNotificationIcon)
        let buttonBG = addNotificationIcon ? buttonView.subviews.first as! UIImageView : buttonView
        let buyButton = makeMainMenuButtonView(with: MiscImages.coinsBG, buttonImageItem: nil, buttontext: String(shopItem.cost), and: #selector(buyItem))
        buttonBG.addSubview(buyButton)
        buttonBG.addSubview(view)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pickitem))
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true
        let viewConstraints = [view.leadingAnchor.constraint(equalTo: buttonBG.leadingAnchor), view.trailingAnchor.constraint(equalTo: buyButton.leadingAnchor), view.topAnchor.constraint(equalTo: buttonBG.topAnchor), view.bottomAnchor.constraint(equalTo: buttonBG.bottomAnchor)]
        let buyButtonConstraints = [buyButton.trailingAnchor.constraint(equalTo: buttonBG.trailingAnchor), buyButton.widthAnchor.constraint(equalTo: buttonBG.widthAnchor, multiplier: constants.multiplierForAdditionalButtonsSizeInMainMenuButton), buyButton.centerYAnchor.constraint(equalTo: buttonBG.centerYAnchor)]
        NSLayoutConstraint.activate(buyButtonConstraints + viewConstraints)
        buttonBG.layer.setValue(shopItem, forKey: constants.keyForItem)
        return buttonBG.superview as? UIImageView ?? buttonBG
    }
    
    private func makeInventoryItemButton(with view: UIView, inventoryItem: GameItem, inInventory: Bool) -> UIImageView {
        let addNotificationIcon = storage.currentUser.containsNewItemIn(items: [inventoryItem])
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
        let itemDescriptionCenterX = itemDescription.centerXAnchor.constraint(equalTo: descriptionScrollView.centerXAnchor)
        itemDescriptionCenterX.priority = .defaultLow
        let itemDescriptionCenterY = itemDescription.centerYAnchor.constraint(equalTo: descriptionScrollView.centerYAnchor)
        itemDescriptionCenterY.priority = .defaultLow
        let buttonView = makeMainMenuButtonView(with: nil, buttonImageItem: nil, buttontext: "", and: nil, addNotificationIcon: addNotificationIcon)
        let buttonBG = addNotificationIcon ? buttonView.subviews.first as! UIImageView : buttonView
        let chooseButton = makeMainMenuButtonView(with: nil, buttonImageItem: SystemImages.chooseImage, buttontext: "", and: #selector(chooseItemInInventory), needHeightConstraint: false)
        let descriptionButton = makeMainMenuButtonView(with: nil, buttonImageItem: SystemImages.descriptionImage, buttontext: "", and: #selector(showDescriptionForItemInInventory), needHeightConstraint: false)
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
        let itemDescriptionConstraint = [itemDescription.leadingAnchor.constraint(equalTo: descriptionScrollView.leadingAnchor), itemDescription.trailingAnchor.constraint(equalTo: descriptionScrollView.trailingAnchor), itemDescription.topAnchor.constraint(equalTo: descriptionScrollView.topAnchor), itemDescription.bottomAnchor.constraint(equalTo: descriptionScrollView.bottomAnchor), itemDescription.widthAnchor.constraint(equalTo: descriptionScrollView.widthAnchor), itemDescriptionCenterX, itemDescriptionCenterY, descriptionHeightConstraint]
        let descriptionScrollViewConstraints = [descriptionScrollView.leadingAnchor.constraint(equalTo: buttonBG.leadingAnchor), descriptionScrollView.trailingAnchor.constraint(equalTo: chooseButton.leadingAnchor), descriptionScrollView.topAnchor.constraint(equalTo: buttonBG.topAnchor), descriptionScrollView.bottomAnchor.constraint(equalTo: buttonBG.bottomAnchor)]
        NSLayoutConstraint.activate(chooseButtonConstraints + viewConstraints + descriptionConstraints + itemDescriptionConstraint + descriptionScrollViewConstraints)
        return buttonBG.superview as? UIImageView ?? buttonBG
    }
    
    private func makeShowcase(items: UIStackView, item: GameItem, inInventory: Bool, axis: NSLayoutConstraint.Axis, isShopButton: Bool) -> UIImageView {
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
        let figuresButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: isShopButtons ? FiguresThemes.purchasable : FiguresThemes.allCases, backgroundImageItem: MiscImages.figuresButtonBG, buttonText: "Figures")
        let backgroundButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: isShopButtons ? Backgrounds.purchasable : Backgrounds.allCases, backgroundImageItem: storage.currentUser.playerBackground, buttonText: "Background")
        let titleButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: isShopButtons ? Titles.purchasable : Titles.allCases, backgroundImageItem: nil, buttonText: "Title")
        let boardButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: isShopButtons ? BoardThemes.purchasable : BoardThemes.allCases, backgroundImageItem: MiscImages.boardsButtonBG, buttonText: "Board")
        let frameButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: isShopButtons ? Frames.purchasable : Frames.allCases, backgroundImageItem: MiscImages.framesButtonBG, buttonText: "Frame")
        let squaresButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: isShopButtons ? SquaresThemes.purchasable : SquaresThemes.allCases, backgroundImageItem: MiscImages.squaresButtonBG, buttonText: "Squares")
        var buttons = [figuresButton, backgroundButton, titleButton, boardButton, frameButton, squaresButton]
        if isShopButtons {
            let avatarsButton = makeInventoryOrShopButton(isShopButton: isShopButtons, items: Avatars.purchasable, backgroundImageItem: storage.currentUser.playerAvatar, buttonText: "Avatars")
            buttons.append(avatarsButton)
        }
        return buttons
    }
    
    private func makeInventoryOrShopButton(isShopButton: Bool, items: [GameItem], backgroundImageItem: ImageItem?, buttonText: String) -> UIView {
        let addNotificationIcon = storage.currentUser.containsNewItemIn(items: items)
        let buttonView = makeMainMenuButtonView(with: backgroundImageItem, buttonImageItem: nil, buttontext: buttonText, and: #selector(makeListOfItems), addNotificationIcon: addNotificationIcon)
        let button = addNotificationIcon ? buttonView.subviews.first as! UIImageView : buttonView
        button.layer.setValue(items, forKey: constants.keyForItems)
        button.layer.setValue(isShopButton, forKey: constants.keyForIsShopButton)
        return button.superview ?? button
    }
    
    private func makeFiguresView(figuresThemes: [FiguresThemes], isShopButtons: Bool) -> [UIView] {
        var figuresViews = [UIView]()
        for figuresTheme in figuresThemes {
            let figuresStack = UIStackView()
            figuresStack.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
            for figureType in Figures.allCases {
                for color in [GameColors.white, GameColors.black] {
                    let figureView = makeSquareView(with: figuresTheme.getSkinedFigure(from: Figure(type: figureType, color: color)))
                    figuresStack.addArrangedSubview(figureView)
                }
            }
            let inInventory = storage.currentUser.availableItems.contains(where: {$0 as? FiguresThemes == figuresTheme})
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
            let emptySquare = makeSquareView(with: boardTheme.emptySquareItem)
            boardItems.addArrangedSubview(emptySquare)
            for file in BoardFiles.allCases {
                let fileView = makeSquareView(with: boardTheme.getSkinedLetter(from: file))
                boardItems.addArrangedSubview(fileView)
            }
            for number in BoardNumberItems.allCases {
                let numberSquare = makeSpecialSquareView(with: boardTheme.emptySquareItem, and: boardTheme.getSkinedNumber(from: number))
                boardItems.addArrangedSubview(numberSquare)
            }
            let inInventory = storage.currentUser.availableItems.contains(where: {$0 as? BoardThemes == boardTheme})
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
            backgroundView.setImage(with: backgroundTheme)
            let backgroundLabel = UILabel()
            backgroundLabel.setup(text: backgroundTheme.getHumanReadableName(), alignment: .center, font: defaultFont)
            backgroundView.addSubview(backgroundLabel)
            backgroundLabel.backgroundColor = backgroundView.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
            let backgroundLabelConstraints = [backgroundLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor), backgroundLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor), backgroundLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor), backgroundLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)]
            NSLayoutConstraint.activate(backgroundLabelConstraints)
            let inInventory = storage.currentUser.availableItems.contains(where: {$0 as? Backgrounds == backgroundTheme})
            let backgroundThemeView = isShopButtons ? makeShopItemButton(with: backgroundView, shopItem: backgroundTheme, inInventory: inInventory) : makeInventoryItemButton(with: backgroundView, inventoryItem: backgroundTheme, inInventory: inInventory)
            backgroundThemesViews.append(backgroundThemeView)
        }
        return backgroundThemesViews
    }
    
    private func makeAvatarsViews(avatars: [Avatars]) -> [UIView] {
        var avatarsViews = [UIView]()
        for avatar in avatars {
            let avatarData = UIStackView()
            avatarData.setup(axis: .horizontal, alignment: .fill, distribution: .fill, spacing: constants.optimalSpacing)
            let avatarImage = makeSquareView(with: avatar)
            let avatarName = UILabel()
            avatarName.setup(text: avatar.getHumanReadableName(), alignment: .center, font: defaultFont)
            avatarData.addArrangedSubviews([avatarImage, avatarName])
            let inInventory = storage.currentUser.availableItems.contains(where: {$0 as? Avatars == avatar})
            let avatarView = makeShopItemButton(with: avatarData, shopItem: avatar, inInventory: inInventory)
            avatarsViews.append(avatarView)
        }
        return avatarsViews
    }
    
    private func makeTitlesView(titles: [Titles], isShopButtons: Bool) -> [UIView] {
        var titlesViews = [UIView]()
        for title in titles {
            let titleLabel = UILabel()
            titleLabel.setup(text: title.getHumanReadableName().capitalizingFirstLetter(), alignment: .center, font: defaultFont)
            let inInventory = storage.currentUser.availableItems.contains(where: {$0 as? Titles == title})
            let titleView = isShopButtons ? makeShopItemButton(with: titleLabel, shopItem: title, inInventory: inInventory) : makeInventoryItemButton(with: titleLabel, inventoryItem: title, inInventory: inInventory)
            titlesViews.append(titleView)
        }
        return titlesViews
    }
    
    private func makeFramesView(frames: [Frames], isShopButtons: Bool) -> [UIView] {
        var framesViews = [UIView]()
        for frame in frames {
            let frameLabel = UILabel()
            frameLabel.setup(text: frame.getHumanReadableName(), alignment: .center, font: defaultFont)
            let frameView = PlayerFrame(background: storage.currentUser.playerBackground, playerFrame: frame, data: frameLabel)
            let inInventory = storage.currentUser.availableItems.contains(where: {$0 as? Frames == frame})
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
            dataStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
            dataStack.addArrangedSubview(makeColorData(text: "First Color", color: squareTheme.firstColor))
            dataStack.addArrangedSubview(makeColorData(text: "Second Color", color: squareTheme.secondColor))
            dataStack.addArrangedSubview(makeColorData(text: "Turn Color", color: squareTheme.turnColor))
            dataStack.addArrangedSubview(makeColorData(text: "Available squares Color", color: squareTheme.availableSquaresColor))
            dataStack.addArrangedSubview(makeColorData(text: "Pick Color", color: squareTheme.pickColor))
            dataStack.addArrangedSubview(makeColorData(text: "Check Color", color: squareTheme.checkColor))
            let inInventory = storage.currentUser.availableItems.contains(where: {$0 as? SquaresThemes == squaresThemeName})
            let itemView = makeShowcase(items: dataStack, item: squaresThemeName, inInventory: inInventory, axis: .horizontal, isShopButton: isShopButtons)
            squaresThemesView.append(itemView)
        }
        return squaresThemesView
    }
    
    private func makeSquareView(with imageItem: ImageItem?) -> UIView {
        let squareView = UIImageView()
        squareView.translatesAutoresizingMaskIntoConstraints = false
        if let imageItem {
            squareView.setImage(with: imageItem)
        }
        let squareViewConstraints = [squareView.widthAnchor.constraint(equalTo: squareView.heightAnchor)]
        NSLayoutConstraint.activate(squareViewConstraints)
        return squareView
    }
    
    //in case if square and element in square is 2 different images
    //right now only used for gameBoard showcase, cuz default numbers is not part of square image
    private func makeSpecialSquareView(with firstItem: ImageItem, and secondItem: ImageItem) -> UIView {
        let firstView = makeSquareView(with: firstItem)
        let secondView = makeSquareView(with: secondItem)
        firstView.addSubview(secondView)
        let secondViewConstraints = [secondView.centerXAnchor.constraint(equalTo: firstView.centerXAnchor), secondView.centerYAnchor.constraint(equalTo: firstView.centerYAnchor), secondView.widthAnchor.constraint(equalTo: firstView.widthAnchor, multiplier: constants.multiplierForSpecialSquareViewSize), secondView.heightAnchor.constraint(equalTo: firstView.heightAnchor, multiplier: constants.multiplierForSpecialSquareViewSize)]
        NSLayoutConstraint.activate(secondViewConstraints)
        return firstView
    }
    
    private func makeAdditionalButtonsForShopOrInventory(isShopButtons: Bool) {
        let coinsView = makeMainMenuButtonView(with: MiscImages.coinsBG, buttonImageItem: nil, buttontext: "", and: nil)
        coinsText.setup(text: String(storage.currentUser.coins), alignment: .center, font: defaultFont)
        coinsText.backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        coinsView.addSubview(coinsText)
        let coinsTextConstraints = [coinsText.topAnchor.constraint(equalTo: coinsView.topAnchor), coinsText.bottomAnchor.constraint(equalTo: coinsView.bottomAnchor), coinsText.leadingAnchor.constraint(equalTo: coinsView.leadingAnchor), coinsText.trailingAnchor.constraint(equalTo: coinsView.trailingAnchor)]
        NSLayoutConstraint.activate(coinsTextConstraints)
        let backButton = makeMainMenuButtonView(with: nil, buttonImageItem: nil, buttontext: "Back", and: isShopButtons ? #selector(makeShopMenu) : #selector(makeInventoryMenu))
        addBackButtonSFImageTo(view: backButton)
        makeAdditionalButtons(with: [backButton, coinsView])
    }
    
    //we are using system image(SF Symbol) in imageView, which causes a bug with constraints for some reason(height of imageView is
    //less than it should be), so we have to add it like this
    private func addBackButtonSFImageTo(view: UIView) {
        let backButtonView = UIImageView()
        backButtonView.translatesAutoresizingMaskIntoConstraints = false
        backButtonView.contentMode = view.contentMode
        backButtonView.setImage(with: SystemImages.backImage)
        view.addSubview(backButtonView)
        view.sendSubviewToBack(backButtonView)
        let backButtonViewConstraints = [backButtonView.topAnchor.constraint(equalTo: view.topAnchor), backButtonView.bottomAnchor.constraint(equalTo: view.bottomAnchor), backButtonView.leadingAnchor.constraint(equalTo: view.leadingAnchor), backButtonView.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
        NSLayoutConstraint.activate(backButtonViewConstraints)
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
            var actualButton = button
            if let viewWithNotif = button as? ViewWithNotifIcon {
                actualButton = viewWithNotif.mainView
            }
            if let shopItem = actualButton.layer.value(forKey: constants.keyForItem) as? GameItem {
                var inInventory = false
                var chosen = false
                let available = shopItem.cost < storage.currentUser.coins
                switch shopItem.type {
                case .squaresThemes:
                    if let squaresTheme = shopItem as? SquaresThemes {
                        inInventory = storage.currentUser.availableItems.contains(where: {$0 as? SquaresThemes == squaresTheme})
                        chosen = squaresTheme == storage.currentUser.squaresTheme
                    }
                case .figuresThemes:
                    if let figuresTheme = shopItem as? FiguresThemes {
                        inInventory = storage.currentUser.availableItems.contains(where: {$0 as? FiguresThemes == figuresTheme})
                        chosen = figuresTheme == storage.currentUser.figuresTheme
                    }
                case .boardThemes:
                    if let boardTheme = shopItem as? BoardThemes {
                        inInventory = storage.currentUser.availableItems.contains(where: {$0 as? BoardThemes == boardTheme})
                        chosen = boardTheme == storage.currentUser.boardTheme
                    }
                case .frames:
                    if let frame = shopItem as? Frames {
                        inInventory = storage.currentUser.availableItems.contains(where: {$0 as? Frames == frame})
                        chosen = frame == storage.currentUser.frame
                    }
                case .backgrounds:
                    if let background = shopItem as? Backgrounds {
                        inInventory = storage.currentUser.availableItems.contains(where: {$0 as? Backgrounds == background})
                        chosen = background == storage.currentUser.playerBackground
                    }
                case .titles:
                    if let title = shopItem as? Titles {
                        inInventory = storage.currentUser.availableItems.contains(where: {$0 as? Titles == title})
                        chosen = title == storage.currentUser.title
                    }
                case .avatars:
                    if let avatar = shopItem as? Avatars {
                        inInventory = storage.currentUser.availableItems.contains(where: {$0 as? Avatars == avatar})
                        chosen = avatar == storage.currentUser.playerAvatar
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
                    actualButton.backgroundColor = color
                    actualButton.subviews.first?.subviews.first?.backgroundColor = color
                    (actualButton.subviews.first?.subviews.first as? UIButton)?.isEnabled = isEnabled
                    if inShop && !isEnabled {
                        (actualButton.subviews.first?.subviews.first as? UIButton)?.setTitleColor(textColor, for: .normal)
                    }
                })
            }
        }
    }
    
    private func makeUserData() {
        userDataView.translatesAutoresizingMaskIntoConstraints = false
        let widthForAvatar = min(view.frame.height, view.frame.width) / constants.sizeMultiplayerForAvatar
        let userData = UIStackView()
        userData.setup(axis: .horizontal, alignment: .fill, distribution: .fill, spacing: constants.optimalSpacing)
        userData.defaultSettings()
        userData.layer.masksToBounds = true
        userData.backgroundColor = userData.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showUserProfileVC))
        let userAvatar = UIImageView()
        userAvatar.rectangleView(width: widthForAvatar)
        userAvatar.contentMode = .scaleAspectFill
        userAvatar.layer.masksToBounds = true
        userAvatar.setImage(with: storage.currentUser.playerAvatar)
        userAvatar.addGestureRecognizer(tapGesture)
        let userName = UILabel()
        userName.setup(text: storage.currentUser.nickname, alignment: .center, font: defaultFont)
        let exitButton = UIButton()
        if #available(iOS 15.0, *) {
            exitButton.buttonWith(imageItem: SystemImages.exitImageiOS15, and: #selector(signOut))
        }
        else {
            exitButton.buttonWith(imageItem: SystemImages.exitImage, and: #selector(signOut))
        }
        userData.addArrangedSubviews([userAvatar, userName, exitButton])
        var userDataConstraints = [NSLayoutConstraint]()
        if storage.currentUser.haveNewAvatarsInInventory() || storage.currentUser.nickname.isEmpty {
            userDataView = ViewWithNotifIcon(mainView: userData, cornerRadius: widthForAvatar / constants.optimalDividerForCornerRadius)
        }
        else {
            userDataView.addSubview(userData)
            userDataConstraints += [userData.topAnchor.constraint(equalTo: userDataView.topAnchor), userData.trailingAnchor.constraint(equalTo: userDataView.trailingAnchor)]
        }
        view.addSubview(userDataView)
        userDataConstraints += [userDataView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: constants.optimalDistance), userDataView.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor, constant: -constants.optimalDistance), userDataView.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor, constant: constants.optimalDistance), userDataView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), exitButton.widthAnchor.constraint(equalTo: exitButton.heightAnchor), userData.leadingAnchor.constraint(equalTo: userDataView.leadingAnchor), userData.bottomAnchor.constraint(equalTo: userDataView.bottomAnchor)]
        NSLayoutConstraint.activate(userDataConstraints)
    }
    
    func updateUserData() {
        if let userAvatar = (userDataView.subviews.first as? UIStackView)?.arrangedSubviews.first as? UIImageView {
            UIView.transition(with: userAvatar, duration: constants.animationDuration, options: .transitionCrossDissolve, animations: {[weak self] in
                if let self = self {
                    userAvatar.setImage(with: self.storage.currentUser.playerAvatar)
                }
            })
        }
        if let userName = (userDataView.subviews.first as? UIStackView)?.arrangedSubviews.second as? UILabel {
            UIView.transition(with: userName, duration: constants.animationDuration, options: .transitionCrossDissolve, animations: {[weak self] in
                if let self = self {
                    userName.text = self.storage.currentUser.nickname
                    self.userDataView.layoutIfNeeded()
                }
            })
        }
    }
    
    func removeNotificationIconsIfNeeded() {
        if !storage.currentUser.haveNewAvatarsInInventory() && !storage.currentUser.nickname.isEmpty {
            userDataView.removeNotificationIcon()
        }
        if !storage.currentUser.haveNewItemsInShop() {
            if buttonsStack.arrangedSubviews.count == 3 {
                if let viewWithNotif = buttonsStack.arrangedSubviews.third as? ViewWithNotifIcon {
                    viewWithNotif.removeNotificationIcon()
                }
            }
        }
        for button in buttonsStack.arrangedSubviews {
            if let viewWithNotif = button as? ViewWithNotifIcon {
                if let item = viewWithNotif.mainView.layer.value(forKey: constants.keyForItem) as? GameItem {
                    if !storage.currentUser.containsNewItemIn(items: [item]) {
                        viewWithNotif.removeNotificationIcon()
                    }
                }
                else if let items = viewWithNotif.mainView.layer.value(forKey: constants.keyForItems) as? [GameItem] {
                    if !storage.currentUser.containsNewItemIn(items: items) {
                        viewWithNotif.removeNotificationIcon()
                    }
                }
            }
        }
    }
    
}

// MARK: - Constants

private struct MainMenuVC_Constants {
    static let dividerForFont: CGFloat = 13
    static let optimalSpacing = 5.0
    static let spacingForHelperButtons = 15.0
    static let optimalAlpha = 0.5
    static let optimalDividerForCornerRadius = 4.0
    static let multiplierForButtonSize = 3.0
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let darkModeTextColor = UIColor.black
    static let lightModeTextColor = UIColor.white
    static let gameWinnerColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let gameLoserColor = UIColor.red.withAlphaComponent(optimalAlpha)
    static let gameDrawColor = UIColor.yellow.withAlphaComponent(optimalAlpha)
    static let gameNotEndedColor = UIColor.orange.withAlphaComponent(optimalAlpha)
    static let animationDuration = 0.5
    static let sizeMultiplayerForGameInfo = 2.0
    static let sizeMultiplayerForAvatar = 5.0
    static let sizeMultiplayerForHelperButtonsStack = 0.9
    static let dividerForDateFont = 3.0
    static let optimalDistance = 10.0
    static let dividerForFontInAdditionalInfo = 2.0
    static let keyForGame = "Game"
    static let keyForIsShopButton = "isShopButton"
    static let keyForItems = "Items"
    static let keyForItem = "Item"
    static let chosenItemColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let inInventoryColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let notAvailableColor = UIColor.red.withAlphaComponent(optimalAlpha)
    static let transformForShopItemWhenBought = CGAffineTransform(scaleX: 0.01, y: 0.01)
    static let insetsForCircleButton = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    static let multiplierForAdditionalButtonsSizeInMainMenuButton = 0.3
    static let distanceForContentInHorizontalShowcase = 20.0
    static let multiplierForSpecialSquareViewSize = 0.6
    static let pickItemBorderColor = UIColor.yellow.cgColor
    static let volumeForBackgroundMusic: Float = 0.5
    
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
