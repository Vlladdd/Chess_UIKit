//
//  GameViewController.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.06.2022.
//

import UIKit
import Starscream
import Network

//VC that represents game view
class GameViewController: UIViewController, WebSocketDelegate {
    
    // MARK: - WebSocketDelegate
    
    var socket: Starscream.WebSocket!
    var isConnected = false
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
            socket.write(string: currentUser.email + Date().toStringDateHMS + "GameVC")
            if !finalError {
                websocketDidConnect()
            }
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
            makeErrorAlert(with: "websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
        case .binary(let data):
            print("Received data: \(data.count)")
            if let playerMessage = try? JSONDecoder().decode(PlayerMessage.self, from: data) {
                if playerMessage.gameID == gameLogic.gameID {
                    websocketDidReceive(playerMessage: playerMessage)
                }
            }
            if let turn = try? JSONDecoder().decode(Turn.self, from: data) {
                if turn.gameID == gameLogic.gameID {
                    websocketDidReceive(turn: turn)
                }
            }
            if let square = try? JSONDecoder().decode(Square.self, from: data) {
                if square.gameID == gameLogic.gameID {
                    websocketDidReceive(square: square)
                }
            }
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
            break
        case .error(let error):
            if !suspendedState {
                serverError = true
                needToRequestLastAction = true
                afkTimer?.invalidate()
                afkTimer = makeAfkTimer(for: .player1)
                enemyAfkTimer?.invalidate()
            }
            isConnected = false
            handleWebSocketError(error)
        }
    }
    
    private func websocketDidConnect() {
        if serverError {
            afkTimer?.invalidate()
            serverError = false
        }
        if gameLogic.players.first!.figuresColor == .white {
            if !(afkTimer?.isValid ?? false) || afkTimer == nil {
                afkTimer = makeAfkTimer(for: .player1)
            }
        }
        else {
            if !(enemyAfkTimer?.isValid ?? false) || enemyAfkTimer == nil {
                enemyAfkTimer = makeAfkTimer(for: .player2)
            }
        }
        if !gameLogic.timerIsValid() && !gameLogic.turns.isEmpty {
            activatePlayerTime(continueTimer: true)
        }
        currentUser.addGame(gameLogic)
        storage.saveUser(currentUser)
        isConnected = true
        reconnectTimer?.fire()
        //to be sure, that both players are connected
        //first player is always current user
        if !needToRequestLastAction && gameLogic.players.first?.multiplayerType == .creator {
            if let playerMessage = try? JSONEncoder().encode(PlayerMessage(gameID: gameLogic.gameID!, playerType: .creator, player1Ready: true, player2Ready: true)) {
                socket.write(data: playerMessage)
            }
        }
        //if app was in suspended state for too long, we need to request last turn from opponent
        else if needToRequestLastAction {
            if let playerMessage = try? JSONEncoder().encode(PlayerMessage(gameID: gameLogic.gameID!, playerType: gameLogic.players.first!.multiplayerType!, requestLastAction: true)) {
                socket.write(data: playerMessage)
            }
        }
    }
    
    private func websocketDidReceive(playerMessage: PlayerMessage) {
        if playerMessage.gameEnded && !gameLogic.gameEnded && view.subviews.first(where: {$0 == endOfTheGameView}) == nil {
            if playerMessage.gameDraw {
                gameLogic.forceDraw()
            }
            else {
                gameLogic.surrender(for: playerMessage.playerToSurrender)
            }
            makeEndOfTheGameView()
        }
        else if playerMessage.player1Ready && playerMessage.player2Ready {
            cancelGameTimer?.invalidate()
            loadingSpinner.removeFromSuperview()
            if gameLogic.currentPlayer.multiplayerType == gameLogic.players.first?.multiplayerType {
                toggleTurnButtons(disable: false)
            }
        }
        else if playerMessage.opponentWantsDraw {
            let interval = ceil(Date().timeIntervalSince(playerMessage.date))
            if interval > 0 {
                opponentWantsDraw = true
                UIView.animate(withDuration: constants.animationDuration, animations: { [weak self] in
                    self?.surrenderButton.backgroundColor = constants.surrenderButtonHighlightColor
                })
                Timer.scheduledTimer(withTimeInterval: constants.timeToAcceptDraw - interval, repeats: false, block: { [weak self] _ in
                    self?.opponentWantsDraw = false
                    UIView.animate(withDuration: constants.animationDuration, animations: {
                        self?.surrenderButton.backgroundColor = constants.surrenderButtonBGColor
                    })
                })
            }
        }
    }
    
    private func websocketDidReceive(turn: Turn) {
        //second condition is for pawnTransform, if opponent sent turn, but didn`t pick new figure yet,
        //cuz when he gonna pick figure and send turn again, that will be 2 different turns, while it shouldn`t
        if !gameLogic.turns.contains(turn) && (gameLogic.turns.last?.squares != turn.squares || gameLogic.turns.isEmpty) {
            for square in turn.squares {
                gameLogic.makeTurn(square: square, turn: turn)
                updateBoard()
                toggleTurnButtons(disable: false)
            }
            if !gameLogic.pawnWizard {
                enemyAfkTimer?.invalidate()
                afkTimer = makeAfkTimer(for: .player1, timeElapsed: Date().timeIntervalSince(turn.time))
                //to update our chess timer as well
                if needToRequestLastAction {
                    restoreFromSuspendedState()
                }
            }
            else if turn.pawnTransform == nil {
                needToRequestLastAction = false
            }
        }
        else {
            needToRequestLastAction = false
        }
    }
    
    //when pawn reached last row
    private func websocketDidReceive(square: Square) {
        if let figure = square.figure, figure.color == gameLogic.currentPlayer.figuresColor {
            if gameLogic.gameBoard[square.column, square.row]?.figure != square.figure && gameLogic.pawnWizard && gameLogic.turns.last!.squares.last!.row == square.row && gameLogic.turns.last!.squares.last!.column == square.column {
                enemyAfkTimer?.invalidate()
                gameLogic.makeTurn(square: square)
                afkTimer = makeAfkTimer(for: .player1, timeElapsed: Date().timeIntervalSince(gameLogic.turns.last!.time))
                finishAnimations()
                if let turn = gameLogic.currentTurn, let square = turn.squares.last {
                    updateSquare(square, figure: figure)
                }
                if gameLogic.gameEnded && view.subviews.first(where: {$0 == endOfTheGameView}) == nil {
                    makeEndOfTheGameView()
                }
                activatePlayerTime()
                addTurnToUI(gameLogic.turns.last!)
                updateUI(animateSquares: true)
                toggleTurnButtons(disable: false)
                rotateScrollContent(reverse: !(gameBoardAutoRotate && gameLogic.currentPlayer.type == .player2))
                if needToRequestLastAction {
                    restoreFromSuspendedState()
                }
            }
        }
    }
    
    private func handleWebSocketError(_ error: Error?) {
        if let error = error as? WSError {
            if !gameLogic.gameEnded && connectedToTheInternet {
                currentUser.removeGame(gameLogic)
                storage.saveUser(currentUser)
            }
            makeErrorAlert(with: "websocket encountered an error: \(error.message)", addReconnectButton: true)
        }
        else if let error = error {
            if let error = error as? NWError {
                //if server encountered a problem, user shouldn`t lose points
                if error._code == 0 && !gameLogic.gameEnded && connectedToTheInternet {
                    currentUser.removeGame(gameLogic)
                    storage.saveUser(currentUser)
                }
            }
            makeErrorAlert(with: "websocket encountered an error: \(error.localizedDescription)", addReconnectButton: true)
        }
        else {
            makeErrorAlert(with: "websocket encountered an error", addReconnectButton: true)
        }
    }
    
    // MARK: - View Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        if !gameLogic.turns.isEmpty && gameLogic.storedTurns.isEmpty {
            gameLogic.configureAfterLoad()
        }
        updateUIIfLoad()
        updateUI()
        activateStartConstraints()
        if gameLogic.gameMode == .multiplayer && !gameLogic.gameEnded {
            configureForMultiplayer()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollViewOfGame.scrollToViewAndCenterOnScreen(view: gameBoard, animated: true)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        //we are not using UIdevice.current.orientation, because in both cases it is the same, so we use size instead
        //orientation parameter needed to perform only 1 function at a time
        //in other words, we are checking, if we are about to transit to landscape or portrait orientation and compare it to which it
        //should be for first or second case
        //if we are changing orientation from landscape to portrait, we need to update constraints, before transition will begin,
        //because there will be not enough space to put anything from left or from right of gameBoard in portrait orientation
        UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
            if let self = self {
                self.checkOrientationAndUpdateConstraints(size: size, orientation: .landscapeLeft)
            }
        })
        //if we are changing orientation from portrait to landscape, we need to wait for rotation to finish, before changing
        //constraints, because there will be not enough space to put anything from left or from right of gameBoard in portrait orientation
        coordinator.animate(alongsideTransition: nil, completion: {[weak self] _ in
            if let self = self {
                UIView.animate(withDuration: constants.animationDuration, animations: {
                    self.checkOrientationAndUpdateConstraints(size: size, orientation: .portrait)
                })
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        deactivateMultiplayerTImers()
        if let mainMenuVC = UIApplication.getTopMostViewController() as? MainMenuVC {
            mainMenuVC.socket.delegate = mainMenuVC
            mainMenuVC.isConnected = isConnected
        }
    }
    
    // MARK: - Properties
    
    var gameLogic: GameLogic!
    var currentUser: User!
    
    //if we connect to the server, after afkTimer for that is expired, and we already have final alert on screen
    private var finalError = false
    private var serverError = false
    //when game will end and we will send last turn, this will become false
    private var shouldSendTurn = true
    private var connectedToTheInternet = true
    //when user left the app, but it is still in apps list
    private var suspendedState = false
    private var needToRequestLastAction = false
    private var currentUserWantsDraw = false
    private var opponentWantsDraw = false
    private var afkTimer: Timer?
    private var enemyAfkTimer: Timer?
    private var pingTimer: Timer?
    //if second player didn`t connect in time at the start of the game
    private var cancelGameTimer: Timer?
    private var reconnectTimer: Timer?
    //used in playback of the turns and also to have ability to stop it
    private var turnsActionTimers: [Timer] = []
    private var backwardRewind = false
    private var forwardRewind = false
    //we are storing all animations to have ability to finish them all at once
    private var animations: [UIViewPropertyAnimator] = []
    //animation of moving the figure to trash
    //we are not storing it in animations, cuz we cancel it only, before start new one
    private var trashAnimation: UIViewPropertyAnimator?
    //makes most of the animations faster
    private var fastAnimations = false
    //when we load an ended game we don`t need to show with animation endOfTheGameView, create wheelOfFortune and also run some functions
    //endOfTheGameView will be created anyway, but he will not pop up and user have to press button to show it
    private var loadedEndedGame = false
    //when we making fastAnimations true, we want to speed up current proccesing turns
    //in other words, we canceling all timers and make move to chosenTurn quickly, that is why we need to store it
    private var chosenTurn: Turn?
    private var restoringTurns = false
    private var animatingTurns = false
    //to rotate gameBoard after currentPlayer changed
    private var gameBoardAutoRotate = false
    
    //to check internet connection
    private let monitor = NWPathMonitor()
    private let storage = Storage()
    
    private typealias constants = GameVC_Constants
    
    // MARK: - User Initiated Methods
    
    //restores game from last saved state
    //at first, we rewinding game to the start and then we rewinding it to last turn in stored turns
    //we need to rewind game to the start to restart UI
    //it could have been done in other way, but i think, it looks cooler this way :)
    //and also we are doing it asynchronously, cuz rewinding turns could take some seconds, which will freeze UI
    @objc private func restoreGame(_ sender: UIButton? = nil) {
        if !animatingTurns && !fastAnimations {
            makeLoadingSpinner()
            restoringTurns = true
            toggleTurnButtons(disable: true)
            DispatchQueue.global().async {[weak self] in
                if let self = self {
                    //this will only rewind to first turn
                    if self.gameLogic.currentTurn != self.gameLogic.turns.first {
                        self.moveTurns(to: self.gameLogic.turns.first!, animate: false)
                    }
                    //this will rewind first turn
                    if !self.gameLogic.firstTurn {
                        self.moveTurn(forward: false, activateTurnButtons: false)
                    }
                    self.gameLogic.restoreFromStoredTurns()
                    DispatchQueue.main.sync {
                        for arrangedSubview in self.turns.arrangedSubviews {
                            arrangedSubview.removeFromSuperview()
                        }
                        self.makeEmptyTurnData()
                        for turn in self.gameLogic.turns {
                            if (!turn.shortCastle && !turn.longCastle) || turn.squares.first?.figure?.name == .rook {
                                self.addTurnToUI(turn)
                            }
                        }
                    }
                    self.restoringTurns = false
                    self.moveTurns(to: self.gameLogic.turns.last!, animate: false)
                    DispatchQueue.main.sync {
                        self.toggleTurnButtons(disable: false)
                        self.loadingSpinner.removeFromSuperview()
                    }
                }
            }
        }
        //instantly restores game
        else if !animatingTurns {
            gameLogic.restoreFromStoredTurnsToLastTurn()
            for arrangedSubview in turns.arrangedSubviews {
                arrangedSubview.removeFromSuperview()
            }
            makeEmptyTurnData()
            removeFiguresFrom(destroyedFigures1)
            removeFiguresFrom(destroyedFigures2)
            replaceFiguresInSquares()
            updatePlayersTime()
            updateUIIfLoad()
            updateUI()
        }
    }
    
    @objc private func chooseSquare(_ sender: UITapGestureRecognizer? = nil) {
        if let square = sender?.view?.layer.value(forKey: constants.keyNameForSquare) as? Square {
            gameLogic.makeTurn(square: square)
            updateBoard()
        }
    }
    
    //when pawn reached last row
    @objc private func replacePawn(_ sender: UITapGestureRecognizer? = nil) {
        if var square = sender?.view?.layer.value(forKey: constants.keyNameForSquare) as? Square, let figure = square.figure {
            square.updateTime(newValue: Date())
            gameLogic.makeTurn(square: square)
            finishAnimations()
            if let turn = gameLogic.currentTurn, let square = turn.squares.last {
                updateSquare(square, figure: figure)
            }
            if gameLogic.gameEnded && view.subviews.first(where: {$0 == endOfTheGameView}) == nil {
                makeEndOfTheGameView()
            }
            activatePlayerTime()
            addTurnToUI(gameLogic.turns.last!)
            updateUI(animateSquares: true)
            if gameLogic.gameMode != .multiplayer {
                toggleTurnButtons(disable: false)
            }
            else if shouldSendTurn {
                if gameLogic.gameEnded {
                    shouldSendTurn = false
                }
                square.updateTimeLeft(newValue: gameLogic.timeLeft)
                if let turnJson = try? JSONEncoder().encode(gameLogic.turns.last!) {
                    socket.write(data: turnJson)
                }
                if let squareJson = try? JSONEncoder().encode(square) {
                    socket.write(data: squareJson)
                }
                afkTimer?.invalidate()
                enemyAfkTimer = makeAfkTimer(for: .player2)
            }
            rotateScrollContent(reverse: !(gameBoardAutoRotate && gameLogic.currentPlayer.type == .player2))
        }
    }
    
    //shows/hides end of the game view
    @objc private func transitEndOfTheGameView(_ sender: UIButton? = nil) {
        animateTransition(of: frameForEndOfTheGameView, startAlpha: frameForEndOfTheGameView.alpha)
        animateTransition(of: endOfTheGameScrollView, startAlpha: endOfTheGameScrollView.alpha)
        animateTransition(of: endOfTheGameView, startAlpha: endOfTheGameView.alpha)
    }
    
    @objc private func toggleFastAnimations(_ sender: UIButton? = nil) {
        fastAnimations.toggle()
        if let sender = sender {
            if sender.backgroundColor == constants.dangerPlayerDataColor {
                UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
                    sender.backgroundColor = self?.currentPlayerDataColor
                })
            }
            else {
                UIView.animate(withDuration: constants.animationDuration, animations: {
                    sender.backgroundColor = constants.dangerPlayerDataColor
                })
            }
        }
        finishAnimations()
        if !turnsActionTimers.isEmpty {
            if let chosenTurn = chosenTurn {
                toggleTurnButtons(disable: true)
                DispatchQueue.global().async {[weak self] in
                    if let self = self {
                        self.moveTurns(to: chosenTurn, animate: false)
                    }
                }
            }
        }
    }
    
    //shows/hides additional buttons
    @objc private func transitAdditonalButtons(_ sender: UIButton? = nil) {
        if let sender = sender {
            if sender.transform == currentTransformOfArrow {
                sender.transform = currentTransformOfArrow.rotated(by: .pi)
            }
            else {
                sender.transform = currentTransformOfArrow
            }
            if sender.image(for: .normal) == nil {
                animateAdditionalButtons(additionalButton: additionalButtonForFigures, additionalButtons: additionalButtonsForFigures)
            }
            else {
                animateAdditionalButtons(arrowToAdditionalButtons: arrowToAdditionalButtons, additionalButton: additionalButton, additionalButtons: additionalButtons)
            }
        }
    }
    
    @objc private func rotateFigures(_ sender: UIButton? = nil) {
        if let sender = sender {
            if sender.transform == CGAffineTransform(rotationAngle: .pi) {
                sender.transform = .identity
            }
            else {
                sender.transform = CGAffineTransform(rotationAngle: .pi)
            }
            if let figuresColor = sender.layer.value(forKey: constants.keyForFigureColor) as? GameColors {
                rotateFiguresInSquares(with: figuresColor)
            }
        }
    }
    
    @objc private func toggleGameBoardAutoRotate(_ sender: UIButton? = nil) {
        gameBoardAutoRotate.toggle()
        if let sender = sender {
            if sender.backgroundColor == constants.dangerPlayerDataColor {
                UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
                    sender.backgroundColor = self?.currentPlayerDataColor
                })
            }
            else {
                UIView.animate(withDuration: constants.animationDuration, animations: {
                    sender.backgroundColor = constants.dangerPlayerDataColor
                })
            }
        }
        let condition1 = gameLogic.currentPlayer.type == .player2 && gameBoardAutoRotate
        let condition2 = (animatingTurns || restoringTurns) && scrollContentOfGame.transform == .identity
        if condition1 || condition2 {
            rotateScrollContent()
        }
        else {
            rotateScrollContent(reverse: true)
        }
    }
    
    //locks scrolling of game view
    @objc private func lockGameView(_ sender: UIButton? = nil) {
        scrollViewOfGame.isScrollEnabled.toggle()
        if let sender = sender {
            if sender.currentImage == UIImage(systemName: "lock.open") {
                sender.setImage(UIImage(systemName: "lock"), for: .normal)
            }
            else {
                sender.setImage(UIImage(systemName: "lock.open"), for: .normal)
            }
        }
    }
    
    //lets player surrender
    @objc private func surrender(_ sender: UIButton? = nil) {
        if !animatingTurns && !gameLogic.gameEnded {
            let surrenderAlert = UIAlertController(title: "Surrender/Draw", message: "Do you want to surrender or draw?", preferredStyle: .alert)
            surrenderAlert.addAction(UIAlertAction(title: "Surrender", style: .default, handler: { [weak self] _ in
                if let self = self {
                    sender?.isEnabled = false
                    if self.gameLogic.gameMode == .multiplayer && !self.gameLogic.gameEnded {
                        self.gameLogic.surrender(for: .player1)
                        if let gameStatusJson = try? JSONEncoder().encode(PlayerMessage(gameID: self.gameLogic.gameID!, playerType: self.gameLogic.players.first!.multiplayerType!, gameEnded: true)) {
                            self.socket.write(data: gameStatusJson)
                        }
                    }
                    else {
                        self.gameLogic.surrender()
                    }
                    if self.view.subviews.first(where: {$0 == self.endOfTheGameView}) == nil {
                        self.makeEndOfTheGameView()
                    }
                }
            }))
            surrenderAlert.addAction(UIAlertAction(title: "Draw", style: .default, handler: { [weak self] _ in
                if let self = self {
                    sender?.isEnabled = false
                    if self.gameLogic.gameMode == .oneScreen {
                        self.gameLogic.forceDraw()
                        if self.view.subviews.first(where: {$0 == self.endOfTheGameView}) == nil {
                            self.makeEndOfTheGameView()
                        }
                    }
                    else if !self.gameLogic.gameEnded {
                        self.currentUserWantsDraw = true
                        UIView.animate(withDuration: constants.animationDuration, animations: {
                            self.surrenderButton.backgroundColor = constants.surrenderButtonHighlightColor
                        })
                        if self.opponentWantsDraw {
                            self.gameLogic.forceDraw()
                            if self.view.subviews.first(where: {$0 == self.endOfTheGameView}) == nil {
                                self.makeEndOfTheGameView()
                            }
                        }
                        else {
                            Timer.scheduledTimer(withTimeInterval: constants.timeToAcceptDraw, repeats: false, block: { _ in
                                self.currentUserWantsDraw = false
                                self.surrenderButton.isEnabled = !self.gameLogic.gameEnded
                                UIView.animate(withDuration: constants.animationDuration, animations: {
                                    self.surrenderButton.backgroundColor = UIColor.clear
                                })
                            })
                        }
                        if let gameStatusJson = try? JSONEncoder().encode(PlayerMessage(gameID: self.gameLogic.gameID!, playerType: self.gameLogic.players.first!.multiplayerType!, gameEnded: self.opponentWantsDraw, gameDraw: self.opponentWantsDraw, opponentWantsDraw: true)) {
                            self.socket.write(data: gameStatusJson)
                        }
                    }
                }
            }))
            surrenderAlert.addAction(UIAlertAction(title: "No", style: .cancel))
            present(surrenderAlert, animated: true)
        }
    }
    
    //shows/hides turnsView
    @objc private func transitTurnsView(_ sender: UIButton? = nil) {
        animateTurnsView()
        //hides/shows timers, when shows/hides turnsView
        if gameLogic.timerEnabled {
            animateTransition(of: player1Timer, startAlpha: player1Timer.alpha)
            animateTransition(of: player2Timer, startAlpha: player2Timer.alpha)
        }
    }
    
    //exits from game
    @objc private func exit(_ sender: UIButton? = nil) {
        let exitAlert = UIAlertController(title: "Exit", message: "Are you sure?", preferredStyle: .alert)
        exitAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            if let self = self {
                self.stopTurnsPlayback()
                self.finishAnimations()
                if self.gameLogic.gameMode == .multiplayer && !self.gameLogic.gameEnded {
                    self.gameLogic.surrender(for: .player1)
                    self.storage.saveUser(self.currentUser)
                    if let gameStatusJson = try? JSONEncoder().encode(PlayerMessage(gameID: self.gameLogic.gameID!, playerType: self.gameLogic.players.first!.multiplayerType!, gameEnded: true)) {
                        self.socket.write(data: gameStatusJson)
                    }
                }
                if let mainMenuVC = self.presentingViewController as? MainMenuVC {
                    mainMenuVC.currentUser = self.currentUser
                }
                self.dismiss(animated: true)
            }
        }))
        exitAlert.addAction(UIAlertAction(title: "No", style: .cancel))
        present(exitAlert, animated: true)
    }
    
    //saves game in oneScreen mode
    @objc private func saveGame(_ sender: UIButton? = nil) {
        if !animatingTurns {
            let alert = UIAlertController(title: "Action completed", message: "Game saved!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            currentUser.addGame(gameLogic)
            storage.saveUser(currentUser)
            gameLogic.saveGameDataForRestore()
            restoreButton.isEnabled = gameLogic.rewindEnabled
            present(alert, animated: true)
        }
    }
    
    //moves game back
    @objc private func turnsBackward(_ sender: UIButton? = nil) {
        if !animatingTurns {
            moveTurn(forward: false)
        }
    }
    
    //moves game forward
    @objc private func turnsForward(_ sender: UIButton? = nil) {
        if !animatingTurns {
            moveTurn(forward: true)
        }
    }
    
    //stops/activates game playback
    @objc private func turnsAction(_ sender: UIButton? = nil) {
        if turnsActionTimers.isEmpty && !animatingTurns {
            toggleTurnButtons(disable: true)
            if fastAnimations {
                DispatchQueue.global().async {[weak self] in
                    if let self = self {
                        self.moveTurns(to: self.gameLogic.turns.last!, animate: false)
                    }
                }
            }
            else {
                moveTurns(to: gameLogic.turns.last!, animate: true)
            }
        }
        else if !turnsActionTimers.isEmpty {
            stopTurnsPlayback()
            toggleTurnButtons(disable: false)
        }
    }
    
    //moves game to chosen turn
    @objc private func moveToTurn(_ sender: UITapGestureRecognizer? = nil) {
        if let turn = sender?.view?.layer.value(forKey: constants.keyNameForTurn) as? Turn {
            if turn != gameLogic.currentTurn && !animatingTurns {
                toggleTurnButtons(disable: true)
                if fastAnimations {
                    DispatchQueue.global().async {[weak self] in
                        if let self = self {
                            self.moveTurns(to: turn, animate: false)
                        }
                    }
                }
                else {
                    moveTurns(to: turn, animate: true)
                }
            }
        }
    }

    // MARK: - Local Methods
    
    private func makeReconnectTimer() {
        pawnPicker.isUserInteractionEnabled = false
        toggleTurnButtons(disable: true)
        reconnectTimer?.invalidate()
        makeLoadingSpinner()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: constants.requestTimeout, repeats: false, block: { [weak self] _ in
            if let self = self {
                if self.gameLogic.currentPlayer.type == .player1 {
                    self.toggleTurnButtons(disable: false)
                    self.pawnPicker.isUserInteractionEnabled = true
                }
                else {
                    self.surrenderButton.isEnabled = true
                    self.exitButton.isEnabled = true
                }
                self.loadingSpinner.removeFromSuperview()
                if (!self.isConnected || !self.connectedToTheInternet) && !self.finalError {
                    self.makeErrorAlert(with: "You are not connected to the server", addReconnectButton: true)
                }
            }
        })
        socket.connect()
    }
    
    private func deactivateMultiplayerTImers() {
        afkTimer?.invalidate()
        enemyAfkTimer?.invalidate()
        pingTimer?.invalidate()
        cancelGameTimer?.invalidate()
        reconnectTimer?.invalidate()
        monitor.pathUpdateHandler = nil
    }
    
    private func configureForMultiplayer() {
        configureNWPathMonitor()
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
        toggleTurnButtons(disable: true)
        makeLoadingSpinner()
        socket.delegate = self
        websocketDidConnect()
        pingTimer = Timer.scheduledTimer(withTimeInterval: constants.requestTimeout, repeats: true, block: { [weak self] _ in
            if let jsonData = try? JSONEncoder().encode("Hello") {
                self?.socket.write(ping: jsonData)
            }
        })
        cancelGameTimer = Timer.scheduledTimer(withTimeInterval: constants.requestTimeout, repeats: false, block: { [weak self] _ in
            if let self = self {
                self.makeErrorAlert(with: "Game was cancelled")
                self.currentUser.removeGame(self.gameLogic)
                self.storage.saveUser(self.currentUser)
            }
        })
    }
    
    //TODO: - Need to be tested on real devices with real server
    //not working properly on simulators
    private func configureNWPathMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            if let self = self {
                DispatchQueue.main.sync {
                    if path.status == .satisfied {
                        self.connectedToTheInternet = true
                        if self.gameLogic.currentPlayer.type == .player2 {
                            if let enemyAfkTimer = self.enemyAfkTimer, !enemyAfkTimer.isValid {
                                var timeElapsed = Date().timeIntervalSince(self.gameLogic.turns.last?.time ?? self.gameLogic.startDate)
                                if timeElapsed > constants.maxTimeForAFK {
                                    timeElapsed = constants.maxTimeForAFK
                                }
                                self.enemyAfkTimer? = self.makeAfkTimer(for: .player2, timeElapsed: timeElapsed)
                            }
                        }
                    }
                    else {
                        if self.gameLogic.currentPlayer.type == .player2 {
                            self.enemyAfkTimer?.invalidate()
                        }
                        self.isConnected = false
                        self.connectedToTheInternet = false
                        self.makeReconnectTimer()
                        self.needToRequestLastAction = true
                    }
                }
            }
        }
    }
    //
    
    func switchToSuspendedState() {
        if !gameLogic.gameEnded {
            suspendedState = true
        }
    }
    
    func restoreFromSuspendedState() {
        suspendedState = false
        if !gameLogic.gameEnded {
            let currentDate = Date()
            var lastTurn: Turn?
            if gameLogic.turns.count > 1 {
                if gameLogic.pawnWizard || gameLogic.turns.last!.shortCastle || gameLogic.turns.last!.longCastle {
                    lastTurn = gameLogic.turns.beforeLast
                }
                else {
                    lastTurn = gameLogic.turns.last
                }
            }
            else if !gameLogic.turns.isEmpty {
                lastTurn = gameLogic.turns.last
            }
            var interval = currentDate.timeIntervalSince(lastTurn?.time ?? gameLogic.startDate)
            if interval < constants.maxTimeForAFK {
                if gameLogic.currentPlayer.type == .player1 {
                    interval = ceil(interval) + constants.chessTimerStep
                    afkTimer?.invalidate()
                    afkTimer = makeAfkTimer(for: .player1, timeElapsed: interval)
                }
                else {
                    interval = floor(interval) - constants.chessTimerStep
                    enemyAfkTimer?.invalidate()
                    enemyAfkTimer = makeAfkTimer(for: .player2, timeElapsed: interval)
                }
                let newTimeLeft = gameLogic.currentPlayer.timeLeft - Int(interval)
                var extraTime = 0.0
                if gameLogic.gameMode == .multiplayer {
                    if gameLogic.currentPlayer == gameLogic.players.second && newTimeLeft < Int(constants.requestTimeout) {
                        extraTime = constants.extraTimeForEnemyAFKTimer
                    }
                }
                if !gameLogic.turns.isEmpty && gameLogic.timerEnabled {
                    gameLogic.updateTimeLeft(with: newTimeLeft + Int(extraTime), countAdditionalTime: false)
                }
                if isConnected || gameLogic.gameMode != .multiplayer {
                    needToRequestLastAction = false
                }
                else {
                    needToRequestLastAction = true
                    makeReconnectTimer()
                }
            }
            else {
                surrenderAction()
                makeErrorAlert(with: "You lost the game, because you was afk for more than 5 minutes")
            }
        }
    }
    
    private func surrenderAction(for player: GamePlayers = .player1) {
        if gameLogic.gameMode == .multiplayer && !gameLogic.gameEnded && isConnected {
            gameLogic.surrender(for: player)
            if let gameStatusJson = try? JSONEncoder().encode(PlayerMessage(gameID: gameLogic.gameID!, playerType: gameLogic.players.first!.multiplayerType!, gameEnded: true, playerToSurrender: player == .player1 ? .player2: .player1)) {
                socket.write(data: gameStatusJson)
            }
        }
        else if !gameLogic.gameEnded {
            gameLogic.surrender()
        }
        if view.subviews.first(where: {$0 == endOfTheGameView}) == nil {
            makeEndOfTheGameView()
        }
    }

    //timeElapsed is used, when app was in suspended state and during that time
    //enemy made a turn
    private func makeAfkTimer(for player: GamePlayers, timeElapsed: Double = 0) -> Timer {
        //in case, if problems with server, we will wait a little longer for enemy turn
        let extraTime: Double = player == .player2 ? constants.extraTimeForEnemyAFKTimer : 0
        return Timer.scheduledTimer(withTimeInterval: constants.maxTimeForAFK + extraTime - timeElapsed, repeats: false, block: { [weak self] _ in
            if let self = self {
                if !self.serverError {
                    if player == .player1 && !self.gameLogic.gameEnded {
                        self.makeErrorAlert(with: "You lost the game, because you was afk for more than 5 minutes", afkError: true)
                    }
                    self.surrenderAction(for: player)
                }
                else if !self.gameLogic.gameEnded {
                    self.finalError = true
                    self.makeErrorAlert(with: "Server is not working")
                }
            }
        })
    }
    
    private func makeErrorAlert(with message: String, addReconnectButton: Bool = false, afkError: Bool = false) {
        if !suspendedState || afkError {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
                if let self = self {
                    self.stopTurnsPlayback()
                    self.finishAnimations()
                    if let mainMenuVC = self.presentingViewController as? MainMenuVC {
                        mainMenuVC.currentUser = self.currentUser
                    }
                    self.dismiss(animated: true)
                }
            })
            if addReconnectButton {
                alert.addAction(UIAlertAction(title: "Reconnect", style: .default) { [weak self] _ in
                    if let self = self {
                        if !self.isConnected || !self.connectedToTheInternet {
                            self.makeReconnectTimer()
                        }
                    }
                })
            }
            if let topVC = UIApplication.getTopMostViewController(), topVC as? UIAlertController != nil {
                topVC.dismiss(animated: true, completion: {
                    if let topVC = UIApplication.getTopMostViewController() {
                        topVC.present(alert, animated: true)
                    }
                })
            }
            else if let topVC = UIApplication.getTopMostViewController() {
                topVC.present(alert, animated: true)
            }
        }
    }
    
    private func rotateScrollContent(reverse: Bool = false) {
        let transform = reverse ? CGAffineTransform.identity : CGAffineTransform(rotationAngle: .pi)
        //will not rotate figures, if we already in correct state
        //we need this, cuz we don`t store rotation of figures
        if scrollContentOfGame.transform != transform {
            scrollContentOfGame.transform = transform
            //if we have same rotation for both figures, we don`t want to rotate them with content rotation
            //in other words, if figures aren`t rotated, after content rotation, they will be rotated(upside down)
            //and we want to avoid that
            if player1RotateFiguresButton.transform == player2RotateFiguresButton.transform {
                rotateAllFigures()
            }
            scrollViewOfGame.scrollToViewAndCenterOnScreen(view: gameBoard, animated: false)
        }
    }
    
    private func rotateAllFigures() {
        if player1RotateFiguresButton.transform == .identity {
            player1RotateFiguresButton.transform = CGAffineTransform(rotationAngle: .pi)
            player2RotateFiguresButton.transform = CGAffineTransform(rotationAngle: .pi)
        }
        else {
            player1RotateFiguresButton.transform = .identity
            player2RotateFiguresButton.transform = .identity
        }
        rotateFiguresInSquares()
    }
    
    private func rotateFiguresInSquares(with color: GameColors? = nil) {
        for squareView in squares {
            if let square = squareView.layer.value(forKey: constants.keyNameForSquare) as? Square {
                if square.figure?.color == color || color == nil {
                    for subview in squareView.subviews {
                        if let figureImageView = subview as? UIImageView {
                            figureImageView.image = figureImageView.image?.rotate(radians: .pi)
                        }
                    }
                }
            }
        }
        for squareView in pawnPicker.subviews {
            if let square = squareView.layer.value(forKey: constants.keyNameForSquare) as? Square {
                if square.figure?.color == color || color == nil {
                    if let figureImageView = squareView.subviews.second as? UIImageView {
                        figureImageView.image = figureImageView.image?.rotate(radians: .pi)
                    }
                }
            }
        }
        if color == gameLogic.players.first!.figuresColor || color == nil {
            rotateFiguresIn(destroyedFigures2)
        }
        if color == gameLogic.players.second!.figuresColor || color == nil {
            rotateFiguresIn(destroyedFigures1)
        }
        checkSpecialFigureView(figureToTrash, color: color, operation: {$0 != $1})
        checkSpecialFigureView(figureFromTrash, color: color, operation: {$0 == $1})
        for figureInMotion in figuresInMotion {
            checkSpecialFigureView(figureInMotion, color: color, operation: {$0 == $1})
        }
        transformViews([player1FrameForDF, player1Timer, player1FrameView, player1TitleView], with: player1RotateFiguresButton.transform)
        transformViews([player2FrameForDF, player2Timer, player2FrameView, player2TitleView], with: player2RotateFiguresButton.transform)
    }
    
    private func transformViews(_ views: [UIView], with transform: CGAffineTransform) {
        for view in views {
            view.transform = transform
        }
    }
    
    //we have some rotation animations when we animating turn
    //this function is used to prevent double rotation
    //and also figure can be in wrong place, cuz animation don`t finish, so we also need to rotate her
    private func checkSpecialFigureView(_ figureView: UIView?, color: GameColors?, operation: @escaping (GameColors, GameColors) -> Bool) {
        if let figureView = figureView {
            if let figureData = figureView.layer.value(forKey: constants.keyForFIgure) as? Figure, color != nil ? operation(figureData.color, color!) : true {
                if let figureImageView = figureView as? UIImageView {
                    figureImageView.image = figureImageView.image?.rotate(radians: .pi)
                }
            }
        }
    }
    
    private func updatePlayersTime() {
        if gameLogic.timerEnabled {
            player1Timer.text = gameLogic.players.first!.timeLeft.timeAsString
            player2Timer.text = gameLogic.players.second!.timeLeft.timeAsString
            player1TimerForTurns.text = gameLogic.players.first!.timeLeft.timeAsString
            player2TimerForTurns.text = gameLogic.players.second!.timeLeft.timeAsString
        }
    }
    
    private func rotateFiguresIn(_ destroyedFiguresView: UIView) {
        for subview in destroyedFiguresView.subviews {
            if let figuresStack = subview as? UIStackView {
                for figureView in figuresStack.arrangedSubviews {
                    if figureView != figureFromTrash {
                        if let figureImageView = figureView as? UIImageView {
                            figureImageView.image = figureImageView.image?.rotate(radians: .pi)
                        }
                    }
                }
            }
            if let background = subview as? UIImageView {
                background.image = background.image?.rotate(radians: .pi)
            }
        }
    }
    
    private func removeFiguresFrom(_ destroyedFiguresView: UIView) {
        for subview in destroyedFiguresView.subviews {
            if let figuresStack = subview as? UIStackView {
                for figureView in figuresStack.arrangedSubviews {
                    figureView.removeFromSuperview()
                }
            }
        }
    }
    
    //when user wants to restore turns instantly
    private func replaceFiguresInSquares() {
        let player1figuresThemeName = gameLogic.players.first!.user.figuresTheme.rawValue
        let player2figuresThemeName = gameLogic.players.second!.user.figuresTheme.rawValue
        let width = min(view.frame.width, view.frame.height)  / constants.dividerForSquare
        for squareView in squares {
            if let oldSquare = squareView.layer.value(forKey: constants.keyNameForSquare) as? Square {
                let newSquare = gameLogic.gameBoard.squares.first(where: {$0 == oldSquare})
                if let newSquare = newSquare {
                    if let figure = squareView.subviews.second {
                        figure.removeFromSuperview()
                    }
                    squareView.layer.setValue(newSquare, forKey: constants.keyNameForSquare)
                    if let figure = newSquare.figure {
                        let figuresThemeName = figure.color == gameLogic.players.first?.figuresColor ? player1figuresThemeName : player2figuresThemeName
                        var figureImage: UIImage?
                        figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(figure.color.rawValue)_\(figure.name.rawValue)")
                        let figureButton = gameLogic.players.first?.figuresColor == figure.color ? player1RotateFiguresButton : player2RotateFiguresButton
                        if figureButton.transform != .identity {
                            //we are not using transform here to not have problems with animation
                            figureImage = figureImage?.rotate(radians: .pi)
                        }
                        let figureView = UIImageView()
                        figureView.rectangleView(width: width)
                        figureView.layer.borderWidth = 0
                        figureView.image = figureImage
                        figureView.layer.setValue(figure, forKey: constants.keyForFIgure)
                        squareView.addSubview(figureView)
                    }
                }
            }
        }
    }
    
    //disables/enables turnsView buttons
    private func toggleTurnButtons(disable: Bool) {
        restoreButton.isEnabled = !gameLogic.storedTurns.isEmpty ? !disable : false
        //don`t allows user interact with gameboard during animation
        for arrangedSubview in gameBoard.arrangedSubviews[1...8] {
            arrangedSubview.isUserInteractionEnabled = !disable
        }
        let condition = (gameLogic.gameEnded || gameLogic.rewindEnabled) && !gameLogic.turns.isEmpty
        turns.isUserInteractionEnabled = condition ? !disable : false
        turnBackward.isEnabled = disable ? !disable : condition && !gameLogic.firstTurn
        turnForward.isEnabled = disable ? !disable : condition && !gameLogic.lastTurn
        if gameLogic.gameMode == .oneScreen || gameLogic.gameEnded {
            let turnActionImage = disable ? UIImage(systemName: "stop") : UIImage(systemName: "play")
            turnAction.setImage(turnActionImage, for: .normal)
        }
        turnAction.isEnabled = disable ? !disable : condition && !gameLogic.lastTurn
        fastAnimationsButton.isEnabled = disable ? !fastAnimations && !restoringTurns : !disable
        saveButton.isEnabled = disable ? !disable : !gameLogic.gameEnded && !gameLogic.turns.isEmpty
        surrenderButton.isEnabled = disable ? gameLogic.gameMode == .multiplayer && !gameLogic.gameEnded && isConnected && connectedToTheInternet : !gameLogic.gameEnded
        animatingTurns = disable ? gameLogic.gameMode == .oneScreen || gameLogic.gameEnded : disable
        exitButton.isEnabled = !disable ? !disable : !fastAnimations && !restoringTurns && ((isConnected && connectedToTheInternet) || gameLogic.gameMode == .oneScreen)
        player1RotateFiguresButton.isEnabled = disable ? !fastAnimations && !restoringTurns : !disable
        player2RotateFiguresButton.isEnabled = disable ? !fastAnimations && !restoringTurns : !disable
        stopTurnsPlayback()
        rotateScrollContent(reverse: !(gameBoardAutoRotate && gameLogic.currentPlayer.type == .player2))
    }
    
    //described in viewWillTransition
    private func checkOrientationAndUpdateConstraints(size: CGSize, orientation: UIDeviceOrientation) {
        let operation: (CGFloat, CGFloat) -> Bool = orientation.isLandscape ? {$0 / $1 < 1} : {$0 / $1 > 1}
        if operation(size.width, size.height) {
            updateConstraints(portrait: orientation.isLandscape)
        }
        //puts gameBoard in center of the screen
        scrollViewOfGame.scrollToViewAndCenterOnScreen(view: gameBoard, animated: true)
    }
    
    private func activateStartConstraints() {
        let screenSize: CGSize = UIScreen.main.bounds.size
        let widthForFrame = min(view.frame.width, view.frame.height)  / constants.widthDividerForTrash
        //checks if we have enough space to put player data left and right from gameBoard,
        //otherwise we will use special constraints for landscape mode
        specialLayout = gameBoard.frame.size.width + widthForFrame > max(scrollContentOfGame.layoutMarginsGuide.layoutFrame.width, scrollContentOfGame.layoutMarginsGuide.layoutFrame.height)
        if screenSize.width / screenSize.height < 1 {
            NSLayoutConstraint.activate(portraitConstraints)
        }
        else if screenSize.width / screenSize.height > 1 {
            arrowToAdditionalButtons.transform = CGAffineTransform(rotationAngle: .pi * 1.5)
            additionalButton.transform = CGAffineTransform(rotationAngle: .pi * 1.5)
            currentTransformOfArrow = CGAffineTransform(rotationAngle: .pi * 1.5)
            if !specialLayout {
                NSLayoutConstraint.activate(landscapeConstraints)
            }
            else {
                NSLayoutConstraint.activate(portraitConstraints)
                NSLayoutConstraint.deactivate(timerConstraints)
                NSLayoutConstraint.deactivate(additionalButtonConstraints)
                NSLayoutConstraint.activate(specialConstraints)
            }
        }
        updateLayout()
    }
    
    private func updateLayout() {
        player2FrameView.setNeedsDisplay()
        player1FrameView.setNeedsDisplay()
        player2TitleView.setNeedsDisplay()
        player1TitleView.setNeedsDisplay()
        playerProgress.setNeedsDisplay()
        view.layoutIfNeeded()
    }
    
    private func stopTurnsPlayback() {
        for timer in turnsActionTimers {
            timer.invalidate()
        }
        turnsActionTimers = []
    }
    
    private func finishAnimations() {
        for animation in animations {
            animation.stopAnimation(false)
            animation.finishAnimation(at: .end)
        }
        animations = []
    }
    
    private func activatePlayerTime(continueTimer: Bool = false) {
        if gameLogic.timerEnabled && !gameLogic.gameEnded && (!gameLogic.pawnWizard || continueTimer) {
            if !continueTimer {
                updatePlayersTime()
                Timer.scheduledTimer(withTimeInterval: constants.animationDuration, repeats: false, block: {[weak self] _ in
                    if let self = self {
                        self.startPlayerTime(continueTimer: continueTimer)
                    }
                })
            }
            else {
                startPlayerTime(continueTimer: continueTimer)
            }
        }
    }
    
    private func startPlayerTime(continueTimer: Bool) {
        gameLogic.activateTime(continueTimer: continueTimer, callback: {[weak self] time in
            if let self = self {
                if !self.isConnected && self.gameLogic.gameMode == .multiplayer && self.connectedToTheInternet {
                    self.gameLogic.stopTime()
                }
                if !self.connectedToTheInternet && self.gameLogic.gameMode == .multiplayer && self.gameLogic.currentPlayer.type == .player2 {
                    if self.gameLogic.timeLeft <= Int(constants.extraTimeForEnemyAFKTimer) {
                        self.gameLogic.stopTime()
                    }
                }
                if time == 0 && self.view.subviews.first(where: {$0 == self.endOfTheGameView}) == nil {
                    self.makeEndOfTheGameView()
                }
                if self.gameLogic.currentPlayer.type == .player1 {
                    self.player1Timer.text = time.timeAsString
                    self.player1TimerForTurns.text = time.timeAsString
                    if self.gameLogic.timeLeft < constants.dangerTimeleft {
                        let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {
                            self.player1Timer.layer.backgroundColor = constants.dangerPlayerDataColor.cgColor
                            self.player1TimerForTurns.layer.backgroundColor = constants.dangerPlayerDataColor.cgColor
                        })
                        self.animations.append(animation)
                    }
                }
                else {
                    self.player2Timer.text = time.timeAsString
                    self.player2TimerForTurns.text = time.timeAsString
                    if self.gameLogic.timeLeft < constants.dangerTimeleft {
                        let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {
                            self.player2Timer.layer.backgroundColor = constants.dangerPlayerDataColor.cgColor
                            self.player2TimerForTurns.layer.backgroundColor = constants.dangerPlayerDataColor.cgColor
                        })
                        self.animations.append(animation)
                    }
                }
            }
        })
    }
    
    //moves turns backward or forward with animation and activates turnsView buttons, if it`s last turn to animate
    //if we have many turns to animate without timers we are doing it asynchronously, cuz it could take some seconds, which will freeze UI
    //and also we can`t update UI asynchronously, cuz before animating new turns, we need to be sure that gameBoard is in correct state
    private func moveTurn(forward: Bool, activateTurnButtons: Bool = true, animated: Bool = false) {
        //we need to stop all animations, before performing new ones, to be sure, that gameboard is in correct state
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                finishAnimations()
            }
        }
        else {
            finishAnimations()
        }
        forward == true ? forwardRewind.toggle() : backwardRewind.toggle()
        let turn = forward == true ? gameLogic.forward() : gameLogic.backward()
        var castleTurn: Turn?
        if let turn = turn {
            if turn.shortCastle || turn.longCastle {
                //we need to animate 2 turns, if it`s castle
                castleTurn = forward == true ? gameLogic.forward() : gameLogic.backward()
            }
        }
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                updateUIAfterRewind(activateTurnButtons: activateTurnButtons, turn: turn, castleTurn: castleTurn)
            }
        }
        else {
            updateUIAfterRewind(activateTurnButtons: activateTurnButtons, turn: turn, castleTurn: castleTurn)
        }
        forward == true ? forwardRewind.toggle() : backwardRewind.toggle()
    }
    
    private func updateUIAfterRewind(activateTurnButtons: Bool, turn: Turn?, castleTurn: Turn?) {
        if let turn = turn {
            animateTurn(turn)
        }
        if let castleTurn = castleTurn {
            animateTurn(castleTurn)
        }
        updatePlayersTime()
        updateUI(animateSquares: true)
        if activateTurnButtons && !restoringTurns {
            if gameLogic.currentTurn == chosenTurn {
                chosenTurn = nil
            }
            toggleTurnButtons(disable: false)
        }
    }
    
    //used to move figures from trash back to the game
    private func coordinatesToMoveFigureFrom(firstView: UIView, to secondView: UIView) -> (x: CGFloat, y: CGFloat) {
        destroyedFigures1.layoutIfNeeded()
        destroyedFigures2.layoutIfNeeded()
        let frame = getFrameForAnimation(firstView: firstView, secondView: secondView)
        let x = frame.minX - secondView.bounds.minX
        let y = frame.maxY - secondView.bounds.maxY
        return (x,y)
    }
    
    //moves game to chosen turn
    private func moveTurns(to turn: Turn, animate: Bool = true) {
        var delay = 0.0
        chosenTurn = turn
        let turnsInfo = gameLogic.turnsLeft(to: turn)
        let turnsLeft = turnsInfo.count
        let forward = turnsInfo.forward
        if turnsLeft > 0 {
            if animate && Thread.isMainThread {
                //before we start animating turns, we need to put gameBoard in center of the screen
                if !scrollViewOfGame.checkIfViewInCenterOfTheScreen(view: gameBoard) {
                    scrollViewOfGame.scrollToViewAndCenterOnScreen(view: gameBoard, animated: true)
                    delay = constants.animationDuration
                }
                for i in 0..<turnsLeft {
                    let isLastTurnToAnimate = i == turnsLeft - 1
                    //chaining animations to create playback
                    //we are assuming that our logic will calculate turn in less than animationDuration
                    //otherwise it will not work as expected and app could freeze
                    //other solution is to make a recursive function, which assign new timer to callback of previous
                    //but anyway, if our logic will calculate turn for so long, it`s pretty bad, so no need in that function
                    //in average it is 0.025 seconds for 1 turn
                    let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: {[weak self] _ in
                        if let self = self {
                            self.moveTurn(forward: forward, activateTurnButtons: isLastTurnToAnimate, animated: true)
                        }
                    })
                    //prevent animations from stop, when scrolling
                    RunLoop.main.add(timer, forMode: .common)
                    turnsActionTimers.append(timer)
                    //if there is no animation, it means all our logic turns will be calculated syncronously without any delay,
                    //so we have to wait for calculations to finish and there is no way for us to make them slower, cuz they all already processing
                    //in other situiation it`s possible, cuz we simply cancel all timers and calculating all turns without them,
                    //which will make them faster
                    turnAction.isEnabled = animate
                    fastAnimationsButton.isEnabled = animate
                    delay += constants.animationDuration
                }
            }
            else {
                for i in 0..<turnsLeft {
                    let isLastTurnToAnimate = i == turnsLeft - 1
                    moveTurn(forward: forward, activateTurnButtons: isLastTurnToAnimate)
                }
            }
        }
        else {
            DispatchQueue.main.async {[weak self] in
                self?.chosenTurn = nil
                self?.toggleTurnButtons(disable: false)
            }
        }
    }
    
    //changes figure on square; used when transforming pawn
    private func updateSquare(_ square: Square, figure: Figure) {
        if let squareView = squares.first(where: {$0.layer.value(forKey: constants.keyNameForSquare) as? Square == square}) {
            var square = squareView.layer.value(forKey: constants.keyNameForSquare) as? Square
            square?.updateFigure(newValue: figure)
            squareView.layer.setValue(square, forKey: constants.keyNameForSquare)
            //when we have forward rewind and pawn is about to eat a figure,
            //we will have 2 figures at that time, when we will transform pawn
            //P.S. first subview is a border
            if squareView.subviews.count == 3 {
                squareView.subviews.third!.removeFromSuperview()
            }
            else if squareView.subviews.count == 2 {
                squareView.subviews.second!.removeFromSuperview()
            }
            let themeName = gameLogic.currentPlayer.user.figuresTheme.rawValue
            let figureButton = gameLogic.players.first?.figuresColor == figure.color ? player1RotateFiguresButton : player2RotateFiguresButton
            var figureImage = UIImage(named: "figuresThemes/\(themeName)/\(figure.color.rawValue)_\(figure.name.rawValue)")
            if figureButton.transform != .identity {
                figureImage = figureImage?.rotate(radians: .pi)
            }
            let figureView = getSquareView(image: figureImage, figure: figure).subviews.second!
            figureView.layer.borderWidth = 0
            squareView.addSubview(figureView)
            let figureViewConstraints = [figureView.centerXAnchor.constraint(equalTo: squareView.centerXAnchor), figureView.centerYAnchor.constraint(equalTo: squareView.centerYAnchor)]
            NSLayoutConstraint.activate(figureViewConstraints)
            for subview in pawnPicker.arrangedSubviews {
                subview.removeFromSuperview()
            }
            pawnPicker.removeFromSuperview()
        }
        updateUI()
    }
    
    //updates Ui
    private func updateUI(animateSquares: Bool = false) {
        updateSquares(animate: animateSquares)
        updateCurrentPlayer()
        updateCurrentTurn()
    }
    
    //updates UI, if game was loaded and/or not in start state
    private func updateUIIfLoad() {
        for turn in gameLogic.turns {
            if (!turn.shortCastle && !turn.longCastle) || turn.squares.first?.figure?.name == .rook {
                addTurnToUI(turn)
            }
        }
        for player in gameLogic.players {
            for figure in player.destroyedFigures {
                var figureImage: UIImage?
                let figuresThemeName = player.user.figuresTheme.rawValue
                figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(figure.color.rawValue)_\(figure.name.rawValue)")
                let figureButton = gameLogic.players.first?.figuresColor == figure.color ? player2RotateFiguresButton : player1RotateFiguresButton
                if figureButton.transform != .identity {
                    //we are not using transform here to not have problems with animation
                    figureImage = figureImage?.rotate(radians: .pi)
                }
                let squareView = getSquareView(image: figureImage, figure: figure)
                if let figureView = squareView.subviews.last {
                    switch player.type {
                    case .player1:
                        addFigureToTrash(player: .player1, destroyedFiguresStack1: player1DestroyedFigures1, destroyedFiguresStack2: player1DestroyedFigures2, figure: figureView)
                    case .player2:
                        addFigureToTrash(player: .player2, destroyedFiguresStack1: player2DestroyedFigures1, destroyedFiguresStack2: player2DestroyedFigures2, figure: figureView)
                    }
                }
            }
        }
    }
    
    //updates game board
    private func updateBoard() {
        if gameLogic.pickedSquares.count > 1 {
            finishAnimations()
        }
        if (gameLogic.currentTurn?.shortCastle ?? false || gameLogic.currentTurn?.longCastle ?? false) && gameLogic.pickedSquares.count > 1 {
            animateTurn(gameLogic.turns.beforeLast!)
            animateTurn(gameLogic.turns.last!)
            addTurnToUI(gameLogic.turns.last!)
            activatePlayerTime()
            toggleTurnButtons(disable: false)
            updateUI(animateSquares: true)
            rotateScrollContent(reverse: !(gameBoardAutoRotate && gameLogic.currentPlayer.type == .player2))
            if gameLogic.gameMode == .multiplayer && gameLogic.currentPlayer.multiplayerType != gameLogic.players.first?.multiplayerType && shouldSendTurn {
                if gameLogic.gameEnded {
                    shouldSendTurn = false
                }
                if let turnJson = try? JSONEncoder().encode(gameLogic.turns.beforeLast!) {
                    socket.write(data: turnJson)
                }
                toggleTurnButtons(disable: true)
                afkTimer?.invalidate()
                enemyAfkTimer = makeAfkTimer(for: .player2)
            }
        }
        else if gameLogic.pickedSquares.count > 1 {
            activatePlayerTime()
            if let turn = gameLogic.turns.last {
                if gameLogic.pawnWizard {
                    toggleTurnButtons(disable: true)
                    if let figure = turn.squares.first!.figure {
                        showPawnPicker(square: turn.squares.second!, figure: figure)
                    }
                }
                else {
                    addTurnToUI(turn)
                }
                animateTurn(turn)
                toggleTurnButtons(disable: false)
                updateUI(animateSquares: true)
                rotateScrollContent(reverse: !(gameBoardAutoRotate && gameLogic.currentPlayer.type == .player2))
                //second condition is different than above for pawnWizard case
                //when pawnWizard gameLogic.currentPlayer.multiplayerType != gameLogic.players.first?.multiplayerType, but we don`t
                //need to send that turn 2 times
                if gameLogic.gameMode == .multiplayer && turn.squares.first?.figure?.color == gameLogic.players.first?.figuresColor && shouldSendTurn {
                    if gameLogic.gameEnded {
                        shouldSendTurn = false
                    }
                    if let turnJson = try? JSONEncoder().encode(turn) {
                        socket.write(data: turnJson)
                    }
                    toggleTurnButtons(disable: true)
                    if !gameLogic.pawnWizard {
                        afkTimer?.invalidate()
                        enemyAfkTimer = makeAfkTimer(for: .player2)
                    }
                }
            }
        }
        else {
            updateSquares()
        }
    }
    
    private func addTurnToUI(_ turn: Turn) {
        deleteTurnsIfGameChanged()
        let thisTurnData = UIStackView()
        thisTurnData.setup(axis: .horizontal, alignment: .fill, distribution: .fill, spacing: constants.optimalSpacing)
        thisTurnData.defaultSettings()
        thisTurnData.backgroundColor = thisTurnData.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        var firstFigureView: UIImageView?
        var secondFigureView: UIImageView?
        var pawnTransformFigureView: UIImageView?
        let firstFigure = turn.squares.first?.figure
        let playerOfTurn = turn.squares.first?.figure?.color == gameLogic.players.first?.figuresColor ? gameLogic.players.first! : gameLogic.players.second!
        let enemyPlayer = playerOfTurn.type == .player1 ? gameLogic.players.second! : gameLogic.players.first!
        if let firstFigure = firstFigure {
            firstFigureView = makeFigureView(of: playerOfTurn, with: firstFigure.name.rawValue)
            //we are adding castle as one turn
            if turn.shortCastle || turn.longCastle {
                let kingView = makeFigureView(of: playerOfTurn, with: Figures.king.rawValue)
                thisTurnData.addArrangedSubview(kingView)
            }
        }
        let secondFigure = turn.squares.second?.figure == nil ? turn.pawnSquare?.figure : turn.squares.second?.figure
        if let secondFigure = secondFigure {
            secondFigureView = makeFigureView(of: enemyPlayer, with: secondFigure.name.rawValue)
        }
        if let figure = turn.pawnTransform {
            pawnTransformFigureView = makeFigureView(of: playerOfTurn, with: figure.name.rawValue)
        }
        let turnLabel = makeTurnLabel(from: turn)
        if let firstFigureView = firstFigureView {
            thisTurnData.addArrangedSubview(firstFigureView)
        }
        thisTurnData.layer.setValue(turn, forKey: constants.keyNameForTurn)
        let tap = UITapGestureRecognizer(target: self, action: #selector(moveToTurn))
        thisTurnData.addGestureRecognizer(tap)
        thisTurnData.addArrangedSubview(turnLabel)
        if let secondFigureView = secondFigureView {
            thisTurnData.addArrangedSubview(secondFigureView)
        }
        if let pawnTransformFigureView = pawnTransformFigureView {
            thisTurnData.addArrangedSubview(pawnTransformFigureView)
        }
        if turnData.arrangedSubviews.isEmpty {
            turnData.addArrangedSubview(thisTurnData)
            //spacer is used to make stacks same size no matter if they contain 1 or 2 turns
            let spacerView = UIView()
            turnData.addArrangedSubview(spacerView)
            turns.addArrangedSubview(turnData)
            animateTransition(of: thisTurnData)
        }
        else if turnData.arrangedSubviews.count == 2 {
            //removes spacer before adding second turn
            turnData.arrangedSubviews.last!.removeFromSuperview()
            turnData.addArrangedSubview(thisTurnData)
            animateTransition(of: thisTurnData)
            makeEmptyTurnData()
        }
    }
    
    private func makeTurnLabel(from turn: Turn) -> UILabel {
        var firstSqureText = turn.squares.first!.column.rawValue + String(turn.squares.first!.row)
        var secondSqureText = turn.squares.second!.column.rawValue + String(turn.squares.second!.row)
        if turn.shortCastle || turn.longCastle {
            if turn.shortCastle {
                firstSqureText = constants.shortCastleNotation
            }
            else {
                firstSqureText = constants.longCastleNotation
            }
            secondSqureText = ""
        }
        if turn.checkMate {
            secondSqureText += constants.checkmateNotation
        }
        else if turn.check {
            secondSqureText += constants.checkNotation
        }
        if turn.squares.second?.figure != nil || turn.pawnSquare != nil {
            firstSqureText += constants.figureEatenNotation
        }
        let turnText = firstSqureText.lowercased() + secondSqureText.lowercased()
        let turnLabel = makeLabel(text: turnText)
        return turnLabel
    }
    
    private func makeFigureView(of player: Player, with figureName: String) -> UIImageView {
        let figuresThemeName = player.user.figuresTheme.rawValue
        let figureColor = player.figuresColor.rawValue
        let figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(figureColor)_\(figureName)")
        let figureImageView = getSquareView(image: figureImage)
        figureImageView.subviews.first!.layer.borderWidth = 0
        return figureImageView
    }
    
    //when player changed game, we need to update turns UI
    private func deleteTurnsIfGameChanged() {
        var changeData = false
        for turnsStack in turns.arrangedSubviews {
            if let turnsStack = turnsStack as? UIStackView {
                for turn in turnsStack.arrangedSubviews {
                    if let turnData = turn.layer.value(forKey: constants.keyNameForTurn) as? Turn {
                        if !gameLogic.turns.contains(turnData) {
                            changeData = true
                            turn.removeFromSuperview()
                            if turnsStack.arrangedSubviews.isEmpty {
                                turnsStack.removeFromSuperview()
                            }
                            if turnsStack.arrangedSubviews.count == 1 {
                                if turnsStack.arrangedSubviews.first!.layer.value(forKey: constants.keyNameForTurn) as? Turn == nil {
                                    turnsStack.removeFromSuperview()
                                }
                            }
                        }
                    }
                }
            }
        }
        if changeData {
            if let turnsStack = turns.arrangedSubviews.last as? UIStackView {
                if turnsStack.arrangedSubviews.count == 1 {
                    turnData = turnsStack
                    let spacer = UIView()
                    turnData.addArrangedSubview(spacer)
                }
                else {
                    makeEmptyTurnData()
                }
            }
            else {
                makeEmptyTurnData()
            }
        }
    }
    
    //creates new turn line(contains turns of both players), where we gonna add new turn
    private func makeEmptyTurnData() {
        let newTurnData = UIStackView()
        newTurnData.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        turnData = newTurnData
    }
    
    //highlights current turn
    private func updateCurrentTurn() {
        let squaresTheme = gameLogic.players.first!.user.squaresTheme.getTheme()
        for turnsStack in turns.arrangedSubviews {
            if let turnsStack = turnsStack as? UIStackView {
                for turn in turnsStack.arrangedSubviews {
                    if let turnData = turn.layer.value(forKey: constants.keyNameForTurn) as? Turn {
                        if turnData == gameLogic.currentTurn {
                            let newColor = constants.convertLogicColor(squaresTheme.turnColor)
                            let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {
                                turn.backgroundColor = newColor.withAlphaComponent(constants.optimalAlpha)
                            })
                            animations.append(animation)
                            //scrolls turns to current turn
                            if let index = turns.arrangedSubviews.firstIndex(of: turnsStack) {
                                turnsView.layoutIfNeeded()
                                //index + 1 cuz we start from 0
                                let condition = turnsScrollView.contentSize.height / CGFloat(turns.arrangedSubviews.count) * CGFloat(index + 1) + turnsButtons.bounds.size.height + currentPlayerForTurns.bounds.size.height
                                var contentOffset = CGPoint.zero
                                if condition > turnsView.bounds.size.height {
                                    contentOffset = CGPoint(x: 0, y: condition - turnsView.bounds.size.height + turns.spacing)
                                }
                                let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {[weak self] in
                                    self?.turnsScrollView.contentOffset = contentOffset
                                })
                                animations.append(animation)
                            }
                        }
                        else {
                            let newColor = defaultPlayerDataColor
                            let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {
                                turn.backgroundColor = newColor
                            })
                            animations.append(animation)
                        }
                    }
                }
            }
        }
    }
    
    //updates colors of players data
    private func updateCurrentPlayer() {
        let currentPlayer = gameLogic.currentPlayer
        let currentPlayerFrame = currentPlayer.type == .player1 ? player1FrameView : player2FrameView
        let enemyPlayerFrame = currentPlayer.type == .player1 ? player2FrameView : player1FrameView
        let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {[weak self] in
            if let self = self {
                currentPlayerFrame.updateDataBackgroundColor(self.currentPlayerDataColor)
                enemyPlayerFrame.updateDataBackgroundColor(self.defaultPlayerDataColor)
                self.currentPlayerForTurns.text = self.gameLogic.currentPlayer.user.nickname
                if self.gameLogic.timerEnabled {
                    let currentPlayerTimer = currentPlayer.type == .player1 ? self.player1Timer : self.player2Timer
                    let enemyPlayerTimer = currentPlayer.type == .player1 ? self.player2Timer : self.player1Timer
                    let currentPlayerTimerInTurns = currentPlayer.type == .player1 ? self.player1TimerForTurns : self.player2TimerForTurns
                    let enemyPlayerTimerInTurns = currentPlayer.type == .player1 ? self.player2TimerForTurns : self.player1TimerForTurns
                    if currentPlayer.timeLeft > constants.dangerTimeleft {
                        currentPlayerTimer.layer.backgroundColor = self.currentPlayerDataColor.cgColor
                        currentPlayerTimerInTurns.layer.backgroundColor = self.currentPlayerDataColor.cgColor
                    }
                    else {
                        currentPlayerTimer.layer.backgroundColor = constants.dangerPlayerDataColor.cgColor
                        currentPlayerTimerInTurns.layer.backgroundColor = constants.dangerPlayerDataColor.cgColor
                    }
                    enemyPlayerTimer.layer.backgroundColor = self.defaultPlayerDataColor.cgColor
                    enemyPlayerTimerInTurns.layer.backgroundColor = self.defaultPlayerDataColor.cgColor
                }
            }
        })
        animations.append(animation)
    }
    
    //when pawn reaches last row
    private func showPawnPicker(square: Square, figure: Figure) {
        makePawnPicker(figure: figure, squareColor: square.color)
        scrollContentOfGame.addSubview(pawnPicker)
        pawnPicker.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.getTheme().secondColor)
        if square.color == .white {
            pawnPicker.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.getTheme().firstColor)
        }
        var pawnPickerConstraints: [NSLayoutConstraint] = []
        if gameLogic.currentPlayer.type == .player1 {
            pawnPicker.transform = player1RotateFiguresButton.transform
            if let lettersLine = gameBoard.arrangedSubviews.last {
                pawnPickerConstraints = [pawnPicker.centerXAnchor.constraint(equalTo: lettersLine.centerXAnchor), pawnPicker.centerYAnchor.constraint(equalTo: lettersLine.centerYAnchor)]
            }
        }
        else {
            pawnPicker.transform = player2RotateFiguresButton.transform
            if let lettersLine = gameBoard.arrangedSubviews.first {
                pawnPickerConstraints = [pawnPicker.centerXAnchor.constraint(equalTo: lettersLine.centerXAnchor), pawnPicker.centerYAnchor.constraint(equalTo: lettersLine.centerYAnchor)]
            }
        }
        NSLayoutConstraint.activate(pawnPickerConstraints)
    }
    
    private func updateSquares(animate: Bool = false) {
        for view in squares {
            if let square = view.layer.value(forKey: constants.keyNameForSquare) as? Square {
                var newColor: UIColor?
                if let currentTurn = gameLogic.currentTurn, currentTurn.squares.contains(square) {
                    newColor = constants.convertLogicColor(gameLogic.squaresTheme.getTheme().turnColor)
                }
                else {
                    switch square.color {
                    case .white:
                        newColor = constants.convertLogicColor(gameLogic.squaresTheme.getTheme().firstColor)
                    case .black:
                        newColor = constants.convertLogicColor(gameLogic.squaresTheme.getTheme().secondColor)
                    case .random:
                        fatalError("Somehow we have .random color!")
                    }
                }
                if gameLogic.pawnWizard {
                    view.isUserInteractionEnabled = false
                }
                else if gameLogic.currentPlayer.figuresColor == .white && square.figure?.color == .white {
                    view.isUserInteractionEnabled = true
                }
                else if gameLogic.currentPlayer.figuresColor == .black && square.figure?.color == .black{
                    view.isUserInteractionEnabled = true
                }
                else {
                    view.isUserInteractionEnabled = false
                }
                if gameLogic.pickedSquares.count == 1 {
                    if gameLogic.pickedSquares.contains(square) {
                        newColor = constants.convertLogicColor(gameLogic.squaresTheme.getTheme().pickColor)
                    }
                    else if gameLogic.availableSquares.contains(square) {
                        newColor = constants.convertLogicColor(gameLogic.squaresTheme.getTheme().availableSquaresColor)
                        view.isUserInteractionEnabled = true
                    }
                }
                if gameLogic.currentTurn?.checkSquare == square {
                    newColor = constants.convertLogicColor(gameLogic.squaresTheme.getTheme().checkColor)
                }
                if animate {
                    let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, options: .allowUserInteraction, animations: {
                        view.backgroundColor = newColor
                    })
                    animations.append(animation)
                }
                else {
                    view.backgroundColor = newColor
                }
            }
        }
    }
    
    private func animateTurn(_ turn: Turn) {
        gameLogic.resetPickedSquares()
        let firstSquare = gameLogic.getUpdatedSquares(from: turn).first
        let secondSquare = gameLogic.getUpdatedSquares(from: turn).second
        let firstSquareView = squares.first(where: {$0.layer.value(forKey: constants.keyNameForSquare) as? Square == firstSquare})
        let secondSquareView = squares.first(where: {$0.layer.value(forKey: constants.keyNameForSquare) as? Square == secondSquare})
        //if en passant
        var thirdSquareView: UIImageView?
        var backwardSquareView: UIImageView?
        if !backwardRewind {
            if let pawnSquare = turn.pawnSquare {
                thirdSquareView = squares.first(where: {if let square = $0.layer.value(forKey: constants.keyNameForSquare) as? Square, square == pawnSquare && square.figure != nil {return true} else {return false}})
            }
        }
        else {
            if let pawnSquare = turn.pawnSquare {
                if let squareView = squares.first(where: {$0.layer.value(forKey: constants.keyNameForSquare) as? Square == pawnSquare}) {
                    squareView.layer.setValue(pawnSquare, forKey: constants.keyNameForSquare)
                    backwardSquareView = squareView
                }
            }
            else if let _ = turn.squares.second?.figure, let squareView = squares.first(where: {$0.layer.value(forKey: constants.keyNameForSquare) as? Square == turn.squares.first}) {
                backwardSquareView = squareView
            }
        }
        if let firstSquareView = firstSquareView, let secondSquareView = secondSquareView, let firstSquare = firstSquare, let secondSquare = secondSquare {
            animateFigures(firstSquareView: firstSquareView, secondSquareView: secondSquareView, thirdSquareView: thirdSquareView, firstSquare: firstSquare, secondSquare: secondSquare, pawnSquare: turn.pawnSquare, pawnTransform: turn.pawnTransform, backwardSquareView: backwardSquareView)
        }
    }
    
    //moves figure between squares and trash, both forward and backward, and also transform pawn when rewind
    private func animateFigures(firstSquareView: UIImageView, secondSquareView: UIImageView, thirdSquareView: UIImageView?, firstSquare: Square, secondSquare: Square, pawnSquare: Square?, pawnTransform: Figure?, backwardSquareView: UIImageView?) {
        //for proper coordinates for transform of figure, when we removing it from square
        firstSquareView.layoutIfNeeded()
        secondSquareView.layoutIfNeeded()
        thirdSquareView?.layoutIfNeeded()
        //bacwardRewind will change after animation will finish, so we need to capture it
        let backwardRewind = self.backwardRewind
        if backwardRewind {
            if pawnTransform != nil, let figure = secondSquare.figure {
                updateSquare(firstSquare, figure: figure)
            }
        }
        var frameForBackward: (x: CGFloat, y: CGFloat) = (0, 0)
        var backwardFigureView: UIImageView?
        if let backwardSquareView = backwardSquareView {
            backwardFigureView = getBackwardFigureView()
            if let backwardFigureView = backwardFigureView {
                bringFigureToFrontFromTrash(figureView: backwardFigureView)
                frameForBackward = coordinatesToMoveFigureFrom(firstView: backwardFigureView, to: backwardSquareView)
                if player1RotateFiguresButton.transform != player2RotateFiguresButton.transform {
                    backwardFigureView.image = backwardFigureView.image?.rotate(radians: .pi)
                }
            }
        }
        let frame = getFrameForAnimation(firstView: firstSquareView, secondView: secondSquareView)
        //currentPlayer will change after animation will finish, so we need to capture it
        var currentPlayer = gameLogic.currentPlayer
        if gameLogic.pawnWizard {
            currentPlayer = currentPlayer == gameLogic.players.first! ? gameLogic.players.second! : gameLogic.players.first!
        }
        secondSquareView.layer.setValue(secondSquare, forKey: constants.keyNameForSquare)
        firstSquareView.layer.setValue(firstSquare, forKey: constants.keyNameForSquare)
        if let pawnSquare = pawnSquare {
            var newSquare = pawnSquare
            newSquare.updateFigure()
            thirdSquareView?.layer.setValue(newSquare, forKey: constants.keyNameForSquare)
        }
        figureFromTrash = backwardFigureView
        let firstFigureView = firstSquareView.subviews.second
        let secondFigureView = secondSquareView.subviews.second
        let thirdFigureView = thirdSquareView?.subviews.second
        for figureView in [firstFigureView, secondFigureView, thirdFigureView] {
            if let figureView = figureView {
                figureView.isUserInteractionEnabled = false
                figuresInMotion.append(figureView)
                let bounds = getFrameForAnimation(firstView: scrollContentOfGame, secondView: figureView)
                //when we remove figure from square, we need to move figure to square position
                figureView.transform = CGAffineTransform(translationX: bounds.minX, y: bounds.minY)
                //we are doing this to be able to have both figures on top of gameBoard(useful in castle, for example)
                scrollContentOfGame.addSubview(figureView)
                //positioning figure in 0 0, to be sure, that transform is correct
                let figureViewConstraints = [figureView.leadingAnchor.constraint(equalTo: scrollContentOfGame.leadingAnchor), figureView.topAnchor.constraint(equalTo: scrollContentOfGame.topAnchor)]
                NSLayoutConstraint.activate(figureViewConstraints)
            }
        }
        if let firstFigureView = firstFigureView {
            scrollContentOfGame.bringSubviewToFront(firstFigureView)
        }
        viewsOnTop()
        //turn animation
        let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {
            backwardFigureView?.transform = CGAffineTransform(translationX: frameForBackward.x, y: frameForBackward.y)
            if let firstFigureView = firstFigureView {
                firstFigureView.transform = firstFigureView.transform.translatedBy(x: frame.minX - firstSquareView.bounds.minX, y: frame.minY - firstSquareView.bounds.minY)
            }
        }) { [weak self] _ in
            if let self = self {
                NSLayoutConstraint.deactivate(self.scrollContentOfGame.constraints.filter({$0.firstItem === firstFigureView || $0.firstItem === secondFigureView || $0.firstItem === thirdFigureView}))
                self.figuresInMotion = []
                //stops trashAnimation before starting new one
                self.trashAnimation?.stopAnimation(false)
                self.trashAnimation?.finishAnimation(at: .end)
                if let backwardSquareView = backwardSquareView, let backwardFigureView = backwardFigureView {
                    let destroyedFiguresView = backwardFigureView.superview?.superview
                    backwardFigureView.transform = .identity
                    self.figureFromTrash = nil
                    backwardSquareView.addSubview(backwardFigureView)
                    destroyedFiguresView?.layoutIfNeeded()
                }
                if let secondFigureView = secondFigureView as? UIImageView {
                    self.moveFigureToTrash(figureView: secondFigureView, currentPlayer: currentPlayer)
                }
                if let firstFigureView = firstFigureView {
                    firstFigureView.transform = .identity
                    secondSquareView.addSubview(firstFigureView)
                    let figureViewConstraints = [firstFigureView.centerXAnchor.constraint(equalTo: secondSquareView.centerXAnchor), firstFigureView.centerYAnchor.constraint(equalTo: secondSquareView.centerYAnchor)]
                    NSLayoutConstraint.activate(figureViewConstraints)
                }
                if let thirdFigureView = thirdFigureView as? UIImageView {
                    self.moveFigureToTrash(figureView: thirdFigureView, currentPlayer: currentPlayer)
                }
                if self.gameLogic.gameEnded && self.view.subviews.first(where: {$0 == self.endOfTheGameView}) == nil {
                    self.makeEndOfTheGameView()
                }
                if let pawnTransform = pawnTransform, !backwardRewind {
                    if let turn = self.gameLogic.currentTurn, let square = turn.squares.last {
                        self.updateSquare(square, figure: pawnTransform)
                    }
                }
            }
        }
        animations.append(animation)
    }
    
    //gets figure to move from trash to game
    private func getBackwardFigureView() -> UIImageView? {
        trashAnimation?.stopAnimation(false)
        trashAnimation?.finishAnimation(at: .end)
        if gameLogic.currentPlayer == gameLogic.players.first! {
            if player2DestroyedFigures2.arrangedSubviews.count > 0 {
                return player2DestroyedFigures2.arrangedSubviews.last! as? UIImageView
            }
            else if player2DestroyedFigures1.arrangedSubviews.count > 0{
                return player2DestroyedFigures1.arrangedSubviews.last! as? UIImageView
            }
        }
        else {
            if gameLogic.gameMode != .oneScreen {
                if player1DestroyedFigures2.arrangedSubviews.count > 0 {
                    return player1DestroyedFigures2.arrangedSubviews.last! as? UIImageView
                }
                else if player1DestroyedFigures1.arrangedSubviews.count > 0{
                    return player1DestroyedFigures1.arrangedSubviews.last! as? UIImageView
                }
            }
            else {
                if player1DestroyedFigures2.arrangedSubviews.count > 0 {
                    return player1DestroyedFigures2.arrangedSubviews.first! as? UIImageView
                }
                else if player1DestroyedFigures1.arrangedSubviews.count > 0{
                    return player1DestroyedFigures1.arrangedSubviews.first! as? UIImageView
                }
            }
        }
        return nil
    }
    
    private func bringFigureToFrontFromTrash(figureView: UIView) {
        let trashView = figureView.superview?.superview
        let trashStack = figureView.superview
        if let trashStack = trashStack, let trashView = trashView {
            scrollContentOfGame.bringSubviewToFront(trashView)
            trashView.bringSubviewToFront(trashStack)
            trashStack.bringSubviewToFront(figureView)
        }
        viewsOnTop()
    }
    
    private func getFrameForAnimation(firstView: UIView, secondView: UIView) -> CGRect {
        return firstView.convert(secondView.bounds, from: secondView)
    }
    
    private func moveFigureToTrash(figureView: UIImageView, currentPlayer: Player) {
        figureToTrash = figureView
        if player1RotateFiguresButton.transform != player2RotateFiguresButton.transform  {
            figureView.image = figureView.image?.rotate(radians: .pi)
        }
        var coordinates: (xCoordinate: CGFloat, yCoordinate: CGFloat) = (0, 0)
        switch currentPlayer.type {
        case .player1:
            coordinates = coordinatesForTrashAnimation(player: .player1, figureView: figureView, destroyedFiguresStack1: player1DestroyedFigures1, destroyedFiguresStack2: player1DestroyedFigures2)
        case .player2:
            coordinates = coordinatesForTrashAnimation(player: .player2, figureView: figureView, destroyedFiguresStack1: player2DestroyedFigures1, destroyedFiguresStack2: player2DestroyedFigures2)
        }
        animateFigureToTrash(figure: figureView, x: coordinates.xCoordinate, y: coordinates.yCoordinate, currentPlayer: currentPlayer)
    }
    
    private func coordinatesForTrashAnimation(player: GamePlayers, figureView: UIImageView, destroyedFiguresStack1: UIStackView, destroyedFiguresStack2: UIStackView) -> (xCoordinate: CGFloat, yCoordinate: CGFloat) {
        var frame = CGRect.zero
        var xCoordinate: CGFloat = 0
        var yCoordinate: CGFloat = 0
        //we have 2 lines of trash figures
        if destroyedFiguresStack1.subviews.count == constants.maxFiguresInTrashLine {
            frame = getFrameForAnimation(firstView: figureView, secondView: destroyedFiguresStack2)
        }
        else {
            frame = getFrameForAnimation(firstView: figureView, secondView: destroyedFiguresStack1)
        }
        if gameLogic.gameMode == .oneScreen && player == .player1 {
            xCoordinate = frame.minX - figureView.bounds.maxX
            yCoordinate = frame.maxY - figureView.bounds.maxY
            //at the start StackView have height 0
            if destroyedFiguresStack1.subviews.count == constants.maxFiguresInTrashLine && destroyedFiguresStack2.subviews.isEmpty {
                yCoordinate = frame.maxY - figureView.bounds.minY
            }
        }
        else if gameLogic.gameMode == .multiplayer || player == .player2{
            xCoordinate = frame.maxX - figureView.bounds.minX
            yCoordinate = frame.minY - figureView.bounds.minY
            if destroyedFiguresStack1.subviews.count == constants.maxFiguresInTrashLine && destroyedFiguresStack2.subviews.isEmpty {
                yCoordinate = frame.minY - figureView.bounds.maxY
            }
        }
        return (xCoordinate, yCoordinate)
    }
    
    private func animateFigureToTrash(figure: UIView, x: CGFloat, y: CGFloat, currentPlayer: Player) {
        trashAnimation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {
            figure.transform = figure.transform.translatedBy(x: x, y: y)
        }) {[weak self] _ in
            if let self = self {
                figure.transform = .identity
                self.figureToTrash = nil
                switch currentPlayer.type {
                case .player1:
                    self.addFigureToTrash(player: .player1, destroyedFiguresStack1: self.player1DestroyedFigures1, destroyedFiguresStack2: self.player1DestroyedFigures2, figure: figure)
                case .player2:
                    self.addFigureToTrash(player: .player2, destroyedFiguresStack1: self.player2DestroyedFigures1, destroyedFiguresStack2: self.player2DestroyedFigures2, figure: figure)
                }
            }
        }
    }
    
    private func addFigureToTrash(player: GamePlayers, destroyedFiguresStack1: UIStackView, destroyedFiguresStack2: UIStackView, figure: UIView) {
        if gameLogic.gameMode == .oneScreen && player == .player1 {
            if destroyedFiguresStack1.subviews.count == constants.maxFiguresInTrashLine {
                //here we insert at 0, because stacks start from left side, but for player 2 they should start from right side
                destroyedFiguresStack2.insertArrangedSubview(figure, at: 0)
            }
            else {
                destroyedFiguresStack1.insertArrangedSubview(figure, at: 0)
            }
        }
        else if gameLogic.gameMode == .multiplayer || player == .player2 {
            if destroyedFiguresStack1.subviews.count == constants.maxFiguresInTrashLine {
                destroyedFiguresStack2.addArrangedSubview(figure)
            }
            else {
                destroyedFiguresStack1.addArrangedSubview(figure)
            }
        }
    }
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private let frameForEndOfTheGameView = UIImageView()
    private let scrollViewOfGame = UIScrollView()
    private let endOfTheGameScrollView = UIScrollView()
    private let scrollContentOfGame = UIView()
    private let pawnPicker = UIStackView()
    private let gameBoard = UIStackView()
    //2 stacks for destroyed figures, 8 figures each
    private let player1DestroyedFigures1 = UIStackView()
    private let player1DestroyedFigures2 = UIStackView()
    private let player2DestroyedFigures1 = UIStackView()
    private let player2DestroyedFigures2 = UIStackView()
    private let endOfTheGameView = UIImageView()
    private let additionalButtons = UIStackView()
    private let additionalButtonsForFigures = UIStackView()
    private let showEndOfTheGameView = UIButton()
    //just a pointer to additional buttons
    private let arrowToAdditionalButtons = UIImageView()
    private let turnsScrollView = UIScrollView()
    private let turns = UIStackView()
    private let restoreButton = UIButton()
    private let turnBackward = UIButton()
    private let turnForward = UIButton()
    private let turnAction = UIButton()
    private let turnsButtons = UIStackView()
    private let turnsView = UIView()
    private let additionalButton = UIButton()
    private let additionalButtonForFigures = UIButton(type: .system)
    //df - destroyed figures
    private let player2FrameForDF = UIImageView()
    private let player1FrameForDF = UIImageView()
    private let playerProgress = ProgressBar()
    private let surrenderButton = UIButton()
    private let saveButton = UIButton()
    private let exitButton = UIButton()
    private let fastAnimationsButton = UIButton()
    private let player1RotateFiguresButton = UIButton()
    private let player2RotateFiguresButton = UIButton()
    
    private lazy var defaultPlayerDataColor = traitCollection.userInterfaceStyle == .dark ? constants.defaultDarkModeColorForDataBackground : constants.defaultLightModeColorForDataBackground
    private lazy var currentPlayerDataColor = traitCollection.userInterfaceStyle == .dark ? constants.currentPlayerDataColorDarkMode : constants.currentPlayerDataColorLightMode
    
    private var loadingSpinner = LoadingSpinner()
    //contains currentTurn of both players
    private var turnData = UIStackView()
    private var player1Timer = UILabel()
    private var player2Timer = UILabel()
    //when we show turnsView, it blocks some UI, so we recreate it inside it
    private var player1TimerForTurns = UILabel()
    private var player2TimerForTurns = UILabel()
    private var currentPlayerForTurns = UILabel()
    private var squares = [UIImageView]()
    private var destroyedFigures1 = UIView()
    private var destroyedFigures2 = UIView()
    private var player1FrameView = PlayerFrame()
    private var player2FrameView = PlayerFrame()
    private var player1TitleView = PlayerFrame()
    private var player2TitleView = PlayerFrame()
    
    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []
    private var specialConstraints: [NSLayoutConstraint] = []
    private var timerConstraints: [NSLayoutConstraint] = []
    private var additionalButtonConstraints: [NSLayoutConstraint] = []
    //when we changing device orientation, we transform arrow and we need to store that transformation for animation
    //of transition of additional buttons
    private var currentTransformOfArrow = CGAffineTransform.identity
    private var specialLayout = false
    //is used in checkSpecialFigureView
    private var figureToTrash: UIView?
    private var figureFromTrash: UIView?
    private var figuresInMotion = [UIView]()
    
    //letters line on top and bottom of the board
    private var lettersLine: UIStackView {
        let boardTheme = gameLogic.boardTheme.rawValue
        let lettersLine = UIStackView()
        lettersLine.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        lettersLine.addArrangedSubview(getSquareView(image: UIImage(named: "boardThemes/\(boardTheme)/letter")))
        for column in GameBoard.availableColumns {
            lettersLine.addArrangedSubview(getSquareView(image: UIImage(named: "boardThemes/\(boardTheme)/letter_\(column.rawValue)")))
        }
        lettersLine.addArrangedSubview(getSquareView(image: UIImage(named: "boardThemes/\(boardTheme)/letter")))
        return lettersLine
    }
    
    // MARK: - UI Methods
    
    //makes button to show/hide additional buttons
    private func makeAdditionalButton() {
        let fontSize = min(view.frame.width, view.frame.height) / constants.dividerForFont
        let figuresThemeName = gameLogic.players.first!.user.figuresTheme.rawValue
        let figureColor = traitCollection.userInterfaceStyle == .dark ? GameColors.black.rawValue : GameColors.white.rawValue
        let figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(figureColor)_pawn")
        arrowToAdditionalButtons.image = figureImage
        scrollContentOfGame.addSubview(arrowToAdditionalButtons)
        additionalButton.buttonWith(image: UIImage(systemName: "arrowtriangle.down.fill"), and: #selector(transitAdditonalButtons))
        additionalButtonForFigures.buttonWith(text: "♞", font: UIFont.systemFont(ofSize: fontSize), and: #selector(transitAdditonalButtons))
    }
    
    private func makeAdditionalButtons() {
        surrenderButton.buttonWith(image: UIImage(systemName: "flag.fill"), and: #selector(surrender))
        let lockScrolling = UIButton()
        lockScrolling.buttonWith(image: UIImage(systemName: "lock.open"), and: #selector(lockGameView))
        let turnsViewButton = UIButton()
        turnsViewButton.buttonWith(image: UIImage(systemName: "backward"), and: #selector(transitTurnsView))
        if #available(iOS 15.0, *) {
            exitButton.buttonWith(image: UIImage(systemName: "rectangle.portrait.and.arrow.right"), and: #selector(exit))
        }
        else {
            exitButton.buttonWith(image: UIImage(systemName: "arrow.left.square"), and: #selector(exit))
        }
        showEndOfTheGameView.buttonWith(image: UIImage(systemName: "doc.text.magnifyingglass"), and: #selector(transitEndOfTheGameView))
        var buttonViews = [showEndOfTheGameView, lockScrolling, turnsViewButton, exitButton]
        if !gameLogic.gameEnded {
            buttonViews.insert(surrenderButton, at: 2)
        }
        additionalButtons.addArrangedSubviews(buttonViews)
        if gameLogic.gameMode == .oneScreen && !gameLogic.gameEnded {
            saveButton.buttonWith(image: UIImage(systemName: "square.and.arrow.down"), and: #selector(saveGame))
            saveButton.isEnabled = false
            additionalButtons.addArrangedSubview(saveButton)
        }
        scrollContentOfGame.addSubview(additionalButtons)
    }
    
    private func makeAdditionalButtonsForFigures() {
        let figureImageFirstPlayer = (makeFigureView(of: gameLogic.players.first!, with: "pawn").subviews.second as? UIImageView)?.image
        let figureImageSecondPlayer = (makeFigureView(of: gameLogic.players.second!, with: "pawn").subviews.second as? UIImageView)?.image
        player1RotateFiguresButton.buttonWith(image: figureImageFirstPlayer, and: #selector(rotateFigures))
        player2RotateFiguresButton.buttonWith(image: figureImageSecondPlayer, and: #selector(rotateFigures))
        let gameBoardAutoRotateButton = UIButton()
        gameBoardAutoRotateButton.buttonWith(image: UIImage(systemName: "arrow.2.squarepath"), and: #selector(toggleGameBoardAutoRotate))
        gameBoardAutoRotateButton.backgroundColor = constants.dangerPlayerDataColor
        player1RotateFiguresButton.layer.setValue(gameLogic.players.first!.figuresColor, forKey: constants.keyForFigureColor)
        player2RotateFiguresButton.layer.setValue(gameLogic.players.second!.figuresColor, forKey: constants.keyForFigureColor)
        if gameLogic.gameMode == .oneScreen {
            player2RotateFiguresButton.transform = CGAffineTransform(rotationAngle: .pi)
        }
        additionalButtonsForFigures.addArrangedSubviews([player1RotateFiguresButton, player2RotateFiguresButton, gameBoardAutoRotateButton])
        scrollContentOfGame.addSubview(additionalButtonsForFigures)
        let buttonConstraints = [player1RotateFiguresButton.widthAnchor.constraint(equalTo: player1RotateFiguresButton.heightAnchor)]
        NSLayoutConstraint.activate(buttonConstraints)
    }
    
    private func makeUI() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        setupViews()
        addPlayersBackgrounds()
        makeScrollViewOfGame()
        makePlayer2Title()
        makePlayer2Frame()
        makePlayer2DestroyedFiguresView()
        makeGameBoard()
        makePlayer1DestroyedFiguresView()
        makePlayer1Frame()
        makePlayer1Title()
        makeAdditionalButton()
        makeAdditionalButtons()
        makeAdditionalButtonsForFigures()
        if gameLogic.timerEnabled {
            makeTimers()
        }
        makeTurnsView()
        viewsOnTop()
        makeSpecialConstraints()
        makePortraitConstraints()
        makeLandscapeConstraints()
        if gameLogic.gameEnded {
            loadedEndedGame = true
            makeEndOfTheGameView()
        }
    }
    
    //updates constraints depending on orientation
    private func updateConstraints(portrait: Bool) {
        if portrait {
            if arrowToAdditionalButtons.alpha == 1 {
                arrowToAdditionalButtons.transform = CGAffineTransform(rotationAngle: .pi)
                additionalButton.transform = CGAffineTransform(rotationAngle: .pi)
            }
            else {
                arrowToAdditionalButtons.transform = .identity
                additionalButton.transform = .identity
            }
            if additionalButtonsForFigures.alpha == 1 {
                additionalButtonForFigures.transform = CGAffineTransform(rotationAngle: .pi)
            }
            else {
                additionalButtonForFigures.transform = .identity
            }
            currentTransformOfArrow = .identity
            if !specialLayout {
                NSLayoutConstraint.deactivate(landscapeConstraints)
                NSLayoutConstraint.activate(portraitConstraints)
            }
            else {
                NSLayoutConstraint.deactivate(specialConstraints)
                NSLayoutConstraint.activate(timerConstraints)
                NSLayoutConstraint.activate(additionalButtonConstraints)
            }
        }
        else {
            if arrowToAdditionalButtons.alpha == 1 {
                arrowToAdditionalButtons.transform = CGAffineTransform(rotationAngle: .pi).rotated(by: .pi * 1.5)
                additionalButton.transform = CGAffineTransform(rotationAngle: .pi).rotated(by: .pi * 1.5)
            }
            else {
                arrowToAdditionalButtons.transform = CGAffineTransform(rotationAngle: .pi * 1.5)
                additionalButton.transform = CGAffineTransform(rotationAngle: .pi * 1.5)
            }
            if additionalButtonsForFigures.alpha == 1 {
                additionalButtonForFigures.transform = CGAffineTransform(rotationAngle: .pi).rotated(by: .pi * 1.5)
            }
            else {
                additionalButtonForFigures.transform = CGAffineTransform(rotationAngle: .pi * 1.5)
            }
            currentTransformOfArrow = CGAffineTransform(rotationAngle: .pi * 1.5)
            if !specialLayout {
                NSLayoutConstraint.deactivate(portraitConstraints)
                NSLayoutConstraint.activate(landscapeConstraints)
            }
            else {
                NSLayoutConstraint.deactivate(timerConstraints)
                NSLayoutConstraint.deactivate(additionalButtonConstraints)
                NSLayoutConstraint.activate(specialConstraints)
            }
        }
        updateLayout()
    }
    
    //if we dont have enough space for player data left and right from gameBoard,
    //instead we only move timers and change layout of additional buttons
    private func makeSpecialConstraints() {
        let heightForAdditionalButtons = min(view.frame.width, view.frame.height)  / constants.dividerForSquare
        var player1TimerConstaints = [NSLayoutConstraint]()
        var player2TimerConstaints = [NSLayoutConstraint]()
        if gameLogic.timerEnabled {
            player1TimerConstaints = [player1Timer.bottomAnchor.constraint(equalTo: gameBoard.bottomAnchor), player1Timer.trailingAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.leadingAnchor), player1Timer.leadingAnchor.constraint(greaterThanOrEqualTo: scrollContentOfGame.layoutMarginsGuide.leadingAnchor)]
            player2TimerConstaints = [player2Timer.topAnchor.constraint(equalTo: gameBoard.topAnchor), player2Timer.leadingAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.trailingAnchor), player2Timer.trailingAnchor.constraint(lessThanOrEqualTo: scrollContentOfGame.layoutMarginsGuide.trailingAnchor)]
        }
        let additionalButtonsConstraints = [additionalButtons.bottomAnchor.constraint(equalTo: gameBoard.bottomAnchor), additionalButtons.leadingAnchor.constraint(equalTo: arrowToAdditionalButtons.trailingAnchor), additionalButtons.heightAnchor.constraint(equalToConstant: heightForAdditionalButtons), showEndOfTheGameView.widthAnchor.constraint(equalTo: showEndOfTheGameView.heightAnchor)]
        let additionalButtonsForFiguresConstraints = [additionalButtonsForFigures.bottomAnchor.constraint(equalTo: gameBoard.bottomAnchor), additionalButtonsForFigures.trailingAnchor.constraint(equalTo: additionalButtonForFigures.leadingAnchor), additionalButtonsForFigures.heightAnchor.constraint(equalToConstant: heightForAdditionalButtons)]
        if let stackWhereToAdd = gameBoard.arrangedSubviews.last {
            if let stackWhereToAdd = stackWhereToAdd as? UIStackView {
                if let viewWhereToAdd = stackWhereToAdd.arrangedSubviews.first {
                    viewWhereToAdd.addSubview(additionalButton)
                    let additionalButtonConstraints = [additionalButton.widthAnchor.constraint(equalTo: viewWhereToAdd.widthAnchor, multiplier: constants.multiplierForNumberView), additionalButton.heightAnchor.constraint(equalTo: viewWhereToAdd.heightAnchor, multiplier: constants.multiplierForNumberView), additionalButton.centerXAnchor.constraint(equalTo: viewWhereToAdd.centerXAnchor), additionalButton.centerYAnchor.constraint(equalTo: viewWhereToAdd.centerYAnchor), arrowToAdditionalButtons.leadingAnchor.constraint(equalTo: viewWhereToAdd.trailingAnchor), arrowToAdditionalButtons.centerYAnchor.constraint(equalTo: viewWhereToAdd.centerYAnchor), arrowToAdditionalButtons.widthAnchor.constraint(equalTo: viewWhereToAdd.widthAnchor), arrowToAdditionalButtons.heightAnchor.constraint(equalTo: viewWhereToAdd.heightAnchor)]
                    specialConstraints += additionalButtonConstraints
                }
                if let viewWhereToAdd = stackWhereToAdd.arrangedSubviews.last {
                    viewWhereToAdd.addSubview(additionalButtonForFigures)
                    let additionalButtonForFiguresConstraints = [additionalButtonForFigures.widthAnchor.constraint(equalTo: viewWhereToAdd.widthAnchor, multiplier: constants.multiplierForNumberView), additionalButtonForFigures.heightAnchor.constraint(equalTo: viewWhereToAdd.heightAnchor, multiplier: constants.multiplierForNumberView), additionalButtonForFigures.centerXAnchor.constraint(equalTo: viewWhereToAdd.centerXAnchor), additionalButtonForFigures.centerYAnchor.constraint(equalTo: viewWhereToAdd.centerYAnchor)]
                    specialConstraints += additionalButtonForFiguresConstraints
                }
            }
        }
        specialConstraints += player1TimerConstaints + player2TimerConstaints + additionalButtonsConstraints + additionalButtonsForFiguresConstraints
    }
    
    private func makePortraitConstraints() {
        let heightForAdditionalButtons = min(view.frame.width, view.frame.height)  / constants.dividerForSquare
        let widthForFrame = min(view.frame.width, view.frame.height)  / constants.widthDividerForTrash
        let heightForFrame = min(view.frame.width, view.frame.height)  / constants.heightDividerForFrame
        if let stackWhereToAdd = gameBoard.arrangedSubviews.last {
            if let stackWhereToAdd = stackWhereToAdd as? UIStackView {
                if let viewWhereToAdd = stackWhereToAdd.arrangedSubviews.first {
                    viewWhereToAdd.addSubview(additionalButton)
                    let additionalButtonConstraints = [additionalButton.widthAnchor.constraint(equalTo: viewWhereToAdd.widthAnchor, multiplier: constants.multiplierForNumberView), additionalButton.heightAnchor.constraint(equalTo: viewWhereToAdd.heightAnchor, multiplier: constants.multiplierForNumberView), additionalButton.centerXAnchor.constraint(equalTo: viewWhereToAdd.centerXAnchor), additionalButton.centerYAnchor.constraint(equalTo: viewWhereToAdd.centerYAnchor), arrowToAdditionalButtons.topAnchor.constraint(equalTo: viewWhereToAdd.bottomAnchor), arrowToAdditionalButtons.centerXAnchor.constraint(equalTo: viewWhereToAdd.centerXAnchor), arrowToAdditionalButtons.widthAnchor.constraint(equalTo: viewWhereToAdd.widthAnchor), arrowToAdditionalButtons.heightAnchor.constraint(equalTo: viewWhereToAdd.heightAnchor)]
                    portraitConstraints += additionalButtonConstraints
                    self.additionalButtonConstraints += additionalButtonConstraints
                }
                if let viewWhereToAdd = stackWhereToAdd.arrangedSubviews.last {
                    viewWhereToAdd.addSubview(additionalButtonForFigures)
                    let additionalButtonForFiguresConstraints = [additionalButtonForFigures.widthAnchor.constraint(equalTo: viewWhereToAdd.widthAnchor, multiplier: constants.multiplierForNumberView), additionalButtonForFigures.heightAnchor.constraint(equalTo: viewWhereToAdd.heightAnchor, multiplier: constants.multiplierForNumberView), additionalButtonForFigures.centerXAnchor.constraint(equalTo: viewWhereToAdd.centerXAnchor), additionalButtonForFigures.centerYAnchor.constraint(equalTo: viewWhereToAdd.centerYAnchor)]
                    portraitConstraints += additionalButtonForFiguresConstraints
                    additionalButtonConstraints += additionalButtonForFiguresConstraints
                }
            }
        }
        let additionalButtonsConstraints = [additionalButtons.topAnchor.constraint(equalTo: arrowToAdditionalButtons.bottomAnchor), additionalButtons.leadingAnchor.constraint(equalTo: gameBoard.leadingAnchor), additionalButtons.heightAnchor.constraint(equalToConstant: heightForAdditionalButtons), showEndOfTheGameView.widthAnchor.constraint(equalTo: showEndOfTheGameView.heightAnchor)]
        let additionalButtonsForFiguresConstraints = [additionalButtonsForFigures.topAnchor.constraint(equalTo: additionalButtonForFigures.bottomAnchor), additionalButtonsForFigures.trailingAnchor.constraint(equalTo: gameBoard.trailingAnchor), additionalButtonsForFigures.heightAnchor.constraint(equalToConstant: heightForAdditionalButtons)]
        let player2FrameViewConstraints = [player2FrameView.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player2FrameView.topAnchor.constraint(equalTo: player2TitleView.bottomAnchor, constant: constants.distanceForTitle), player2FrameView.widthAnchor.constraint(equalToConstant: widthForFrame), player2FrameView.heightAnchor.constraint(equalToConstant: heightForFrame)]
        let player1FrameViewConstraints = [player1FrameView.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player1FrameView.topAnchor.constraint(equalTo: destroyedFigures2.bottomAnchor, constant: constants.optimalDistance), player1FrameView.widthAnchor.constraint(equalToConstant: widthForFrame), player1FrameView.heightAnchor.constraint(equalToConstant: heightForFrame)]
        let player2TitleViewConstraints = [player2TitleView.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player2TitleView.widthAnchor.constraint(equalToConstant: widthForFrame), player2TitleView.heightAnchor.constraint(equalToConstant: heightForFrame), player2TitleView.topAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.topAnchor)]
        let player1TitleViewConstraints = [player1TitleView.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player1TitleView.widthAnchor.constraint(equalToConstant: widthForFrame), player1TitleView.heightAnchor.constraint(equalToConstant: heightForFrame), player1TitleView.topAnchor.constraint(equalTo: player1FrameView.bottomAnchor, constant: constants.distanceForTitle), player1TitleView.bottomAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.bottomAnchor)]
        let player2FrameConstraintsDF = [player2FrameForDF.topAnchor.constraint(equalTo: player2FrameView.bottomAnchor, constant: constants.distanceForFrame), player2FrameForDF.widthAnchor.constraint(equalTo: destroyedFigures1.widthAnchor, constant: constants.optimalDistance), player2FrameForDF.heightAnchor.constraint(equalTo: destroyedFigures1.heightAnchor, constant: constants.optimalDistance), player2FrameForDF.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        let destroyedFigures1Constraints = [destroyedFigures1.topAnchor.constraint(equalTo: player2FrameView.bottomAnchor, constant: constants.optimalDistance), destroyedFigures1.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        let player1FrameConstraintsDF = [player1FrameForDF.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.distanceForFrame), player1FrameForDF.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player1FrameForDF.widthAnchor.constraint(equalTo: destroyedFigures1.widthAnchor, constant: constants.optimalDistance), player1FrameForDF.heightAnchor.constraint(equalTo: destroyedFigures1.heightAnchor, constant: constants.optimalDistance)]
        let destroyedFigures2Constraints = [destroyedFigures2.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.optimalDistance), destroyedFigures2.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        var player1TimerConstraints = [NSLayoutConstraint]()
        var player2TimerConstraints = [NSLayoutConstraint]()
        if gameLogic.timerEnabled {
            player1TimerConstraints = [player1Timer.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.optimalDistance), player1Timer.trailingAnchor.constraint(equalTo: gameBoard.trailingAnchor)]
            player2TimerConstraints = [player2Timer.bottomAnchor.constraint(equalTo: gameBoard.topAnchor, constant: -constants.optimalDistance), player2Timer.trailingAnchor.constraint(equalTo: gameBoard.trailingAnchor)]
        }
        portraitConstraints += additionalButtonsConstraints + additionalButtonsForFiguresConstraints + player2FrameViewConstraints + player1FrameViewConstraints + player2TitleViewConstraints + player1TitleViewConstraints + player2FrameConstraintsDF + destroyedFigures1Constraints + player1FrameConstraintsDF + destroyedFigures2Constraints + player1TimerConstraints + player2TimerConstraints
        timerConstraints += player1TimerConstraints + player2TimerConstraints
        additionalButtonConstraints += additionalButtonsConstraints + additionalButtonsForFiguresConstraints
    }
    
    private func makeLandscapeConstraints() {
        let heightForFrame = min(view.frame.width, view.frame.height)  / constants.heightDividerForFrame
        let player2FrameViewConstraints = [player2FrameView.centerYAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.centerYAnchor), player2FrameView.leadingAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.trailingAnchor, constant: constants.optimalDistance), player2FrameView.trailingAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.trailingAnchor, constant: -constants.optimalDistance), player2FrameView.heightAnchor.constraint(equalToConstant: heightForFrame)]
        let player1FrameViewConstraints = [player1FrameView.centerYAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.centerYAnchor), player1FrameView.trailingAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.leadingAnchor, constant: -constants.optimalDistance), player1FrameView.leadingAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.leadingAnchor, constant: constants.optimalDistance), player1FrameView.heightAnchor.constraint(equalToConstant: heightForFrame)]
        let player2TitleViewConstraints = [player2TitleView.topAnchor.constraint(equalTo: player2FrameView.layoutMarginsGuide.bottomAnchor, constant: constants.optimalDistance), player2TitleView.leadingAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.trailingAnchor, constant: constants.optimalDistance), player2TitleView.trailingAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.trailingAnchor, constant: -constants.optimalDistance), player2TitleView.heightAnchor.constraint(equalToConstant: heightForFrame)]
        let player1TitleViewConstraints = [player1TitleView.topAnchor.constraint(equalTo: player1FrameView.layoutMarginsGuide.bottomAnchor, constant: constants.optimalDistance), player1TitleView.trailingAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.leadingAnchor, constant: -constants.optimalDistance), player1TitleView.leadingAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.leadingAnchor, constant: constants.optimalDistance), player1TitleView.heightAnchor.constraint(equalToConstant: heightForFrame)]
        let player2FrameConstraintsDF = [player2FrameForDF.topAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.topAnchor, constant: constants.distanceForFrame), player2FrameForDF.widthAnchor.constraint(equalTo: destroyedFigures1.widthAnchor, constant: constants.optimalDistance), player2FrameForDF.heightAnchor.constraint(equalTo: destroyedFigures1.heightAnchor, constant: constants.optimalDistance), player2FrameForDF.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        let destroyedFigures1Constraints = [destroyedFigures1.topAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.topAnchor, constant: constants.optimalDistance), destroyedFigures1.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        let player1FrameConstraintsDF = [player1FrameForDF.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.distanceForFrame), player1FrameForDF.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player1FrameForDF.widthAnchor.constraint(equalTo: destroyedFigures2.widthAnchor, constant: constants.optimalDistance), player1FrameForDF.heightAnchor.constraint(equalTo: destroyedFigures2.heightAnchor, constant: constants.optimalDistance)]
        let destroyedFigures2Constraints = [destroyedFigures2.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.optimalDistance), destroyedFigures2.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), destroyedFigures2.bottomAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.bottomAnchor, constant: -constants.distanceToFitTurnsViewInLandscape)]
        landscapeConstraints += player2FrameViewConstraints + player1FrameViewConstraints + player2TitleViewConstraints + player1TitleViewConstraints + player2FrameConstraintsDF + destroyedFigures1Constraints + player1FrameConstraintsDF + destroyedFigures2Constraints + specialConstraints
    }
    
    //moves some views to top
    private func viewsOnTop() {
        scrollContentOfGame.bringSubviewToFront(turnsView)
        if gameLogic.timerEnabled {
            scrollContentOfGame.bringSubviewToFront(player1Timer)
            scrollContentOfGame.bringSubviewToFront(player2Timer)
        }
        scrollContentOfGame.bringSubviewToFront(arrowToAdditionalButtons)
        scrollContentOfGame.bringSubviewToFront(additionalButtons)
        scrollContentOfGame.bringSubviewToFront(additionalButtonsForFigures)
        scrollContentOfGame.bringSubviewToFront(pawnPicker)
        scrollContentOfGame.bringSubviewToFront(loadingSpinner)
    }
    
    private func setupViews() {
        turnsView.translatesAutoresizingMaskIntoConstraints = false
        scrollViewOfGame.translatesAutoresizingMaskIntoConstraints = false
        scrollViewOfGame.setValue(constants.animationDuration, forKey: "contentOffsetAnimationDuration")
        scrollContentOfGame.translatesAutoresizingMaskIntoConstraints = false
        endOfTheGameScrollView.translatesAutoresizingMaskIntoConstraints = false
        turnsScrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollViewOfGame.delaysContentTouches = false
        endOfTheGameScrollView.delaysContentTouches = false
        turnsScrollView.delaysContentTouches = false
        turnsView.alpha = 0
        additionalButtons.alpha = 0
        additionalButtonsForFigures.alpha = 0
        arrowToAdditionalButtons.alpha = 0
        showEndOfTheGameView.isEnabled = false
        turnBackward.isEnabled = gameLogic.rewindEnabled && !gameLogic.turns.isEmpty ? !gameLogic.firstTurn : false
        turnForward.isEnabled = gameLogic.rewindEnabled && !gameLogic.turns.isEmpty ? !gameLogic.lastTurn : false
        turnAction.isEnabled = gameLogic.rewindEnabled && !gameLogic.turns.isEmpty ? !gameLogic.lastTurn : false
        turns.isUserInteractionEnabled = gameLogic.rewindEnabled
        pawnPicker.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        gameBoard.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player1DestroyedFigures1.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player1DestroyedFigures2.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player2DestroyedFigures1.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player2DestroyedFigures2.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        additionalButtons.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        additionalButtonsForFigures.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        turns.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        turnData.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        turnsButtons.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        turnsButtons.layer.masksToBounds = true
        additionalButtonsForFigures.layer.masksToBounds = true
        endOfTheGameView.defaultSettings()
        additionalButtons.defaultSettings()
        additionalButtonsForFigures.defaultSettings()
        turnsButtons.defaultSettings()
        frameForEndOfTheGameView.defaultSettings()
        arrowToAdditionalButtons.defaultSettings()
        player2FrameForDF.defaultSettings()
        player1FrameForDF.defaultSettings()
        turnsButtons.backgroundColor = turnsButtons.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        arrowToAdditionalButtons.backgroundColor = constants.backgroundForArrow
        turnsScrollView.backgroundColor = .clear
        arrowToAdditionalButtons.contentMode = .scaleAspectFit
        arrowToAdditionalButtons.layer.borderWidth = 0
        currentPlayerForTurns = makeLabel(text: gameLogic.currentPlayer.user.nickname)
        currentPlayerForTurns.backgroundColor = currentPlayerDataColor
        if gameLogic.timerEnabled {
            player1Timer = makeTimer(with: gameLogic.players.first!.timeLeft.timeAsString)
            player2Timer = makeTimer(with: gameLogic.players.second!.timeLeft.timeAsString)
            player1TimerForTurns = makeTimer(with: gameLogic.players.first!.timeLeft.timeAsString)
            player2TimerForTurns = makeTimer(with: gameLogic.players.second!.timeLeft.timeAsString)
        }
    }
    
    private func makeTimer(with time: String) -> UILabel {
        let timer = makeLabel(text: time)
        timer.layer.cornerRadius = constants.cornerRadiusForChessTime
        timer.layer.masksToBounds = true
        timer.font = UIFont.monospacedDigitSystemFont(ofSize: timer.font.pointSize, weight: constants.weightForChessTime)
        return timer
    }
    
    private func makeScrollViewOfGame() {
        view.addSubview(scrollViewOfGame)
        scrollViewOfGame.addSubview(scrollContentOfGame)
        let contentHeight = scrollContentOfGame.heightAnchor.constraint(equalTo: scrollViewOfGame.heightAnchor)
        contentHeight.priority = .defaultLow
        let scrollViewConstraints = [scrollViewOfGame.leadingAnchor.constraint(equalTo: view.leadingAnchor), scrollViewOfGame.trailingAnchor.constraint(equalTo: view.trailingAnchor), scrollViewOfGame.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor), scrollViewOfGame.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)]
        let contentConstraints = [scrollContentOfGame.topAnchor.constraint(equalTo: scrollViewOfGame.topAnchor), scrollContentOfGame.bottomAnchor.constraint(equalTo: scrollViewOfGame.bottomAnchor), scrollContentOfGame.leadingAnchor.constraint(equalTo: scrollViewOfGame.leadingAnchor), scrollContentOfGame.trailingAnchor.constraint(equalTo: scrollViewOfGame.trailingAnchor), scrollContentOfGame.widthAnchor.constraint(equalTo: scrollViewOfGame.widthAnchor), contentHeight]
        NSLayoutConstraint.activate(scrollViewConstraints + contentConstraints)
    }
    
    private func makePlayer2Frame() {
        let player2Background = gameLogic.players.second!.user.playerBackground
        let player2Frame = gameLogic.players.second!.user.frame
        let player2Data = makeLabel(text: gameLogic.players.second!.user.nickname + " " + String(gameLogic.players.second!.user.points))
        player2FrameView = PlayerFrame(background: player2Background, playerFrame: player2Frame, data: player2Data)
        scrollContentOfGame.addSubview(player2FrameView)
        if gameLogic.gameMode == .oneScreen {
            player2FrameView.transform = player2FrameView.transform.rotated(by: .pi)
        }
        scrollContentOfGame.bringSubviewToFront(player2TitleView)
    }
    
    private func makePlayer1Frame() {
        let player1Background = gameLogic.players.first!.user.playerBackground
        let player1Frame = gameLogic.players.first!.user.frame
        let player1Data = makeLabel(text: gameLogic.players.first!.user.nickname + " " + String(gameLogic.players.first!.user.points))
        player1FrameView = PlayerFrame(background: player1Background, playerFrame: player1Frame, data: player1Data)
        scrollContentOfGame.addSubview(player1FrameView)
    }
    
    private func makePlayer2Title() {
        let player2Background = gameLogic.players.second!.user.playerBackground
        let player2Frame = gameLogic.players.second!.user.frame
        let player2Title = makeLabel(text: gameLogic.players.second!.user.title.rawValue.capitalizingFirstLetter().replacingOccurrences(of: "_", with: " "))
        player2TitleView = PlayerFrame(background: player2Background, playerFrame: player2Frame, data: player2Title)
        scrollContentOfGame.addSubview(player2TitleView)
        if gameLogic.gameMode == .oneScreen {
            player2TitleView.transform = player2TitleView.transform.rotated(by: .pi)
        }
    }
    
    private func makePlayer1Title() {
        let player1Background = gameLogic.players.first!.user.playerBackground
        let player1Frame = gameLogic.players.first!.user.frame
        let player1Title = makeLabel(text: gameLogic.players.first!.user.title.rawValue.capitalizingFirstLetter().replacingOccurrences(of: "_", with: " "))
        player1TitleView = PlayerFrame(background: player1Background, playerFrame: player1Frame, data: player1Title)
        scrollContentOfGame.addSubview(player1TitleView)
    }
    
    private func makeGameBoard() {
        let lettersLineTop = lettersLine
        //upside down for player 2
        for subview in lettersLineTop.arrangedSubviews {
            subview.transform = subview.transform.rotated(by: .pi)
        }
        gameBoard.addArrangedSubview(lettersLineTop)
        configureGameBoard()
        gameBoard.addArrangedSubview(lettersLine)
        scrollContentOfGame.addSubview(gameBoard)
        let gameBoardConstraints = [gameBoard.topAnchor.constraint(equalTo: destroyedFigures1.bottomAnchor, constant: constants.optimalDistance), gameBoard.centerXAnchor.constraint(equalTo: scrollContentOfGame.centerXAnchor)]
        NSLayoutConstraint.activate(gameBoardConstraints)
    }
    
    private func makePlayer2DestroyedFiguresView() {
        player2FrameForDF.image = UIImage(named: "frames/\(gameLogic.players.second!.user.frame.rawValue)")
        scrollContentOfGame.addSubview(player2FrameForDF)
        //in oneScreen second stack should be first, in other words upside down
        if gameLogic.gameMode == .oneScreen {
            player2FrameForDF.transform = player2FrameForDF.transform.rotated(by: .pi)
            destroyedFigures1 = makeDestroyedFiguresView(destroyedFigures1: player1DestroyedFigures2, destroyedFigures2: player1DestroyedFigures1, player2: true)
        }
        else if gameLogic.gameMode == .multiplayer{
            destroyedFigures1 = makeDestroyedFiguresView(destroyedFigures1: player1DestroyedFigures1, destroyedFigures2: player1DestroyedFigures2, player2: true)
        }
        scrollContentOfGame.addSubview(destroyedFigures1)
    }
    
    private func makePlayer1DestroyedFiguresView() {
        player1FrameForDF.image = UIImage(named: "frames/\(gameLogic.players.first!.user.frame.rawValue)")
        scrollContentOfGame.addSubview(player1FrameForDF)
        destroyedFigures2 = makeDestroyedFiguresView(destroyedFigures1: player2DestroyedFigures1, destroyedFigures2: player2DestroyedFigures2)
        scrollContentOfGame.addSubview(destroyedFigures2)
    }
    
    private func addPlayersBackgrounds() {
        let bottomPlayerBackground = UIImageView()
        bottomPlayerBackground.defaultSettings()
        bottomPlayerBackground.image = UIImage(named: "avatars/\(gameLogic.players.first!.user.playerAvatar.rawValue)")
        if gameLogic.gameMode == .multiplayer {
            let topPlayerBackground = UIImageView()
            topPlayerBackground.defaultSettings()
            topPlayerBackground.image = UIImage(named: "avatars/\(gameLogic.players.second!.user.playerAvatar.rawValue)")
            view.addSubviews([topPlayerBackground, bottomPlayerBackground])
            let topConstraints = [topPlayerBackground.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor), topPlayerBackground.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: constants.multiplierForBackground), topPlayerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor), topPlayerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
            let bottomConstraints = [bottomPlayerBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor), bottomPlayerBackground.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: constants.multiplierForBackground), bottomPlayerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor), bottomPlayerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
            NSLayoutConstraint.activate(topConstraints + bottomConstraints)
        }
        else {
            view.addSubview(bottomPlayerBackground)
            let bottomConstraints = [bottomPlayerBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor), bottomPlayerBackground.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor), bottomPlayerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor), bottomPlayerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
            NSLayoutConstraint.activate(bottomConstraints)
        }
    }
    
    private func configureGameBoard() {
        let operation: (Int, Int) -> Bool = gameLogic.players.first!.figuresColor == .white ? (>) : (<)
        let colorToRotate: GameColors = gameLogic.players.first!.figuresColor == .white ? .black : .white
        for coordinate in GameBoard.availableRows.sorted(by: operation) {
            //line contains number at the start and end and 8 squares
            let line = UIStackView()
            line.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
            line.addArrangedSubview(getNumberSquareView(number: coordinate))
            for column in GameBoard.availableColumns {
                if let square = gameLogic.gameBoard[column, coordinate] {
                    var figureImage: UIImage?
                    if let figure = square.figure {
                        if square.figure?.color == .black {
                            let figuresThemeName = gameLogic.players.second!.user.figuresTheme.rawValue
                            figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(figure.color.rawValue)_\(figure.name.rawValue)")
                        }
                        else {
                            let figuresThemeName = gameLogic.players.first!.user.figuresTheme.rawValue
                            figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(figure.color.rawValue)_\(figure.name.rawValue)")
                        }
                        if gameLogic.gameMode == .oneScreen && square.figure?.color == colorToRotate {
                            //we are not using transform here to not have problems with animation
                            figureImage = figureImage?.rotate(radians: .pi)
                        }
                    }
                    let squareView = getSquareView(image: figureImage, figure: square.figure)
                    switch square.color {
                    case .white:
                        squareView.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.getTheme().firstColor)
                    case .black:
                        squareView.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.getTheme().secondColor)
                    case .random:
                        fatalError("Somehow we have .random color!")
                    }
                    squareView.layer.setValue(square, forKey: constants.keyNameForSquare)
                    let tap = UITapGestureRecognizer(target: self, action: #selector(chooseSquare))
                    squareView.addGestureRecognizer(tap)
                    squares.append(squareView)
                    line.addArrangedSubview(squareView)
                }
            }
            let numberSquareRight = getNumberSquareView(number: coordinate)
            //upside down for player 2
            for subview in numberSquareRight.subviews {
                subview.transform = subview.transform.rotated(by: .pi)
            }
            line.addArrangedSubview(numberSquareRight)
            gameBoard.addArrangedSubview(line)
        }
    }
    
    private func getSquareView(image: UIImage? = nil, figure: Figure? = nil, multiplier: CGFloat = 1) -> UIImageView {
        let square = UIImageView()
        let width = min(view.frame.width, view.frame.height)  / constants.dividerForSquare * multiplier
        square.rectangleView(width: width)
        square.layer.borderWidth = 0
        //when we animating, border is always on top, so we have to add it as subview instead
        let border = UIImageView()
        border.rectangleView(width: width)
        square.addSubview(border)
        let borderConstraints = [border.centerXAnchor.constraint(equalTo: square.centerXAnchor), border.centerYAnchor.constraint(equalTo: square.centerYAnchor)]
        NSLayoutConstraint.activate(borderConstraints)
        //we are adding image in this way, so we can move figure separately from square
        if image != nil {
            let imageView = UIImageView()
            imageView.rectangleView(width: width)
            imageView.layer.borderWidth = 0
            imageView.image = image
            imageView.layer.setValue(figure, forKey: constants.keyForFIgure)
            square.addSubview(imageView)
            let imageViewConstraints = [imageView.centerXAnchor.constraint(equalTo: square.centerXAnchor), imageView.centerYAnchor.constraint(equalTo: square.centerYAnchor)]
            NSLayoutConstraint.activate(imageViewConstraints)
        }
        return square
    }
    
    //according to current design, we need to make number image smaller
    private func getNumberSquareView(number: Int) -> UIImageView {
        var square = UIImageView()
        let boardTheme = gameLogic.boardTheme.rawValue
        square = getSquareView(image: UIImage(named: "boardThemes/\(boardTheme)/letter"))
        let numberView = getSquareView(image: UIImage(named: "boardThemes/\(boardTheme)/number_\(number)"), multiplier: constants.multiplierForNumberView)
        numberView.subviews.first!.layer.borderWidth = 0
        square.addSubview(numberView)
        let numberViewConstraints = [numberView.centerXAnchor.constraint(equalTo: square.centerXAnchor), numberView.centerYAnchor.constraint(equalTo: square.centerYAnchor)]
        NSLayoutConstraint.activate(numberViewConstraints)
        return square
    }
    
    private func makeLabel(text: String) -> UILabel {
        let label = UILabel()
        label.setup(text: text, alignment: .center, font: UIFont.systemFont(ofSize: min(view.frame.width, view.frame.height) / constants.dividerForFont))
        return label
    }
    
    private func makePawnPicker(figure: Figure, squareColor: GameColors) {
        let figuresNames: [Figures] = [.rook, .queen, .bishop, .knight]
        for figureName in figuresNames {
            let pawnPickerFigure = Figure(name: figureName, color: figure.color, startColumn: figure.startColumn, startRow: figure.startRow)
            let square = Square(column: gameLogic.turns.last!.squares.last!.column, row: gameLogic.turns.last!.squares.last!.row, color: gameLogic.turns.last!.squares.last!.color, gameID: gameLogic.gameID, figure: pawnPickerFigure)
            let figuresThemeName = gameLogic.currentPlayer.user.figuresTheme.rawValue
            let figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(pawnPickerFigure.color.rawValue)_\(figureName.rawValue)")
            let squareView = getSquareView(image: figureImage, figure: pawnPickerFigure)
            squareView.layer.setValue(square, forKey: constants.keyNameForSquare)
            let tap = UITapGestureRecognizer(target: self, action: #selector(replacePawn))
            squareView.addGestureRecognizer(tap)
            squareView.subviews.first!.layer.borderColor = squareColor == .black ? UIColor.white.cgColor : UIColor.black.cgColor
            pawnPicker.addArrangedSubview(squareView)
        }
        if gameLogic.gameMode == .multiplayer {
            if gameLogic.currentPlayer.multiplayerType != gameLogic.players.first?.multiplayerType {
                pawnPicker.isUserInteractionEnabled = false
            }
            else {
                pawnPicker.isUserInteractionEnabled = true
            }
        }
    }

    private func makeDestroyedFiguresView(destroyedFigures1: UIStackView, destroyedFigures2: UIStackView, player2: Bool = false) -> UIView {
        let width = min(view.frame.width, view.frame.height)  / constants.widthDividerForTrash
        let height = min(view.frame.width, view.frame.height)  / constants.heightDividerForTrash
        let destroyedFiguresBackground = UIImageView()
        destroyedFiguresBackground.defaultSettings()
        let destroyedFigures = UIImageView()
        destroyedFigures.defaultSettings()
        destroyedFigures.layer.masksToBounds = false
        destroyedFigures.addSubviews([destroyedFiguresBackground, destroyedFigures1, destroyedFigures2])
        let destroyedFiguresConstraints1 = [destroyedFigures.widthAnchor.constraint(equalToConstant: width), destroyedFigures.heightAnchor.constraint(equalToConstant: height)]
        let destroyedFiguresConstraints2 = [destroyedFigures1.topAnchor.constraint(equalTo: destroyedFigures.topAnchor, constant: constants.distanceForFigureInTrash), destroyedFigures2.bottomAnchor.constraint(equalTo: destroyedFigures.bottomAnchor, constant: -constants.distanceForFigureInTrash)]
        var destroyedFiguresConstraints3: [NSLayoutConstraint] = []
        //here we add this, because stacks start from left side, but for player 2 they should start from right side
        if player2 && gameLogic.gameMode == .oneScreen {
            destroyedFiguresConstraints3 = [destroyedFigures1.trailingAnchor.constraint(equalTo: destroyedFigures.trailingAnchor), destroyedFigures2.trailingAnchor.constraint(equalTo: destroyedFigures.trailingAnchor)]
        }
        else {
            destroyedFiguresConstraints3 = [destroyedFigures1.leadingAnchor.constraint(equalTo: destroyedFigures.leadingAnchor), destroyedFigures2.leadingAnchor.constraint(equalTo: destroyedFigures.leadingAnchor)]
        }
        let backgroundConstraints = [destroyedFiguresBackground.leadingAnchor.constraint(equalTo: destroyedFigures.leadingAnchor), destroyedFiguresBackground.trailingAnchor.constraint(equalTo: destroyedFigures.trailingAnchor), destroyedFiguresBackground.topAnchor.constraint(equalTo: destroyedFigures.topAnchor), destroyedFiguresBackground.bottomAnchor.constraint(equalTo: destroyedFigures.bottomAnchor)]
        NSLayoutConstraint.activate(destroyedFiguresConstraints1 + destroyedFiguresConstraints2 + destroyedFiguresConstraints3 + backgroundConstraints)
        var image = UIImage(named: "backgrounds/\(gameLogic.players.first!.user.playerBackground.rawValue)")
        if player2 {
            image = UIImage(named: "backgrounds/\(gameLogic.players.second!.user.playerBackground.rawValue)")
            if gameLogic.gameMode == .oneScreen {
                image = image?.rotate(radians: .pi)
            }
        }
        image = image?.alpha(constants.alphaForTrashBackground)
        destroyedFiguresBackground.image = image
        return destroyedFigures
    }
    
    private func makeEndOfTheGameView() {
        //updatePlayersTime()
        deactivateMultiplayerTImers()
        saveButton.isEnabled = false
        showEndOfTheGameView.isEnabled = true
        surrenderButton.isEnabled = false
        //if there is no winner, it means, that it is a draw and we will choose data of current user
        let winner = gameLogic.winner ?? gameLogic.players.first!
        frameForEndOfTheGameView.image = UIImage(named: "frames/\(winner.user.frame.rawValue)")
        let winnerBackground = UIImage(named: "backgrounds/\(winner.user.playerBackground.rawValue)")?.alpha(constants.alphaForPlayerBackground)
        let data = makeEndOfTheGameData()
        endOfTheGameView.image = winnerBackground
        view.addSubviews([frameForEndOfTheGameView, endOfTheGameView, endOfTheGameScrollView])
        endOfTheGameScrollView.addSubview(data)
        frameForEndOfTheGameView.alpha = 0
        endOfTheGameView.alpha = 0
        endOfTheGameScrollView.alpha = 0
        if !loadedEndedGame {
            if !gameLogic.turns.isEmpty {
                currentUser.updatePoints(newValue: gameLogic.players.first!.user.points)
                currentUser.addGame(gameLogic)
                storage.saveUser(currentUser)
                gameLogic.saveGameDataForRestore()
            }
            for view in [frameForEndOfTheGameView, endOfTheGameView, endOfTheGameScrollView] {
                animateTransition(of: view)
            }
        }
        let contentHeight = data.heightAnchor.constraint(equalTo: endOfTheGameScrollView.heightAnchor)
        contentHeight.priority = .defaultLow
        let scrollViewConstraints = [endOfTheGameScrollView.leadingAnchor.constraint(equalTo: endOfTheGameView.leadingAnchor), endOfTheGameScrollView.trailingAnchor.constraint(equalTo: endOfTheGameView.trailingAnchor), endOfTheGameScrollView.topAnchor.constraint(equalTo: endOfTheGameView.topAnchor), endOfTheGameScrollView.bottomAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.bottomAnchor)]
        let contentConstraints = [data.topAnchor.constraint(equalTo: endOfTheGameScrollView.topAnchor), data.bottomAnchor.constraint(equalTo: endOfTheGameScrollView.bottomAnchor), data.leadingAnchor.constraint(equalTo: endOfTheGameScrollView.leadingAnchor), data.trailingAnchor.constraint(equalTo: endOfTheGameScrollView.trailingAnchor), data.widthAnchor.constraint(equalTo: endOfTheGameScrollView.widthAnchor), contentHeight]
        NSLayoutConstraint.activate(scrollViewConstraints + contentConstraints)
        let endOfTheGameViewConstraints = [endOfTheGameView.centerXAnchor.constraint(equalTo: view.centerXAnchor), endOfTheGameView.centerYAnchor.constraint(equalTo: view.centerYAnchor), endOfTheGameView.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor), endOfTheGameView.heightAnchor.constraint(equalTo: view.layoutMarginsGuide.heightAnchor, multiplier: constants.heightMultiplierForEndOfTheGameView)]
        let frameForEndOfTheGameViewConstraints = [frameForEndOfTheGameView.centerXAnchor.constraint(equalTo: view.centerXAnchor), frameForEndOfTheGameView.centerYAnchor.constraint(equalTo: view.centerYAnchor), frameForEndOfTheGameView.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor, constant: constants.optimalDistance), frameForEndOfTheGameView.heightAnchor.constraint(equalTo: view.layoutMarginsGuide.heightAnchor, multiplier: constants.heightMultiplierForEndOfTheGameView, constant: constants.optimalDistance)]
        NSLayoutConstraint.activate(endOfTheGameViewConstraints + frameForEndOfTheGameViewConstraints)
    }
    
    //shows/hides view with animation
    private func animateTransition(of view: UIView, startAlpha: CGFloat = 0) {
        view.alpha = startAlpha
        UIView.animate(withDuration: constants.animationDuration, animations: {
            view.alpha = startAlpha == 0 ? 1 : 0
        })
    }
    
    //shows/hides turns view from/to middle of the game board
    private func animateTurnsView() {
        let turnsCenterY = turnsView.center.y
        let gameBoardCenterY = gameBoard.center.y
        if turnsView.alpha == 0 {
            turnsView.transform = CGAffineTransform(translationX: 0, y: gameBoardCenterY - turnsCenterY)
            UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
                self?.turnsView.transform = .identity
                self?.turnsView.alpha = 1
            })
        }
        else {
            UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
                self?.turnsView.transform = CGAffineTransform(translationX: 0, y: gameBoardCenterY - turnsCenterY)
                self?.turnsView.alpha = 0
            }) {[weak self] _ in
                self?.turnsView.transform = .identity
            }
        }
    }
    
    //shows/hides additional buttons with animation
    private func animateAdditionalButtons(arrowToAdditionalButtons: UIView? = nil, additionalButton: UIView, additionalButtons: UIView) {
        let currentTransformOfArrow = self.currentTransformOfArrow
        let positionOfAdditionalButton = getFrameForAnimation(firstView: scrollContentOfGame, secondView: additionalButton).origin
        let positionOfArrow = arrowToAdditionalButtons?.layer.position
        let positionOfAdditButtons = additionalButtons.layer.position
        if additionalButtons.alpha == 0 {
            //curtain animation
            additionalButtons.transform = constants.transformForAdditionalButtons
            arrowToAdditionalButtons?.transform = currentTransformOfArrow.concatenating(constants.transformForAdditionalButtons)
            //this comment saved for history :d
            //as i realized, we can`t rotate and translate view at the same time, cuz weird
            //animation occurs, so i decided to make it in this way (change center and then
            //comeback to original value in animation block), which leads to beautiful
            //animation (now it really looks like the additional buttons are pop out from button
            //or enters the button, which shows/hides them), exactly as i wanted to :)
            //
            //P.S. i also realized, that we cant animate by changing center, cuz, if view will triger layout update,
            //then our animation will fucked up, so i decided to rewrite it with CAAnimation
            //P.P.S. i think i should rewrite some more animations with CAAnimation, cuz in some situations its working much better imho
            arrowToAdditionalButtons?.layer.position = positionOfAdditionalButton
            additionalButtons.layer.position = positionOfAdditionalButton
            arrowToAdditionalButtons?.layer.moveTo(position: positionOfArrow ?? .zero, animated: true, duration: constants.animationDuration)
            additionalButtons.layer.moveTo(position: positionOfAdditButtons, animated: true, duration: constants.animationDuration)
            UIView.animate(withDuration: constants.animationDuration, animations: {
                arrowToAdditionalButtons?.transform = currentTransformOfArrow.rotated(by: .pi)
                additionalButtons.transform = .identity
                additionalButtons.alpha = 1
                arrowToAdditionalButtons?.alpha = 1
            })
        }
        else {
            arrowToAdditionalButtons?.layer.moveTo(position: positionOfAdditionalButton, animated: true, duration: constants.animationDuration)
            additionalButtons.layer.moveTo(position: positionOfAdditionalButton, animated: true, duration: constants.animationDuration)
            arrowToAdditionalButtons?.layer.position = positionOfArrow ?? .zero
            additionalButtons.layer.position = positionOfAdditButtons
            UIView.animate(withDuration: constants.animationDuration, animations: {
                additionalButtons.transform = constants.transformForAdditionalButtons
                arrowToAdditionalButtons?.transform = currentTransformOfArrow.concatenating(constants.transformForAdditionalButtons)
                arrowToAdditionalButtons?.alpha = 0
                additionalButtons.alpha = 0
            }) { _ in
                additionalButtons.transform = .identity
                arrowToAdditionalButtons?.transform = currentTransformOfArrow
            }
        }
    }
    
    private func makeInfoStack() -> UIStackView {
        //just for animation
        let startPoints = gameLogic.players.first!.user.points - gameLogic.players.first!.pointsForGame
        var endPoints = gameLogic.players.first!.user.points
        let startRank = gameLogic.players.first!.user.getRank(from: startPoints)
        let factor = endPoints > startPoints ? gameLogic.players.first!.pointsForGame / constants.dividerForFactorForPointsAnimation : -(gameLogic.players.first!.pointsForGame / constants.dividerForFactorForPointsAnimation)
        let infoStack = UIStackView()
        infoStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let rankLabel = makeLabel(text: startRank.rawValue)
        let pointsLabel = makeLabel(text: String(startPoints))
        playerProgress.backgroundColor = constants.backgroundColorForProgressBar
        //how much percentage is filled
        playerProgress.progress = CGFloat(startPoints * 100 / gameLogic.players.first!.user.rank.maximumPoints) / 100.0
        if endPoints < 0 {
            endPoints = 0
        }
        animatePoints(interval: constants.intervalForPointsAnimation, startPoints: startPoints, endPoints: endPoints, playerProgress: playerProgress, pointsLabel: pointsLabel, factor: factor, rank: startRank, rankLabel: rankLabel)
        infoStack.addArrangedSubviews([rankLabel, playerProgress, pointsLabel])
        return infoStack
    }
    
    //points increasing animation
    private func animatePoints(interval: Double, startPoints: Int, endPoints: Int, playerProgress: ProgressBar, pointsLabel: UILabel, factor: Int, rank: Ranks, rankLabel: UILabel) {
        var currentPoints = startPoints
        var rank = rank
        //1 is maximum value for progress, we convert rank points to this to properly fill progress bar
        //in other words if points for rank is 5000 the speed for filling the bar should be slower, than
        //if points for rank is 500
        var progressPoints = 1.0 / CGFloat(rank.maximumPoints - rank.minimumPoints)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: {[weak self] timer in
            if currentPoints == endPoints {
                timer.invalidate()
                return
            }
            playerProgress.progress += currentPoints < endPoints ? progressPoints : -progressPoints
            currentPoints += currentPoints < endPoints ? constants.pointsAnimationStep : -constants.pointsAnimationStep
            if currentPoints == rank.nextRank.minimumPoints || currentPoints == rank.previousRank.maximumPoints {
                rank = currentPoints == rank.nextRank.minimumPoints ? rank.nextRank : rank.previousRank
                rankLabel.text = rank.rawValue
                progressPoints = 1.0 / CGFloat(rank.maximumPoints - rank.minimumPoints)
            }
            pointsLabel.text = String(currentPoints)
            //slow down when we are getting closer to end value
            //in other words new timer with bigger interval
            if currentPoints + factor == endPoints {
                timer.invalidate()
                self?.animatePoints(interval: interval * constants.muttiplierForIntervalForPointsAnimation, startPoints: currentPoints, endPoints: endPoints, playerProgress: playerProgress, pointsLabel: pointsLabel, factor: factor / constants.dividerForFactorForPointsAnimation, rank: rank, rankLabel: rankLabel)
            }
        })
        RunLoop.main.add(timer, forMode: .common)
    }
    
    private func makeEndOfTheGameData() -> UIImageView {
        toggleTurnButtons(disable: false)
        let hideButton = UIButton()
        hideButton.buttonWith(image: UIImage(systemName: "eye.slash"), and: #selector(transitEndOfTheGameView))
        let data = UIImageView()
        data.defaultSettings()
        data.isUserInteractionEnabled = true
        data.backgroundColor = data.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        let playerAvatarImage = UIImage(named: "avatars/\(gameLogic.players.first!.user.playerAvatar.rawValue)")
        let playerAvatar = UIImageView()
        playerAvatar.rectangleView(width: min(view.frame.width, view.frame.height) / constants.dividerForPlayerAvatar)
        playerAvatar.contentMode = .scaleAspectFill
        playerAvatar.layer.masksToBounds = true
        playerAvatar.image = playerAvatarImage
        var hideButtonConstraints = [NSLayoutConstraint]()
        var wheelConstraints = [NSLayoutConstraint]()
        if !loadedEndedGame && gameLogic.gameMode != .oneScreen && !gameLogic.turns.isEmpty {
            let wheel = WheelOfFortune(figuresTheme: gameLogic.players.first!.user.figuresTheme, maximumCoins: gameLogic.maximumCoinsForWheel)
            wheel.translatesAutoresizingMaskIntoConstraints = false
            currentUser.addCoins(wheel.winCoins)
            data.addSubview(wheel)
            wheelConstraints = [wheel.topAnchor.constraint(equalTo: playerAvatar.bottomAnchor, constant: constants.optimalDistance), wheel.centerXAnchor.constraint(equalTo: data.centerXAnchor), wheel.heightAnchor.constraint(equalTo: wheel.widthAnchor), wheel.leadingAnchor.constraint(equalTo: data.layoutMarginsGuide.leadingAnchor, constant: constants.optimalDistance), wheel.trailingAnchor.constraint(equalTo: data.layoutMarginsGuide.trailingAnchor, constant: -constants.optimalDistance)]
            hideButtonConstraints.append(hideButton.topAnchor.constraint(equalTo: wheel.bottomAnchor, constant: constants.optimalDistance))
        }
        else {
            hideButtonConstraints.append(hideButton.topAnchor.constraint(equalTo: playerAvatar.bottomAnchor, constant: constants.optimalDistance))
        }
        var titleText = "Congrats!"
        if gameLogic.winner == nil {
            titleText = "What a game, but it is a draw!"
        }
        else if gameLogic.winner == gameLogic.players.second! {
            titleText = "Better luck next time!"
        }
        let infoStack = makeInfoStack()
        let titleLabel = makeLabel(text: titleText)
        let nicknameLabel = makeLabel(text: "\(gameLogic.players.first!.user.nickname)")
        data.addSubviews([nicknameLabel, titleLabel, infoStack, playerAvatar, hideButton])
        let titleLabelConstraints = [titleLabel.centerXAnchor.constraint(equalTo: data.centerXAnchor), titleLabel.topAnchor.constraint(equalTo: data.topAnchor, constant: constants.optimalDistance), titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: data.leadingAnchor, constant: constants.optimalDistance), titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: data.trailingAnchor, constant: -constants.optimalDistance)]
        let playerDataConstraints = [nicknameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: constants.optimalDistance), nicknameLabel.centerXAnchor.constraint(equalTo: data.centerXAnchor), nicknameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: data.layoutMarginsGuide.leadingAnchor), nicknameLabel.trailingAnchor.constraint(lessThanOrEqualTo: data.layoutMarginsGuide.trailingAnchor), playerAvatar.topAnchor.constraint(equalTo: nicknameLabel.bottomAnchor, constant: constants.optimalDistance), playerAvatar.leadingAnchor.constraint(equalTo: data.leadingAnchor, constant: constants.optimalDistance), infoStack.centerYAnchor.constraint(equalTo: playerAvatar.centerYAnchor),  infoStack.leadingAnchor.constraint(equalTo: playerAvatar.trailingAnchor, constant: constants.optimalDistance), infoStack.trailingAnchor.constraint(equalTo: data.trailingAnchor, constant: -constants.optimalDistance)]
        hideButtonConstraints += [hideButton.centerXAnchor.constraint(equalTo: data.centerXAnchor), hideButton.widthAnchor.constraint(equalToConstant: min(view.frame.width, view.frame.height) / constants.dividerForButton), hideButton.heightAnchor.constraint(equalTo: hideButton.widthAnchor), hideButton.bottomAnchor.constraint(equalTo: data.layoutMarginsGuide.bottomAnchor)]
        NSLayoutConstraint.activate(titleLabelConstraints + playerDataConstraints + hideButtonConstraints + wheelConstraints)
        return data
    }
    
    //makes chess timers
    private func makeTimers() {
        scrollContentOfGame.addSubviews([player1Timer, player2Timer])
        if gameLogic.gameMode == .oneScreen {
            player2Timer.transform = player2Timer.transform.rotated(by: .pi)
        }
    }
    
    private func makeTurnsView() {
        let heightForButtons = min(view.frame.width, view.frame.height)  / constants.dividerForSquare
        let playerBackground = UIImage(named: "backgrounds/\(gameLogic.players.first!.user.playerBackground.rawValue)")
        let background = UIImageView()
        background.defaultSettings()
        background.image = playerBackground
        background.contentMode = .scaleAspectFill
        let turnsContent = UIView()
        turnsContent.translatesAutoresizingMaskIntoConstraints = false
        turnBackward.buttonWith(image: UIImage(systemName: "backward"), and: #selector(turnsBackward))
        turnForward.buttonWith(image: UIImage(systemName: "forward"), and: #selector(turnsForward))
        turnAction.buttonWith(image: UIImage(systemName: "play"), and: #selector(turnsAction))
        let hideButton = UIButton()
        hideButton.buttonWith(image: UIImage(systemName: "eye.slash"), and: #selector(transitTurnsView))
        restoreButton.buttonWith(image: UIImage(systemName: "arrow.uturn.backward"), and: #selector(restoreGame))
        restoreButton.isEnabled = false
        fastAnimationsButton.buttonWith(image: UIImage(systemName: "timer"), and: #selector(toggleFastAnimations))
        fastAnimationsButton.backgroundColor = constants.dangerPlayerDataColor
        let buttons = [turnBackward, turnAction, turnForward, hideButton, restoreButton, fastAnimationsButton]
        if gameLogic.gameEnded || gameLogic.gameMode == .oneScreen {
            if currentUser.games.contains(where: {$0.startDate == gameLogic.startDate}) {
                restoreButton.isEnabled = gameLogic.rewindEnabled
            }
        }
        turnsButtons.addArrangedSubviews(buttons)
        let gameInfo = UIStackView()
        gameInfo.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        gameInfo.defaultSettings()
        gameInfo.backgroundColor = gameInfo.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        gameInfo.addArrangedSubview(currentPlayerForTurns)
        if gameLogic.timerEnabled {
            gameInfo.addArrangedSubviews([player1TimerForTurns, player2TimerForTurns])
        }
        gameInfo.layer.masksToBounds = true
        turnsView.addSubviews([background, turnsScrollView, turnsButtons, gameInfo])
        turnsContent.addSubview(turns)
        turnsScrollView.addSubview(turnsContent)
        scrollContentOfGame.addSubview(turnsView)
        let contentHeight = turnsContent.heightAnchor.constraint(equalTo: turnsScrollView.heightAnchor)
        contentHeight.priority = .defaultLow
        let gameInfoConstraints = [gameInfo.topAnchor.constraint(equalTo: turnsButtons.bottomAnchor, constant: constants.distanceForGameInfoInTurnsView), gameInfo.leadingAnchor.constraint(equalTo: turnsView.layoutMarginsGuide.leadingAnchor), gameInfo.trailingAnchor.constraint(equalTo: turnsView.layoutMarginsGuide.trailingAnchor)]
        let turnsViewConstraints = [turnsView.leadingAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.leadingAnchor), turnsView.trailingAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.trailingAnchor), turnsView.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.distanceForTurns), turnsView.bottomAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.bottomAnchor)]
        let turnsScrollViewConstraints = [turnsScrollView.leadingAnchor.constraint(equalTo: turnsView.leadingAnchor), turnsScrollView.trailingAnchor.constraint(equalTo: turnsView.trailingAnchor), turnsScrollView.topAnchor.constraint(equalTo: gameInfo.bottomAnchor, constant: constants.topDistanceForTurnsScrollView), turnsScrollView.bottomAnchor.constraint(lessThanOrEqualTo: turnsView.bottomAnchor)]
        let contentConstraints = [turnsContent.topAnchor.constraint(equalTo: turnsScrollView.topAnchor), turnsContent.bottomAnchor.constraint(equalTo: turnsScrollView.bottomAnchor), turnsContent.leadingAnchor.constraint(equalTo: turnsScrollView.leadingAnchor), turnsContent.trailingAnchor.constraint(equalTo: turnsScrollView.trailingAnchor), turnsContent.widthAnchor.constraint(equalTo: turnsScrollView.widthAnchor), contentHeight]
        let buttonsConstraints = [turnsButtons.topAnchor.constraint(equalTo: turnsView.topAnchor), turnsButtons.centerXAnchor.constraint(equalTo: turnsView.centerXAnchor), turnsButtons.heightAnchor.constraint(equalToConstant: heightForButtons), turnBackward.widthAnchor.constraint(equalToConstant: heightForButtons)]
        let turnsConstraints = [turns.topAnchor.constraint(equalTo: turnsContent.layoutMarginsGuide.topAnchor), turns.bottomAnchor.constraint(equalTo: turnsContent.layoutMarginsGuide.bottomAnchor), turns.leadingAnchor.constraint(equalTo: turnsContent.layoutMarginsGuide.leadingAnchor), turns.trailingAnchor.constraint(equalTo: turnsContent.layoutMarginsGuide.trailingAnchor)]
        let backgroundConstraints = [background.widthAnchor.constraint(equalTo: turnsView.widthAnchor), background.heightAnchor.constraint(equalTo: turnsView.heightAnchor), background.centerXAnchor.constraint(equalTo: turnsView.centerXAnchor), background.centerYAnchor.constraint(equalTo: turnsView.centerYAnchor)]
        NSLayoutConstraint.activate(turnsViewConstraints + contentConstraints + buttonsConstraints + turnsConstraints + backgroundConstraints + turnsScrollViewConstraints + gameInfoConstraints)
    }
    
    private func makeLoadingSpinner() {
        loadingSpinner.removeFromSuperview()
        loadingSpinner = LoadingSpinner()
        scrollContentOfGame.addSubview(loadingSpinner)
        let spinnerConstraints = [loadingSpinner.centerXAnchor.constraint(equalTo: gameBoard.centerXAnchor), loadingSpinner.centerYAnchor.constraint(equalTo: gameBoard.centerYAnchor), loadingSpinner.widthAnchor.constraint(equalTo: gameBoard.widthAnchor, multiplier: constants.sizeMultiplierForSpinnerView), loadingSpinner.heightAnchor.constraint(equalTo: gameBoard.heightAnchor, multiplier: constants.sizeMultiplierForSpinnerView)]
        NSLayoutConstraint.activate(spinnerConstraints)
    }
    
    //TODO: -
    
    //add chat
    
}

// MARK: - Constants

private struct GameVC_Constants {
    static let heightMultiplierForEndOfTheGameView = 0.5
    static let defaultLightModeColorForDataBackground = UIColor.white.withAlphaComponent(optimalAlpha)
    static let defaultDarkModeColorForDataBackground = UIColor.black.withAlphaComponent(optimalAlpha)
    static let dangerPlayerDataColor = UIColor.red.withAlphaComponent(optimalAlpha)
    static let dangerTimeleft = 20
    static let currentPlayerDataColorLightMode = UIColor.green.withAlphaComponent(optimalAlpha)
    static let currentPlayerDataColorDarkMode = UIColor.green.adjust(by: -30.0).withAlphaComponent(optimalAlpha)
    static let multiplierForBackground: CGFloat = 0.5
    static let alphaForTrashBackground: CGFloat = 1
    static let alphaForPlayerBackground: CGFloat = 0.5
    static let optimalAlpha: CGFloat = 0.7
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(0.5)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(0.5)
    static let distanceForFigureInTrash: CGFloat = 3
    static let distanceForTurns: CGFloat = 5
    static let multiplierForNumberView: CGFloat = 0.6
    static let optimalDistance: CGFloat = 20
    static let animationDuration = 0.5
    static let maxFiguresInTrashLine = 8
    static let dividerForFont: CGFloat = 13
    static let dividerForSquare: CGFloat = 11
    static let distanceForFrame: CGFloat = optimalDistance / 2
    static let widthDividerForTrash: CGFloat = dividerForSquare / 8.5
    static let heightDividerForTrash: CGFloat = dividerForSquare / 2.5
    static let heightDividerForFrame: CGFloat = dividerForSquare / 2
    static let heightDividerForTitle: CGFloat = dividerForSquare / 1
    static let distanceForTitle: CGFloat = -10
    static let optimalSpacing: CGFloat = 5
    static let keyNameForSquare = "Square"
    static let keyNameForTurn = "Turn"
    static let keyForFigureColor = "figureColor"
    static let keyForFIgure = "Figure"
    static let dividerForWheelRadius: CGFloat = 1.7
    static let dividerForFactorForPointsAnimation = 2
    static let intervalForPointsAnimation = 0.1
    static let muttiplierForIntervalForPointsAnimation = 1.8
    static let pointsAnimationStep = 1
    static let dividerForPlayerAvatar = 3.0
    static let dividerForEndDataDistance = 2.0
    static let dividerForButton = 6.0
    static let distanceAfterWheel: CGFloat = 80
    static let backgroundColorForProgressBar = UIColor.white
    static let backgroundForArrow = UIColor.clear
    static let cornerRadiusForChessTime = 7.0
    static let weightForChessTime = UIFont.Weight.regular
    static let transformForAdditionalButtons = CGAffineTransform(scaleX: 0.1,y: 0.1)
    static let shortCastleNotation = "0-0"
    static let longCastleNotation = "0-0-0"
    static let checkmateNotation = "#"
    static let checkNotation = "+"
    static let figureEatenNotation = "x"
    static let sizeMultiplierForSpinnerView = 0.8
    static let distanceToFitTurnsViewInLandscape = 100.0
    static let distanceForGameInfoInTurnsView = 2.0
    static let topDistanceForTurnsScrollView = 5.0
    static let surrenderButtonHighlightColor = UIColor.yellow.withAlphaComponent(optimalAlpha)
    static let requestTimeout = 5.0
    static let timeToAcceptDraw = 30.0
    static let surrenderButtonBGColor = UIColor.clear
    static let extraTimeForEnemyAFKTimer = 10.0
    static let maxTimeForAFK = 300.0
    static let chessTimerStep = 1.0
    
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

