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
        audioPlayer.playSound(Sounds.moveSound2)
        updateNotificationIcons()
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
    
    private var searchingForMPgames: Task<Void, Error>?
    private var multiplayerGames = [GameLogic]()
    
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    private let wsManager = WSManager.getSharedInstance()
    
    // MARK: - Methods
    
    func updateUserData() {
        if let userDataView = mainMenuView.userDataView.mainView as? UserDataView {
            userDataView.updateUserData(with: storage.currentUser.playerAvatar, and: storage.currentUser.nickname)
        }
    }
    
    func updateNotificationIcons(shouldUpdateInUserProfile: Bool = true) {
        if let itemsView = mainMenuView.buttonsView?.buttonsStack as? ItemsView {
            updateNotificationIcons(for: itemsView)
        }
        else if let basicButtons = mainMenuView.buttonsView?.buttonsStack as? MMBasicButtons {
            updateNotificationIcons(for: basicButtons)
        }
        else if let itemsButtons = mainMenuView.buttonsView?.buttonsStack as? MMItemsButtons {
            updateNotificationIcons(for: itemsButtons)
        }
        if storage.currentUser.haveNewAvatarsInInventory() || storage.currentUser.nickname.isEmpty {
            mainMenuView.userDataView.addNotificationIcon()
        }
        else {
            mainMenuView.userDataView.removeNotificationIcon()
        }
        if shouldUpdateInUserProfile {
            if let userProfileVC = presentedViewController as? UserProfileVC {
                userProfileVC.updateNotificationIcons(shouldUpdateInMainMenu: false)
            }
        }
    }
    
    private func updateNotificationIcons(for itemsView: ItemsView) {
        for view in itemsView.arrangedSubviews {
            if let view = view as? ViewWithNotifIcon {
                if let itemView = view.mainView as? ItemView {
                    if storage.currentUser.containsNewItemIn(items: [itemView.item]) {
                        view.addNotificationIcon()
                    }
                    else {
                        view.removeNotificationIcon()
                    }
                }
                if let specialItemView = view.mainView as? SpecialItemView {
                    if let frameView = specialItemView.itemView as? FrameView {
                        frameView.setNeedsDisplay()
                    }
                }
            }
        }
    }
    
    private func updateNotificationIcons(for basicButtons: MMBasicButtons) {
        if storage.currentUser.haveNewItemsInShop() {
            basicButtons.shopButtonView.addNotificationIcon()
        }
        else {
            basicButtons.shopButtonView.removeNotificationIcon()
        }
        if storage.currentUser.haveNewItemsInInventory() {
            basicButtons.inventoryButtonView.addNotificationIcon()
        }
        else {
            basicButtons.inventoryButtonView.removeNotificationIcon()
        }
    }
    
    private func updateNotificationIcons(for itemsButtons: MMItemsButtons) {
        for button in itemsButtons.arrangedSubviews {
            if let viewWithNotifIcon = button as? ViewWithNotifIcon, let itemsButton = viewWithNotifIcon.mainView as? MMItemsButton {
                if storage.currentUser.containsNewItemIn(items: itemsButton.items) {
                    viewWithNotifIcon.addNotificationIcon()
                }
                else {
                    viewWithNotifIcon.removeNotificationIcon()
                }
            }
        }
    }
    
    private func pickItem(of specialItemView: SpecialItemView) {
        audioPlayer.playSound(Sounds.pickItemSound)
        storage.currentUser.addSeenItem(specialItemView.item)
        updateNotificationIcons()
        if let itemsView = mainMenuView.buttonsView?.buttonsStack as? ItemsView {
            if let pickedItemView = itemsView.pickedItemView {
                pickedItemView.unpickItem()
                if pickedItemView.item.name != specialItemView.item.name {
                    itemsView.pickedItemView = specialItemView
                }
                else {
                    itemsView.pickedItemView = nil
                }
            }
            else {
                itemsView.pickedItemView = specialItemView
            }
        }
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
        print(message)
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
    //font for all views, that are part of main menu view
    private lazy var font = UIFont.systemFont(ofSize: fontSize)
    
    private var reconnectAlert: CustomAlert?
    private var mainMenuView: MainMenuView!
    
    // MARK: - UI Methods
    
    private func makeUI() {
        let widthForAvatar = min(view.frame.height, view.frame.width) / constants.sizeMultiplayerForAvatar
        mainMenuView = MainMenuView(widthForAvatar: widthForAvatar, font: font, userNickname: storage.currentUser.nickname, userAvatar: storage.currentUser.playerAvatar)
        (mainMenuView.userDataView.mainView as? UserDataView)?.delegate = self
        makeBasicMenu(reversed: false)
        view.addSubview(mainMenuView)
        let mainMenuViewConstraints = [mainMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor), mainMenuView.trailingAnchor.constraint(equalTo: view.trailingAnchor), mainMenuView.topAnchor.constraint(equalTo: view.topAnchor), mainMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        NSLayoutConstraint.activate(mainMenuViewConstraints)
    }
    
    private func makeBasicMenu(reversed: Bool) {
        let basicButtons = MMBasicButtons(font: font)
        basicButtons.delegate = self
        mainMenuView.makeMenu(with: basicButtons, reversed: reversed, additionalButtons: nil)
        audioPlayer.playSound(Sounds.moveSound1)
        updateNotificationIcons()
    }
    
    private func makeGameMenu(reversed: Bool) {
        let gameButtons = MMGameButtons(font: font, isGuestMode: storage.currentUser.guestMode)
        gameButtons.delegate = self
        mainMenuView.makeMenu(with: gameButtons, reversed: reversed, additionalButtons: nil)
        audioPlayer.playSound(Sounds.moveSound1)
    }
    
    private func makeGamesMenu(with gamesInfo: [MMGameInfoView.Data], reversed: Bool, forMultiplayer: Bool = false) {
        let gamesView = GamesView(gamesInfo: gamesInfo, currentUserNickname: storage.currentUser.nickname, font: font, isMultiplayerGames: forMultiplayer)
        gamesView.delegate = self
        if forMultiplayer {
            gamesView.loadingSpinner?.delegate = self
            audioPlayer.playSound(Music.waitingMusic, volume: constants.volumeForWaitingMusic)
        }
        for gameView in gamesView.arrangedSubviews {
            if let gameView = gameView as? MMGameInfoView {
                gameView.delegate = self
            }
        }
        let additionalButtons = ABBuilder()
            .addBackButton(with: font)
            .build()
        additionalButtons.backButton?.delegate = self
        mainMenuView.makeMenu(with: gamesView, reversed: reversed, additionalButtons: additionalButtons)
        mainMenuView.buttonsView?.delegate = self
        audioPlayer.playSound(Sounds.moveSound1)
    }
    
    private func makeItemMenu(reversed: Bool, isShopItems: Bool) {
        let itemsButtons = MMItemsButtons(font: font, isShopItems: isShopItems, playerBackground: storage.currentUser.playerBackground, playerAvatar: storage.currentUser.playerAvatar)
        for itemsButton in itemsButtons.arrangedSubviews {
            if let itemsButton = (itemsButton as? ViewWithNotifIcon)?.mainView as? MMItemsButton {
                itemsButton.delegate = self
            }
        }
        itemsButtons.delegate = self
        mainMenuView.makeMenu(with: itemsButtons, reversed: reversed, additionalButtons: nil)
        audioPlayer.playSound(Sounds.moveSound1)
        updateNotificationIcons()
    }
    
    private func makeItemsMenu(with items: [GameItem], reversed: Bool, isShopItems: Bool) {
        let itemsView = ItemsView(items: items, isShopItems: isShopItems, font: font, playerBackground: storage.currentUser.playerBackground)
        for itemView in itemsView.arrangedSubviews {
            if let specialItemView = (itemView as? ViewWithNotifIcon)?.mainView as? SpecialItemView {
                let itemInfo = storage.currentUser.haveInInventory(item: specialItemView.item)
                if let invItemView = specialItemView as? InvItemView {
                    invItemView.delegate = self
                    invItemView.updateStatus(inInventory: itemInfo.inInventory, chosen: itemInfo.chosen)
                    if itemInfo.chosen {
                        itemsView.chosenItemView = invItemView
                    }
                }
                else if let shopItemView = specialItemView as? ShopItemView {
                    shopItemView.delegate = self
                    shopItemView.updateStatus(inInventory: itemInfo.inInventory, available: itemInfo.available)
                }
            }
        }
        let additionalButtons = ABBuilder()
            .addBackButton(with: font)
            .addCoinsView(with: font, and: storage.currentUser.coins)
            .build()
        additionalButtons.backButton?.delegate = self
        mainMenuView.makeMenu(with: itemsView, reversed: reversed, additionalButtons: additionalButtons)
        audioPlayer.playSound(Sounds.moveSound1)
        updateNotificationIcons()
    }
    
    private func makeReconnectAlert(with title: String, and message: String) {
        let alertData = CustomAlert.Data(type: .error, title: title, message: message, closeButtonText: "Cancel")
        reconnectAlert = CustomAlert(font: font, data: alertData, needLoadingSpinner: true)
        if let reconnectAlert {
            reconnectAlert.delegate = self
            reconnectAlert.loadingSpinner?.delegate = self
            audioPlayer.playSound(Music.waitingMusic, volume: constants.volumeForWaitingMusic)
            mainMenuView.applyBlurEffect(withAnimation: true, duration: constants.animationDuration)
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

// MARK: - Constants

private struct MainMenuVC_Constants {
    static let volumeForWaitingMusic: Float = 0.3
    static let animationDuration = 0.5
    static let dividerForFont: CGFloat = 13
    static let sizeMultiplayerForAvatar = 5.0
    static let volumeForBackgroundMusic: Float = 0.5
    static let optimalDistance = 10.0
}

// MARK: - WSManagerDelegate

extension MainMenuVC: WSManagerDelegate {
    
    func managerDidConnectSocket(_ manager: WSManager, with headers: [String: String]) {
        wsManager?.writeText(storage.currentUser.email + Date().toStringDateHMS + "MainMenuVC")
        reconnectAlert?.removeWithAnimation()
    }
    
    func managerDidEncounterError(_ manager: WSManager, with message: String) {
        makeErrorAlert(with: message)
    }
    
}

// MARK: - BackButtonDelegate

extension MainMenuVC: BackButtonDelegate {
    
    func backButtonDidTriggerBackAction(_ backButton: BackButton) {
        if let itemsView = mainMenuView.buttonsView?.buttonsStack as? ItemsView {
            makeItemMenu(reversed: true, isShopItems: itemsView.isShopItems)
        }
        else if mainMenuView.buttonsView?.buttonsStack as? GamesView != nil {
            makeGameMenu(reversed: true)
        }
    }
    
}

// MARK: - GamesViewDelegate

extension MainMenuVC: GamesViewDelegate {
    
    func gamesViewDidChangeLayout(_ gamesView: GamesView) {
        view.layoutIfNeeded()
    }
    
    func gamesViewDidRemoveFromSuperview(_ gamesView: GamesView) {
        searchingForMPgames?.cancel()
    }
    
}

// MARK: - MMGameInfoViewDelegate

extension MainMenuVC: MMGameInfoViewDelegate {
    
    func gameInfoViewDidTriggerLoadGame(_ gameInfoView: MMGameInfoView) {
        let gameID = gameInfoView.gameID
        if let game = storage.currentUser.games.first(where: {$0.gameID == gameID}) ?? multiplayerGames.first(where: {$0.gameID == gameID}) {
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
                makeGameMenu(reversed: true)
            }
            audioPlayer.pauseSound(Music.menuBackgroundMusic)
            audioPlayer.playSound(Sounds.successSound)
            showGameVC(with: game)
            searchingForMPgames?.cancel()
        }
    }
    
    func gameInfoViewDidTriggerDeleteGame(_ gameInfoView: MMGameInfoView) {
        if let game = storage.currentUser.games.first(where: {$0.gameID == gameInfoView.gameID}) {
            let alert = UIAlertController(title: "Delete game", message: "Are you sure?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
                guard let self else { return }
                self.storage.currentUser.removeGame(game)
                if let gamesView = self.mainMenuView.buttonsView?.buttonsStack as? GamesView {
                    gamesView.removeGameView(gameInfoView)
                }
                self.audioPlayer.playSound(Sounds.removeSound)
            }))
            present(alert, animated: true)
            audioPlayer.playSound(Sounds.openPopUpSound)
        }
    }
    
    func gameInfoViewDidToggleAdditionalInfo(_ gameInfoView: MMGameInfoView) {
        view.layoutIfNeeded()
        audioPlayer.playSound(Sounds.moveSound2)
    }
    
    //shows game view with chosen game
    private func showGameVC(with game: GameLogic) {
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
    
    //makes game view with chosen game
    private func makeGameVC(with game: GameLogic) {
        let gameVC = GameViewController()
        gameVC.gameLogic = game
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }
    
}

// MARK: - InvItemViewDelegate

extension MainMenuVC: InvItemViewDelegate {
    
    func invItemViewDidTriggerChooseAction(_ invItemView: InvItemView) {
        let itemInfo = storage.currentUser.haveInInventory(item: invItemView.item)
        if itemInfo.inInventory {
            audioPlayer.playSound(Sounds.chooseItemSound)
            storage.currentUser.setValue(with: invItemView.item)
            invItemView.updateStatus(inInventory: true, chosen: true)
            if let itemsView = mainMenuView.buttonsView?.buttonsStack as? ItemsView {
                if let chosenItemView = itemsView.chosenItemView {
                    let oldChosenItemInfo = storage.currentUser.haveInInventory(item: chosenItemView.item)
                    chosenItemView.updateStatus(inInventory: oldChosenItemInfo.inInventory, chosen: oldChosenItemInfo.chosen)
                }
                itemsView.chosenItemView = invItemView
            }
        }
    }
    
    func invItemViewDidTriggerPickAction(_ invItemView: InvItemView) {
        pickItem(of: invItemView)
    }
    
    func invItemViewDidToggleDescriptionOfItem(_ invItemView: InvItemView) {
        audioPlayer.playSound(Sounds.toggleSound)
    }
    
}

// MARK: - ShopItemViewDelegate

extension MainMenuVC: ShopItemViewDelegate {
    
    func shopItemViewDidTriggerBuyAction(_ shopItemView: ShopItemView) {
        if shopItemView.itemView.item.cost < storage.currentUser.coins {
            let itemName = shopItemView.item.getHumanReadableName()
            let alert = UIAlertController(title: "Buy \(itemName)", message: "Are you sure?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
                guard let self else { return }
                self.audioPlayer.playSound(Sounds.buyItemSound)
                self.storage.currentUser.addAvailableItem(shopItemView.item)
                let startCoins = self.storage.currentUser.coins
                self.storage.currentUser.addCoins(-shopItemView.item.cost)
                let endCoins = self.storage.currentUser.coins
                shopItemView.updateStatus(inInventory: true, available: false)
                self.mainMenuView.buyItem(itemView: shopItemView.itemView, startCoins: startCoins, endCoins: endCoins)
            }))
            present(alert, animated: true)
            audioPlayer.playSound(Sounds.openPopUpSound)
        }
    }
    
    func shopItemViewDidTriggerPickAction(_ shopItemView: ShopItemView) {
        pickItem(of: shopItemView)
    }
    
}

// MARK: - MMBasicButtonsDelegate

extension MainMenuVC: MMBasicButtonsDelegate {
    
    func basicButtonsDidTriggerInventoryMenu(_ basicButtons: MMBasicButtons) {
        makeItemMenu(reversed: false, isShopItems: false)
    }
    
    func basicButtonsDidTriggerShopMenu(_ basicButtons: MMBasicButtons) {
        makeItemMenu(reversed: false, isShopItems: true)
    }
    
    func basicButtonsDidTriggerGameMenu(_ basicButtons: MMBasicButtons) {
        makeGameMenu(reversed: false)
    }
    
}

// MARK: - MMGameButtonsDelegate

extension MainMenuVC: MMGameButtonsDelegate {
    
    //shows/hides view for game creation
    func gameButtonsDidTriggerToggleCreateGameVC(_ gameButtons: MMGameButtons) {
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
    
    func gameButtonsDidTriggerUserGamesMenu(_ gameButtons: MMGameButtons) {
        var gamesInfo = [MMGameInfoView.Data]()
        for game in storage.currentUser.games {
            if game.gameMode == .oneScreen || game.gameEnded {
                gamesInfo.append(makeGameInfo(from: game))
            }
        }
        makeGamesMenu(with: gamesInfo, reversed: false)
    }
    
    func gameButtonsDidTriggerMPGamesMenu(_ gameButtons: MMGameButtons) {
        if let wsManager, wsManager.connectedToWSServer {
            makeGamesMenu(with: [], reversed: false, forMultiplayer: true)
            searchingForMPgames = Task {
                do {
                    for try await games in storage.getMultiplayerGames() {
                        multiplayerGames = games
                        var gamesInfo = [MMGameInfoView.Data]()
                        for game in games {
                            gamesInfo.append(makeGameInfo(from: game))
                        }
                        if let gamesView = mainMenuView.buttonsView?.buttonsStack as? GamesView {
                            gamesView.updateGameViews(with: gamesInfo, and: storage.currentUser.nickname)
                            for gameView in gamesView.arrangedSubviews {
                                if let gameView = gameView as? MMGameInfoView {
                                    gameView.delegate = self
                                }
                            }
                        }
                    }
                }
                catch {
                    makeErrorAlert(with: error.localizedDescription)
                    makeGameMenu(reversed: true)
                }
            }
        }
        else {
            makeReconnectAlert(with: "Error", and: "You are not connected to the server, reconnecting...")
        }
    }
    
    func gameButtonsDidTriggerBackAction(_ gameButtons: MMGameButtons) {
        makeBasicMenu(reversed: true)
    }
    
    //makes view for game creation
    private func makeCreateGameVC() {
        let createGameVC = CreateGameVC()
        configureSheetController(of: createGameVC)
        present(createGameVC, animated: true)
        audioPlayer.playSound(Sounds.openPopUpSound)
    }
    
    private func makeGameInfo(from game: GameLogic) -> MMGameInfoView.Data {
        var winnerInfo: MMGameInfoView.Data.PlayerInfo?
        if let winner = game.winner {
            winnerInfo = MMGameInfoView.Data.PlayerInfo(nickname: winner.user.nickname, points: winner.user.points, pointsForGame: winner.pointsForGame)
        }
        let firstPlayerInfo = MMGameInfoView.Data.PlayerInfo(nickname: game.players.first!.user.nickname, points: game.players.first!.user.points, pointsForGame: game.players.first!.pointsForGame)
        var secondPlayerInfo: MMGameInfoView.Data.PlayerInfo?
        if let secondPlayer = game.players.second {
            secondPlayerInfo = MMGameInfoView.Data.PlayerInfo(nickname: secondPlayer.user.nickname, points: secondPlayer.user.points, pointsForGame: secondPlayer.pointsForGame)
        }
        var gameInfo = MMGameInfoView.Data()
        gameInfo.id = game.gameID
        gameInfo.startDate = game.startDate
        gameInfo.ended = game.gameEnded
        gameInfo.winnerInfo = winnerInfo
        gameInfo.firstPlayerInfo = firstPlayerInfo
        gameInfo.secondPlayerInfo = secondPlayerInfo
        gameInfo.mode = game.gameMode
        gameInfo.rewindEnabled = game.rewindEnabled
        gameInfo.timerEnabled = game.timerEnabled
        gameInfo.totalTime = game.totalTime
        gameInfo.additionalTime = game.additionalTime
        return gameInfo
    }
    
}

// MARK: - MMItemsButtonDelegate

extension MainMenuVC: MMItemsButtonDelegate {
    
    func itemsButtonDidTriggerMakeListOfItems(_ itemsButtons: MMItemsButton) {
        makeItemsMenu(with: itemsButtons.items, reversed: false, isShopItems: itemsButtons.isShopItems)
    }
    
}

// MARK: - MMItemsButtonsDelegate

extension MainMenuVC: MMItemsButtonsDelegate {
    
    func itemsButtonsDidTriggerBackAction(_ itemsButtons: MMItemsButtons) {
        makeBasicMenu(reversed: true)
    }
    
}

// MARK: - UserDataViewDelegate

extension MainMenuVC: UserDataViewDelegate {
    
    //going back to authorization vc
    func userDataViewDidTriggerSignOut(_ userDataView: UserDataView) {
        let exitAlert = UIAlertController(title: "Exit", message: "Are you sure?", preferredStyle: .alert)
        exitAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            guard let self else { return }
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
        }))
        exitAlert.addAction(UIAlertAction(title: "No", style: .cancel))
        present(exitAlert, animated: true)
        audioPlayer.playSound(Sounds.openPopUpSound)
    }
    
    //shows/hides view for redacting user profile
    func userDataViewDidTriggerToggleUserProfileVC(_ userDataView: UserDataView) {
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
    
    //makes view for redacting user profile
    private func makeUserProfileVC() {
        let userProfileVC = UserProfileVC()
        configureSheetController(of: userProfileVC)
        present(userProfileVC, animated: true)
        audioPlayer.playSound(Sounds.openPopUpSound)
    }
    
}

// MARK: - UIScrollViewDelegate

extension MainMenuVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let buttonsView = scrollView as? MMButtonsView {
            if let gamesView = buttonsView.buttonsStack as? GamesView {
                gamesView.removeReduntantGameViews()
            }
        }
    }
    
}

// MARK: - CustomAlertDelegate

extension MainMenuVC: CustomAlertDelegate {
    
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
        mainMenuView.removeBlurEffects(withAnimation: true, duration: constants.animationDuration)
        wsManager?.stopReconnecting()
    }
    
}

// MARK: - LoadingSpinnerDelegate

extension MainMenuVC: LoadingSpinnerDelegate {
    
    func loadingSpinnerDidRemoveFromSuperview(_ loadingSpinner: LoadingSpinner) {
        audioPlayer.pauseSound(Music.waitingMusic)
    }
    
}
