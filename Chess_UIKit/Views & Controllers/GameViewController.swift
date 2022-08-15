//
//  GameViewController.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.06.2022.
//

import UIKit

//VC that represents game view
class GameViewController: UIViewController {
    
    // MARK: - View Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        activateStartConstraints()
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
    
    // MARK: - Properties
    
    //used in playback of the turns and also to have ability to stop it
    private var turnsActionTimers: [Timer] = []
    private let gameLogic = GameLogic()
    private var backwardRewind = false
    private var forwardRewind = false
    //we are storing all animations to have ability to finish them all at once
    private var animations: [UIViewPropertyAnimator] = []
    //animation of moving the figure to trash
    //we are not storing it in animations, cuz we cancel it only, before start new one
    private var trashAnimation: UIViewPropertyAnimator?
    
    private typealias constants = GameVC_Constants
    
    // MARK: - User Initiated Methods
    
    @objc func chooseSquare(_ sender: UITapGestureRecognizer? = nil) {
        if let square = sender?.view?.layer.value(forKey: constants.keyNameForSquare) as? Square {
            gameLogic.makeTurn(square: square)
            updateBoard()
        }
    }
    
    //when pawn reached last row
    @objc func replacePawn(_ sender: UITapGestureRecognizer? = nil) {
        if let square = sender?.view?.layer.value(forKey: constants.keyNameForSquare) as? Square, let figure = square.figure {
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
            turnBackward.isEnabled = gameLogic.rewindEnabled
            turns.isUserInteractionEnabled = gameLogic.rewindEnabled
        }
    }
    
    //shows/hides end of the game view
    @objc func transitEndOfTheGameView(_ sender: UIButton? = nil) {
        animateTransition(of: frameForEndOfTheGameView, startAlpha: frameForEndOfTheGameView.alpha)
        animateTransition(of: endOfTheGameScrollView, startAlpha: endOfTheGameScrollView.alpha)
        animateTransition(of: endOfTheGameView, startAlpha: endOfTheGameView.alpha)
    }
    
    //shows/hides player timers
    @objc func transitTimers(_ sender: UIButton? = nil) {
        animateTransition(of: player1Timer, startAlpha: player1Timer.alpha)
        animateTransition(of: player2Timer, startAlpha: player2Timer.alpha)
    }
    
    //shows/hides additional buttons
    @objc func transitAdditonalButtons(_ sender: UIButton? = nil) {
        animateAdditionalButtons()
        if let sender = sender {
            if sender.transform == currentTransformOfArrow {
                sender.transform = currentTransformOfArrow.rotated(by: .pi)
            }
            else {
                sender.transform = currentTransformOfArrow
            }
        }
    }
    
    //locks scrolling of game view
    @objc func lockGameView(_ sender: UIButton? = nil) {
        let heightForAdditionalButtons = min(view.frame.width, view.frame.height)  / constants.dividerForSquare
        let config = UIImage.SymbolConfiguration(pointSize: heightForAdditionalButtons, weight: .light, scale: .small)
        scrollViewOfGame.isScrollEnabled.toggle()
        if let sender = sender {
            if sender.currentBackgroundImage == UIImage(systemName: "lock.open", withConfiguration: config) {
                sender.setBackgroundImage(UIImage(systemName: "lock", withConfiguration: config), for: .normal)
            }
            else {
                sender.setBackgroundImage(UIImage(systemName: "lock.open", withConfiguration: config), for: .normal)
            }
        }
    }
    
    //TODO: - Draw for multiplayer
    
    //lets player surender
    @objc func surender(_ sender: UIButton? = nil) {
        let surenderAlert = UIAlertController(title: "Surender/Draw", message: "Do you want to surender or draw?", preferredStyle: .alert)
        surenderAlert.addAction(UIAlertAction(title: "Surender", style: .default, handler: { [weak self] _ in
            if let self = self {
                sender?.isEnabled = false
                self.gameLogic.surender()
                self.makeEndOfTheGameView()
            }
        }))
        surenderAlert.addAction(UIAlertAction(title: "Draw", style: .default, handler: { [weak self] _ in
            if let self = self {
                sender?.isEnabled = false
                if self.gameLogic.gameMode == .oneScreen {
                    self.gameLogic.forceDraw()
                    self.makeEndOfTheGameView()
                }
            }
        }))
        surenderAlert.addAction(UIAlertAction(title: "No", style: .cancel))
        present(surenderAlert, animated: true, completion: nil)
    }
    
    //
    
    //shows/hides turns view
    @objc func transitTurnsView(_ sender: UIButton? = nil) {
        animateTurnsView()
        //we bring back timers after closing turns view
        if player1Timer.alpha == 0 {
            animateTransition(of: player1Timer)
            animateTransition(of: player2Timer)
        }
    }
    
    //TODO: -
    
    //exits from game
    @objc func exit(_ sender: UIButton? = nil) {
        
    }
    
    //
    
    //moves game back
    @objc func turnsBackward(_ sender: UIButton? = nil) {
        turnsSingleAction(forward: false)
    }
    
    //moves game forward
    @objc func turnsForward(_ sender: UIButton? = nil) {
        turnsSingleAction(forward: true)
    }
    
    //stops/activates game playback
    @objc func turnsAction(_ sender: UIButton? = nil) {
        if turnsActionTimers.isEmpty {
            turns.isUserInteractionEnabled = false
            turnBackward.isEnabled = false
            turnForward.isEnabled = false
            sender?.setBackgroundImage(UIImage(systemName: "stop"), for: .normal)
            moveTurns(to: gameLogic.turns.last!)
        }
        else {
            turns.isUserInteractionEnabled = true
            turnBackward.isEnabled = !gameLogic.firstTurn
            turnForward.isEnabled = !gameLogic.lastTurn
            sender?.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
            stopTurnsPlayback()
        }
    }
    
    //moves game to chosen turn
    @objc func moveToTurn(_ sender: UITapGestureRecognizer? = nil) {
        turns.isUserInteractionEnabled = false
        turnAction.isEnabled = true
        turnAction.setBackgroundImage(UIImage(systemName: "stop"), for: .normal)
        stopTurnsPlayback()
        if let turn = sender?.view?.layer.value(forKey: constants.keyNameForTurn) as? Turn {
            moveTurns(to: turn)
        }
    }
    
    // MARK: - Local Methods
    
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
        scrollViewOfGame.scrollToViewAndCenterOnScreen(view: gameBoard, animated: true)
    }
    
    private func updateLayout() {
        player2FrameView.setNeedsDisplay()
        player1FrameView.setNeedsDisplay()
        player2TitleView.setNeedsDisplay()
        player1TitleView.setNeedsDisplay()
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
    
    private func activatePlayerTime() {
        if gameLogic.timerEnabled && !gameLogic.gameEnded && !gameLogic.pawnWizard {
            player1Timer.text = prodTimeString(gameLogic.players.first!.timeLeft)
            player2Timer.text = prodTimeString(gameLogic.players.second!.timeLeft)
            Timer.scheduledTimer(withTimeInterval: constants.animationDuration, repeats: false, block: {[weak self] _ in
                if let self = self {
                    self.gameLogic.activateTime(callback: {time in
                        if time == 0 && self.view.subviews.first(where: {$0 == self.endOfTheGameView}) == nil {
                            self.makeEndOfTheGameView()
                        }
                        if self.gameLogic.currentPlayer.type == .player1 {
                            self.player1Timer.text = self.prodTimeString(time)
                            if self.gameLogic.timeLeft < constants.dangerTimeleft {
                                let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {
                                    self.player1Timer.layer.backgroundColor = constants.dangerPlayerDataColor.withAlphaComponent(constants.optimalAlpha).cgColor
                                })
                                self.animations.append(animation)
                            }
                        }
                        else {
                            self.player2Timer.text = self.prodTimeString(time)
                            if self.gameLogic.timeLeft < constants.dangerTimeleft {
                                let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {
                                    self.player2Timer.layer.backgroundColor = constants.dangerPlayerDataColor.withAlphaComponent(constants.optimalAlpha).cgColor
                                })
                                self.animations.append(animation)
                            }
                        }
                    })
                }
            })
        }
    }
    
    private func turnsSingleAction(forward: Bool) {
        stopTurnsPlayback()
        moveTurn(forward: forward)
        turnBackward.isEnabled = !gameLogic.firstTurn
        turnForward.isEnabled = !gameLogic.lastTurn
        turnAction.isEnabled = !gameLogic.lastTurn
    }
    
    private func moveTurn(forward: Bool) {
        finishAnimations()
        forward == true ? forwardRewind.toggle() : backwardRewind.toggle()
        let turn = forward == true ? gameLogic.forward() : gameLogic.backward()
        if let turn = turn {
            if gameLogic.shortCastle || gameLogic.longCastle {
                animateTurn(turn)
                if let castleTurn = forward == true ? gameLogic.currentTurn : gameLogic.backward(){
                    animateTurn(castleTurn)
                }
                gameLogic.resetCastle()
            }
            else {
                animateTurn(turn)
            }
            player1Timer.text = prodTimeString(gameLogic.players.first!.timeLeft)
            player2Timer.text = prodTimeString(gameLogic.players.second!.timeLeft)
        }
        updateUI(animateSquares: true)
        forward == true ? forwardRewind.toggle() : backwardRewind.toggle()
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
    private func moveTurns(to turn: Turn) {
        finishAnimations()
        var delay = 0.0
        //before we start animating turns, we need to put gameBoard in center of the screen
        if !scrollViewOfGame.checkIfViewInCenterOfTheScreen(view: gameBoard) {
            scrollViewOfGame.scrollToViewAndCenterOnScreen(view: gameBoard, animated: true)
            delay = constants.animationDuration
        }
        let turnsInfo = gameLogic.turnsLeft(to: turn)
        let turnsLeft = turnsInfo.count
        let forward = turnsInfo.forward
        if turnsLeft > 0 {
            for i in 0..<turnsLeft {
                let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: {[weak self] _ in
                    if let self = self {
                        self.moveTurn(forward: forward)
                        if i == turnsLeft - 1{
                            self.turnAction.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
                            self.turnBackward.isEnabled = !self.gameLogic.firstTurn
                            self.turnForward.isEnabled = !self.gameLogic.lastTurn
                            self.turnAction.isEnabled = !self.gameLogic.lastTurn
                            self.turns.isUserInteractionEnabled = true
                            self.turnsActionTimers = []
                        }
                    }
                })
                RunLoop.main.add(timer, forMode: .common)
                turnsActionTimers.append(timer)
                delay += constants.animationDuration
            }
        }
    }
    
    //changes figure on square; used when transforming pawn
    private func updateSquare(_ square: Square, figure: Figure) {
        if let squareView = squares.first(where: {$0.layer.value(forKey: constants.keyNameForSquare) as? Square == square}) {
            var square = squareView.layer.value(forKey: constants.keyNameForSquare) as? Square
            square?.figure = figure
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
            let themeName = gameLogic.currentPlayer.figuresTheme.rawValue
            let figureImage = UIImage(named: "figuresThemes/\(themeName)/\(figure.color.rawValue)_\(figure.name.rawValue)")
            let figureView = getSquareView(image: figureImage).subviews.second!
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
    
    //updates game board
    private func updateBoard() {
        if gameLogic.pickedSquares.count > 1 {
            finishAnimations()
        }
        if gameLogic.shortCastle || gameLogic.longCastle {
            animateTurn(gameLogic.turns.beforeLast!)
            animateTurn(gameLogic.turns.last!)
            addTurnToUI(gameLogic.turns.last!)
            gameLogic.resetCastle()
            activatePlayerTime()
            updateUI()
        }
        else if gameLogic.pickedSquares.count > 1 {
            activatePlayerTime()
            if let turn = gameLogic.turns.last{
                if gameLogic.pawnWizard {
                    turnBackward.isEnabled = false
                    turns.isUserInteractionEnabled = false
                    if let figure = turn.squares.first!.figure {
                        showPawnPicker(square: turn.squares.second!, figureColor: figure.color)
                    }
                }
                else {
                    addTurnToUI(turn)
                }
                if !gameLogic.gameEnded {
                    turnBackward.isEnabled = gameLogic.rewindEnabled
                }
                animateTurn(turn)
                turnForward.isEnabled = false
                updateUI(animateSquares: true)
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
        if let firstFigure = firstFigure {
            firstFigureView = makeFigureView(with: firstFigure.color.rawValue, and: firstFigure.name.rawValue)
            //we are adding castle as one turn
            if gameLogic.shortCastle || gameLogic.longCastle {
                let kingView = makeFigureView(with: firstFigure.color.rawValue, and: Figures.king.rawValue)
                thisTurnData.addArrangedSubview(kingView)
            }
        }
        let secondFigure = turn.squares.second?.figure == nil ? turn.pawnSquare?.figure : turn.squares.second?.figure
        if let secondFigure = secondFigure {
            secondFigureView = makeFigureView(with: secondFigure.color.rawValue, and: secondFigure.name.rawValue)
        }
        if let figure = turn.pawnTransform {
            pawnTransformFigureView = makeFigureView(with: figure.color.rawValue, and: figure.name.rawValue)
        }
        let turnLabel = makeTurnLabel(from: turn)
        if let firstFigureView = firstFigureView {
            thisTurnData.addArrangedSubview(firstFigureView)
        }
        thisTurnData.layer.setValue(turn, forKey: constants.keyNameForTurn)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.moveToTurn(_:)))
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
            let newTurnData = UIStackView()
            newTurnData.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
            turnData = newTurnData
        }
    }
    
    private func makeTurnLabel(from turn: Turn) -> UILabel {
        var firstSqureText = turn.squares.first!.column.rawValue + String(turn.squares.first!.row)
        var secondSqureText = turn.squares.second!.column.rawValue + String(turn.squares.second!.row)
        if gameLogic.shortCastle || gameLogic.longCastle {
            if gameLogic.shortCastle {
                firstSqureText = constants.shortCastleNotation
            }
            else {
                firstSqureText = constants.longCastleNotation
            }
            secondSqureText = ""
        }
        if gameLogic.gameEnded {
            secondSqureText += constants.checkmateNotation
        }
        else if gameLogic.check {
            secondSqureText += constants.checkNotation
        }
        if turn.squares.second?.figure != nil || turn.pawnSquare != nil {
            firstSqureText += constants.figureEatenNotation
        }
        let turnText = firstSqureText.lowercased() + secondSqureText.lowercased()
        let turnLabel = makeLabel(text: turnText)
        return turnLabel
    }
    
    private func makeFigureView(with figureColor: String, and figureName: String) -> UIImageView {
        let figuresThemeName = gameLogic.players.first!.figuresTheme.rawValue
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
                    let newTurnData = UIStackView()
                    newTurnData.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
                    turnData = newTurnData
                }
            }
        }
    }
    
    //highlights current turn
    private func updateCurrentTurn() {
        for turnsStack in turns.arrangedSubviews {
            if let turnsStack = turnsStack as? UIStackView {
                for turn in turnsStack.arrangedSubviews {
                    if let turnData = turn.layer.value(forKey: constants.keyNameForTurn) as? Turn {
                        if turnData == gameLogic.currentTurn {
                            let newColor = constants.convertLogicColor(gameLogic.players.first!.squaresTheme.turnColor).withAlphaComponent(constants.optimalAlpha)
                            let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {
                                turn.backgroundColor = newColor
                            })
                            animations.append(animation)
                            //scrolls turns to current turn
                            if let index = turns.arrangedSubviews.firstIndex(of: turnsStack) {
                                turnsView.layoutIfNeeded()
                                let condition1 = backwardRewind ? turnsScrollView.contentSize.height / CGFloat(turns.arrangedSubviews.count) : 0.0
                                //index + 1 cuz we start from 0
                                let condition2 = turnsScrollView.contentSize.height / CGFloat(turns.arrangedSubviews.count) * CGFloat(index + 1) + turnsButtons.bounds.size.height
                                if condition2 > turnsView.bounds.size.height - condition1 {
                                    let bottomOffset = CGPoint(x: 0, y: condition2 - turnsView.bounds.size.height)
                                    turnsScrollView.setContentOffset(bottomOffset, animated: true)
                                }
                            }
                        }
                        else {
                            let newColor = constants.defaultPlayerDataColor.withAlphaComponent(constants.optimalAlpha)
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
    
    private func updateCurrentPlayer() {
        switch gameLogic.currentPlayer.type {
        case .player1:
            let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {[weak self] in
                if let self = self {
                    self.player1FrameView.updateDataBackgroundColor(constants.currentPlayerDataColor)
                    self.player2FrameView.updateDataBackgroundColor(constants.defaultPlayerDataColor)
                    if self.gameLogic.players.first!.timeLeft > constants.dangerTimeleft {
                        self.player1Timer.layer.backgroundColor = constants.currentPlayerDataColor.withAlphaComponent(constants.optimalAlpha).cgColor
                    }
                    else {
                        self.player1Timer.layer.backgroundColor = constants.dangerPlayerDataColor.withAlphaComponent(constants.optimalAlpha).cgColor
                    }
                    self.player2Timer.layer.backgroundColor = constants.defaultPlayerDataColor.withAlphaComponent(constants.optimalAlpha).cgColor
                }
            })
            animations.append(animation)
        case .player2:
            let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {[weak self] in
                if let self = self {
                    self.player1FrameView.updateDataBackgroundColor(constants.defaultPlayerDataColor)
                    self.player2FrameView.updateDataBackgroundColor(constants.currentPlayerDataColor)
                    if self.gameLogic.players.second!.timeLeft > constants.dangerTimeleft {
                        self.player2Timer.layer.backgroundColor = constants.currentPlayerDataColor.withAlphaComponent(constants.optimalAlpha).cgColor
                    }
                    else {
                        self.player2Timer.layer.backgroundColor = constants.dangerPlayerDataColor.withAlphaComponent(constants.optimalAlpha).cgColor
                    }
                    self.player1Timer.layer.backgroundColor = constants.defaultPlayerDataColor.withAlphaComponent(constants.optimalAlpha).cgColor
                }
            })
            animations.append(animation)
        }
    }
    
    private func showPawnPicker(square: Square, figureColor: GameColors) {
        makePawnPicker(figureColor: figureColor, squareColor: square.color)
        scrollContentOfGame.addSubview(pawnPicker)
        pawnPicker.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.secondColor)
        if square.color == .white {
            pawnPicker.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.firstColor)
        }
        var pawnPickerConstraints: [NSLayoutConstraint] = []
        if gameLogic.currentPlayer.type == .player1 {
            if gameLogic.gameMode == .oneScreen {
                pawnPicker.transform = .identity
            }
            if let lettersLine = gameBoard.arrangedSubviews.last {
                pawnPickerConstraints = [pawnPicker.centerXAnchor.constraint(equalTo: lettersLine.centerXAnchor), pawnPicker.centerYAnchor.constraint(equalTo: lettersLine.centerYAnchor)]
            }
        }
        else {
            if gameLogic.gameMode == .oneScreen {
                pawnPicker.transform = pawnPicker.transform.rotated(by: .pi)
            }
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
                    newColor = constants.convertLogicColor(gameLogic.squaresTheme.turnColor)
                }
                else {
                    switch square.color {
                    case .white:
                        newColor = constants.convertLogicColor(gameLogic.squaresTheme.firstColor)
                    case .black:
                        newColor = constants.convertLogicColor(gameLogic.squaresTheme.secondColor)
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
                        newColor = constants.convertLogicColor(gameLogic.squaresTheme.pickColor)
                    }
                    else if gameLogic.availableSquares.contains(square) {
                        newColor = constants.convertLogicColor(gameLogic.squaresTheme.availableSquaresColor)
                        view.isUserInteractionEnabled = true
                    }
                }
                if gameLogic.check {
                    if square == gameLogic.getCheckSquare() {
                        newColor = constants.convertLogicColor(gameLogic.squaresTheme.checkColor)
                    }
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
        //bacwardRewind will change after animation will finish, so we need to capture it
        let backwardRewind = self.backwardRewind
        if backwardRewind {
            if pawnTransform != nil, let figure = secondSquare.figure {
                updateSquare(firstSquare, figure: figure)
            }
        }
        var frameForBackward: (x: CGFloat, y: CGFloat) = (0, 0)
        var backwardFigureView: UIImageView?
        bringFigureToFront(figureView: firstSquareView)
        if let backwardSquareView = backwardSquareView {
            backwardFigureView = getBackwardFigureView()
            if let backwardFigureView = backwardFigureView {
                bringFigureToFrontFromTrash(figureView: backwardFigureView)
                frameForBackward = coordinatesToMoveFigureFrom(firstView: backwardFigureView, to: backwardSquareView)
                if gameLogic.gameMode == .oneScreen {
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
            newSquare.figure = nil
            thirdSquareView?.layer.setValue(newSquare, forKey: constants.keyNameForSquare)
        }
        updateSquares()
        //turn animation
        let animation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {
            backwardFigureView?.transform = CGAffineTransform(translationX: frameForBackward.x, y: frameForBackward.y)
            if let subview = firstSquareView.subviews.second {
                subview.transform = CGAffineTransform(translationX: frame.minX - firstSquareView.bounds.minX, y: frame.minY - firstSquareView.bounds.minY)
            }
        }) { [weak self] _ in
            if let self = self {
                //stops trashAnimation before starting new one
                self.trashAnimation?.stopAnimation(false)
                self.trashAnimation?.finishAnimation(at: .end)
                if let backwardSquareView = backwardSquareView, let backwardFigureView = backwardFigureView {
                    let destroyedFiguresView = backwardFigureView.superview?.superview
                    backwardFigureView.transform = .identity
                    backwardSquareView.addSubview(backwardFigureView)
                    destroyedFiguresView?.layoutIfNeeded()
                }
                if secondSquareView.subviews.count > 1 {
                    self.moveFigureToTrash(squareView: secondSquareView, currentPlayer: currentPlayer)
                }
                var figure = firstSquareView.subviews.last!
                if backwardSquareView != nil {
                    figure = firstSquareView.subviews.second!
                }
                figure.transform = .identity
                secondSquareView.addSubview(figure)
                let imageViewConstraints = [figure.centerXAnchor.constraint(equalTo: secondSquareView.centerXAnchor), figure.centerYAnchor.constraint(equalTo: secondSquareView.centerYAnchor)]
                NSLayoutConstraint.activate(imageViewConstraints)
                if let thirdSquareView = thirdSquareView {
                    if thirdSquareView.subviews.count > 0 {
                        self.moveFigureToTrash(squareView: thirdSquareView, currentPlayer: currentPlayer)
                    }
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
    
    //we need to move figure image to the top
    private func bringFigureToFront(figureView: UIView) {
        let verticalStackView = figureView.superview?.superview
        let horizontalStackView = figureView.superview
        if let verticalStackView = verticalStackView, let horizontalStackView = horizontalStackView {
            scrollContentOfGame.bringSubviewToFront(verticalStackView)
            verticalStackView.bringSubviewToFront(horizontalStackView)
            horizontalStackView.bringSubviewToFront(figureView)
        }
        figureView.bringSubviewToFront(figureView.subviews.second!)
        viewsOnTop()
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
    
    private func moveFigureToTrash(squareView: UIImageView, currentPlayer: Player) {
        if let subview = squareView.subviews.last {
            bringFigureToFront(figureView: squareView)
            if gameLogic.gameMode == .oneScreen {
                if let subview = subview as? UIImageView {
                    subview.image = subview.image?.rotate(radians: .pi)
                }
            }
            var coordinates: (xCoordinate: CGFloat, yCoordinate: CGFloat) = (0, 0)
            switch currentPlayer.type {
            case .player1:
                coordinates = coordinatesForTrashAnimation(player: .player1, squareView: squareView, destroyedFiguresStack1: player1DestroyedFigures1, destroyedFiguresStack2: player1DestroyedFigures2)
            case .player2:
                coordinates = coordinatesForTrashAnimation(player: .player2, squareView: squareView, destroyedFiguresStack1: player2DestroyedFigures1, destroyedFiguresStack2: player2DestroyedFigures2)
            }
            animateFigureToTrash(figure: subview, x: coordinates.xCoordinate, y: coordinates.yCoordinate, currentPlayer: currentPlayer)
        }
    }
    
    private func coordinatesForTrashAnimation(player: GamePlayers, squareView: UIImageView, destroyedFiguresStack1: UIStackView, destroyedFiguresStack2: UIStackView) -> (xCoordinate: CGFloat, yCoordinate: CGFloat) {
        var frame = CGRect.zero
        var xCoordinate: CGFloat = 0
        var yCoordinate: CGFloat = 0
        //we have 2 lines of trash figures
        if destroyedFiguresStack1.subviews.count == constants.maxFiguresInTrashLine {
            frame = getFrameForAnimation(firstView: squareView, secondView: destroyedFiguresStack2)
        }
        else {
            frame = getFrameForAnimation(firstView: squareView, secondView: destroyedFiguresStack1)
        }
        if gameLogic.gameMode == .oneScreen && player == .player1 {
            xCoordinate = frame.minX - squareView.bounds.maxX
            yCoordinate = frame.maxY - squareView.bounds.maxY
            //at the start StackView have height 0
            if destroyedFiguresStack1.subviews.count == constants.maxFiguresInTrashLine && destroyedFiguresStack2.subviews.isEmpty {
                yCoordinate = frame.maxY - squareView.bounds.minY
            }
        }
        else if gameLogic.gameMode == .multiplayer || player == .player2{
            xCoordinate = frame.maxX - squareView.bounds.minX
            yCoordinate = frame.minY - squareView.bounds.minY
            if destroyedFiguresStack1.subviews.count == constants.maxFiguresInTrashLine && destroyedFiguresStack2.subviews.isEmpty {
                yCoordinate = frame.minY - squareView.bounds.maxY
            }
        }
        return (xCoordinate, yCoordinate)
    }
    
    private func animateFigureToTrash(figure: UIView, x: CGFloat, y: CGFloat, currentPlayer: Player) {
        trashAnimation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: constants.animationDuration, delay: 0, animations: {
            figure.transform = CGAffineTransform(translationX: x, y: y)
        }) {[weak self] _ in
            if let self = self {
                figure.transform = .identity
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
    private let showEndOfTheGameView = UIButton()
    //just a pointer to additional buttons
    private let arrowToAdditionalButtons = UIImageView()
    private let turnsScrollView = UIScrollView()
    private let turns = UIStackView()
    private let turnBackward = UIButton()
    private let turnForward = UIButton()
    private let turnAction = UIButton()
    private let turnsButtons = UIStackView()
    private let turnsView = UIView()
    private let additionalButton = UIButton()
    //df - destroyed figures
    private let player2FrameForDF = UIImageView()
    private let player1FrameForDF = UIImageView()
    private let playerProgress = ProgressBar()
    private let surenderButton = UIButton()
    
    //contains currentTurn of both players
    private var turnData = UIStackView()
    private var player1Timer = UILabel()
    private var player2Timer = UILabel()
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
        let figuresThemeName = gameLogic.players.first!.figuresTheme.rawValue
        let figureColor = traitCollection.userInterfaceStyle == .dark ? GameColors.black.rawValue : GameColors.white.rawValue
        let figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(figureColor)_pawn")
        arrowToAdditionalButtons.image = figureImage
        scrollContentOfGame.addSubview(arrowToAdditionalButtons)
        additionalButton.buttonWith(image: UIImage(systemName: "arrowtriangle.down.fill"), and: #selector(transitAdditonalButtons))
    }
    
    private func makeAdditionalButtons() {
        let heightForAdditionalButtons = min(view.frame.width, view.frame.height)  / constants.dividerForSquare
        let configForAdditionalButtons = UIImage.SymbolConfiguration(pointSize: heightForAdditionalButtons, weight: constants.weightForAddionalButtons, scale: constants.scaleForAddionalButtons)
        surenderButton.buttonWith(image: UIImage(systemName: "flag.fill", withConfiguration: configForAdditionalButtons), and: #selector(surender))
        let lockScrolling = UIButton()
        lockScrolling.buttonWith(image: UIImage(systemName: "lock.open", withConfiguration: configForAdditionalButtons), and: #selector(lockGameView))
        let turnsViewButton = UIButton()
        turnsViewButton.buttonWith(image: UIImage(systemName: "backward", withConfiguration: configForAdditionalButtons), and: #selector(transitTurnsView))
        let exitsButton = UIButton()
        exitsButton.buttonWith(image: UIImage(systemName: "rectangle.portrait.and.arrow.right", withConfiguration: configForAdditionalButtons), and: #selector(exit))
        showEndOfTheGameView.buttonWith(image: UIImage(systemName: "doc.text.magnifyingglass", withConfiguration: configForAdditionalButtons), and: #selector(transitEndOfTheGameView))
        additionalButtons.addArrangedSubview(showEndOfTheGameView)
        additionalButtons.addArrangedSubview(lockScrolling)
        additionalButtons.addArrangedSubview(surenderButton)
        additionalButtons.addArrangedSubview(turnsViewButton)
        additionalButtons.addArrangedSubview(exitsButton)
        scrollContentOfGame.addSubview(additionalButtons)
    }
    
    private func makeUI() {
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
        if gameLogic.timerEnabled {
            makeTimers()
        }
        makeTurnsView()
        viewsOnTop()
        makeSpecialConstraints()
        makePortraitConstraints()
        makeLandscapeConstraints()
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
        let player1TimerConstaints = [player1Timer.bottomAnchor.constraint(equalTo: gameBoard.bottomAnchor), player1Timer.trailingAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.leadingAnchor), player1Timer.leadingAnchor.constraint(greaterThanOrEqualTo: scrollContentOfGame.layoutMarginsGuide.leadingAnchor)]
        let player2TimerConstaints = [player2Timer.topAnchor.constraint(equalTo: gameBoard.topAnchor), player2Timer.leadingAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.trailingAnchor), player2Timer.trailingAnchor.constraint(lessThanOrEqualTo: scrollContentOfGame.layoutMarginsGuide.trailingAnchor)]
        let additionalButtonsConstraints = [additionalButtons.bottomAnchor.constraint(equalTo: gameBoard.bottomAnchor), additionalButtons.leadingAnchor.constraint(equalTo: arrowToAdditionalButtons.trailingAnchor), additionalButtons.heightAnchor.constraint(equalToConstant: heightForAdditionalButtons), showEndOfTheGameView.widthAnchor.constraint(equalTo: showEndOfTheGameView.heightAnchor)]
        if let stackWhereToAdd = gameBoard.arrangedSubviews.last {
            if let stackWhereToAdd = stackWhereToAdd as? UIStackView {
                if let viewWhereToAdd = stackWhereToAdd.arrangedSubviews.first {
                    viewWhereToAdd.addSubview(additionalButton)
                    let additionalButtonConstraints = [additionalButton.widthAnchor.constraint(equalTo: viewWhereToAdd.widthAnchor, multiplier: constants.multiplierForNumberView), additionalButton.heightAnchor.constraint(equalTo: viewWhereToAdd.heightAnchor, multiplier: constants.multiplierForNumberView), additionalButton.centerXAnchor.constraint(equalTo: viewWhereToAdd.centerXAnchor), additionalButton.centerYAnchor.constraint(equalTo: viewWhereToAdd.centerYAnchor), arrowToAdditionalButtons.leadingAnchor.constraint(equalTo: viewWhereToAdd.trailingAnchor), arrowToAdditionalButtons.centerYAnchor.constraint(equalTo: viewWhereToAdd.centerYAnchor), arrowToAdditionalButtons.widthAnchor.constraint(equalTo: viewWhereToAdd.widthAnchor), arrowToAdditionalButtons.heightAnchor.constraint(equalTo: viewWhereToAdd.heightAnchor)]
                    specialConstraints += additionalButtonConstraints
                }
            }
        }
        specialConstraints += player1TimerConstaints + player2TimerConstaints + additionalButtonsConstraints
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
            }
        }
        let additionalButtonsConstraints = [additionalButtons.topAnchor.constraint(equalTo: arrowToAdditionalButtons.bottomAnchor), additionalButtons.leadingAnchor.constraint(equalTo: gameBoard.leadingAnchor), additionalButtons.heightAnchor.constraint(equalToConstant: heightForAdditionalButtons), showEndOfTheGameView.widthAnchor.constraint(equalTo: showEndOfTheGameView.heightAnchor)]
        let player2FrameViewConstraints = [player2FrameView.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player2FrameView.topAnchor.constraint(equalTo: player2TitleView.bottomAnchor, constant: constants.distanceForTitle), player2FrameView.widthAnchor.constraint(equalToConstant: widthForFrame), player2FrameView.heightAnchor.constraint(equalToConstant: heightForFrame)]
        let player1FrameViewConstraints = [player1FrameView.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player1FrameView.topAnchor.constraint(equalTo: destroyedFigures2.bottomAnchor, constant: constants.optimalDistance), player1FrameView.widthAnchor.constraint(equalToConstant: widthForFrame), player1FrameView.heightAnchor.constraint(equalToConstant: heightForFrame)]
        let player2TitleViewConstraints = [player2TitleView.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player2TitleView.widthAnchor.constraint(equalToConstant: widthForFrame), player2TitleView.heightAnchor.constraint(equalToConstant: heightForFrame), player2TitleView.topAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.topAnchor)]
        let player1TitleViewConstraints = [player1TitleView.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player1TitleView.widthAnchor.constraint(equalToConstant: widthForFrame), player1TitleView.heightAnchor.constraint(equalToConstant: heightForFrame), player1TitleView.topAnchor.constraint(equalTo: player1FrameView.bottomAnchor, constant: constants.distanceForTitle), player1TitleView.bottomAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.bottomAnchor)]
        let player2FrameConstraintsDF = [player2FrameForDF.topAnchor.constraint(equalTo: player2FrameView.bottomAnchor, constant: constants.distanceForFrame), player2FrameForDF.widthAnchor.constraint(equalTo: destroyedFigures1.widthAnchor, constant: constants.optimalDistance), player2FrameForDF.heightAnchor.constraint(equalTo: destroyedFigures1.heightAnchor, constant: constants.optimalDistance), player2FrameForDF.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        let destroyedFigures1Constraints = [destroyedFigures1.topAnchor.constraint(equalTo: player2FrameView.bottomAnchor, constant: constants.optimalDistance), destroyedFigures1.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        let player1FrameConstraintsDF = [player1FrameForDF.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.distanceForFrame), player1FrameForDF.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player1FrameForDF.widthAnchor.constraint(equalTo: destroyedFigures1.widthAnchor, constant: constants.optimalDistance), player1FrameForDF.heightAnchor.constraint(equalTo: destroyedFigures1.heightAnchor, constant: constants.optimalDistance)]
        let destroyedFigures2Constraints = [destroyedFigures2.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.optimalDistance), destroyedFigures2.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        let player1TimerConstraints = [player1Timer.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.optimalDistance), player1Timer.trailingAnchor.constraint(equalTo: gameBoard.trailingAnchor)]
        let player2TimerConstraints = [player2Timer.bottomAnchor.constraint(equalTo: gameBoard.topAnchor, constant: -constants.optimalDistance), player2Timer.trailingAnchor.constraint(equalTo: gameBoard.trailingAnchor)]
        portraitConstraints += additionalButtonsConstraints + player2FrameViewConstraints + player1FrameViewConstraints + player2TitleViewConstraints + player1TitleViewConstraints + player2FrameConstraintsDF + destroyedFigures1Constraints + player1FrameConstraintsDF + destroyedFigures2Constraints + player1TimerConstraints + player2TimerConstraints
        timerConstraints += player1TimerConstraints + player2TimerConstraints
        additionalButtonConstraints += additionalButtonsConstraints
    }
    
    private func makeLandscapeConstraints() {
        let heightForFrame = min(view.frame.width, view.frame.height)  / constants.heightDividerForFrame
        let player2FrameViewConstraints = [player2FrameView.centerYAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.centerYAnchor), player2FrameView.leadingAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.trailingAnchor, constant: constants.optimalDistance), player2FrameView.trailingAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.trailingAnchor, constant: -constants.optimalDistance), player2FrameView.heightAnchor.constraint(equalToConstant: heightForFrame)]
        let player1FrameViewConstraints = [player1FrameView.centerYAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.centerYAnchor), player1FrameView.trailingAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.leadingAnchor, constant: -constants.optimalDistance), player1FrameView.leadingAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.leadingAnchor, constant: constants.optimalDistance), player1FrameView.heightAnchor.constraint(equalToConstant: heightForFrame)]
        let player2TitleViewConstraints = [player2TitleView.topAnchor.constraint(equalTo: player2FrameView.layoutMarginsGuide.bottomAnchor, constant: constants.optimalDistance), player2TitleView.leadingAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.trailingAnchor, constant: constants.optimalDistance), player2TitleView.trailingAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.trailingAnchor, constant: -constants.optimalDistance), player2TitleView.heightAnchor.constraint(equalToConstant: heightForFrame)]
        let player1TitleViewConstraints = [player1TitleView.topAnchor.constraint(equalTo: player1FrameView.layoutMarginsGuide.bottomAnchor, constant: constants.optimalDistance), player1TitleView.trailingAnchor.constraint(equalTo: gameBoard.layoutMarginsGuide.leadingAnchor, constant: -constants.optimalDistance), player1TitleView.leadingAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.leadingAnchor, constant: constants.optimalDistance), player1TitleView.heightAnchor.constraint(equalToConstant: heightForFrame)]
        let player2FrameConstraintsDF = [player2FrameForDF.topAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.topAnchor, constant: constants.distanceForFrame), player2FrameForDF.widthAnchor.constraint(equalTo: destroyedFigures1.widthAnchor, constant: constants.optimalDistance), player2FrameForDF.heightAnchor.constraint(equalTo: destroyedFigures1.heightAnchor, constant: constants.optimalDistance), player2FrameForDF.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        let destroyedFigures1Constraints = [destroyedFigures1.topAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.topAnchor, constant: constants.optimalDistance), destroyedFigures1.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        let player1FrameConstraintsDF = [player1FrameForDF.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.distanceForFrame), player1FrameForDF.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player1FrameForDF.widthAnchor.constraint(equalTo: destroyedFigures1.widthAnchor, constant: constants.optimalDistance), player1FrameForDF.heightAnchor.constraint(equalTo: destroyedFigures1.heightAnchor, constant: constants.optimalDistance), player1FrameForDF.bottomAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.bottomAnchor)]
        let destroyedFigures2Constraints = [destroyedFigures2.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.optimalDistance), destroyedFigures2.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), destroyedFigures2.bottomAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.bottomAnchor, constant: -constants.distanceForFrame)]
        landscapeConstraints += player2FrameViewConstraints + player1FrameViewConstraints + player2TitleViewConstraints + player1TitleViewConstraints + player2FrameConstraintsDF + destroyedFigures1Constraints + player1FrameConstraintsDF + destroyedFigures2Constraints + specialConstraints
    }
    
    //moves some views to top
    private func viewsOnTop() {
        scrollContentOfGame.bringSubviewToFront(turnsView)
        scrollContentOfGame.bringSubviewToFront(player1Timer)
        scrollContentOfGame.bringSubviewToFront(player2Timer)
        scrollContentOfGame.bringSubviewToFront(arrowToAdditionalButtons)
        scrollContentOfGame.bringSubviewToFront(additionalButtons)
        scrollContentOfGame.bringSubviewToFront(pawnPicker)
    }
    
    private func setupViews() {
        turnsView.translatesAutoresizingMaskIntoConstraints = false
        scrollViewOfGame.translatesAutoresizingMaskIntoConstraints = false
        scrollContentOfGame.translatesAutoresizingMaskIntoConstraints = false
        endOfTheGameScrollView.translatesAutoresizingMaskIntoConstraints = false
        turnsScrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollViewOfGame.delaysContentTouches = false
        endOfTheGameScrollView.delaysContentTouches = false
        turnsScrollView.delaysContentTouches = false
        turnsView.alpha = 0
        additionalButtons.alpha = 0
        arrowToAdditionalButtons.alpha = 0
        showEndOfTheGameView.isEnabled = false
        turnBackward.isEnabled = false
        turnForward.isEnabled = false
        turnAction.isEnabled = false
        turns.isUserInteractionEnabled = gameLogic.rewindEnabled
        pawnPicker.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        gameBoard.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player1DestroyedFigures1.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player1DestroyedFigures2.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player2DestroyedFigures1.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player2DestroyedFigures2.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        additionalButtons.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        turns.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        turnData.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        turnsButtons.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        endOfTheGameView.defaultSettings()
        additionalButtons.defaultSettings()
        turnsButtons.defaultSettings()
        frameForEndOfTheGameView.defaultSettings()
        arrowToAdditionalButtons.defaultSettings()
        player2FrameForDF.defaultSettings()
        player1FrameForDF.defaultSettings()
        player1Timer = makeLabel(text: prodTimeString(gameLogic.players.first!.timeLeft))
        player2Timer = makeLabel(text: prodTimeString(gameLogic.players.second!.timeLeft))
        turnsButtons.backgroundColor = turnsButtons.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        arrowToAdditionalButtons.backgroundColor = constants.backgroundForArrow
        turnsScrollView.backgroundColor = .clear
        arrowToAdditionalButtons.contentMode = .scaleAspectFit
        arrowToAdditionalButtons.layer.borderWidth = 0
        player1Timer.layer.cornerRadius = constants.cornerRadiusForChessTime
        player2Timer.layer.cornerRadius = constants.cornerRadiusForChessTime
        player1Timer.layer.masksToBounds = true
        player2Timer.layer.masksToBounds = true
        player1Timer.font = UIFont.monospacedDigitSystemFont(ofSize: player1Timer.font.pointSize, weight: constants.weightForChessTime)
        player2Timer.font = UIFont.monospacedDigitSystemFont(ofSize: player2Timer.font.pointSize, weight: constants.weightForChessTime)
    }
    
    private func makeScrollViewOfGame() {
        view.addSubview(scrollViewOfGame)
        scrollViewOfGame.addSubview(scrollContentOfGame)
        let contentHeight = scrollContentOfGame.heightAnchor.constraint(equalTo: scrollViewOfGame.heightAnchor)
        contentHeight.priority = .defaultLow;
        let scrollViewConstraints = [scrollViewOfGame.leadingAnchor.constraint(equalTo: view.leadingAnchor), scrollViewOfGame.trailingAnchor.constraint(equalTo: view.trailingAnchor), scrollViewOfGame.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor), scrollViewOfGame.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)]
        let contentConstraints = [scrollContentOfGame.topAnchor.constraint(equalTo: scrollViewOfGame.topAnchor), scrollContentOfGame.bottomAnchor.constraint(equalTo: scrollViewOfGame.bottomAnchor), scrollContentOfGame.leadingAnchor.constraint(equalTo: scrollViewOfGame.leadingAnchor), scrollContentOfGame.trailingAnchor.constraint(equalTo: scrollViewOfGame.trailingAnchor), scrollContentOfGame.widthAnchor.constraint(equalTo: scrollViewOfGame.widthAnchor), contentHeight]
        NSLayoutConstraint.activate(scrollViewConstraints + contentConstraints)
    }
    
    private func makePlayer2Frame() {
        let player2Background = gameLogic.players.second!.playerBackground
        let player2Frame = gameLogic.players.second!.frame
        let player2Data = makeLabel(text: gameLogic.players.second!.name + " " + String(gameLogic.players.second!.points))
        player2FrameView = PlayerFrame(background: player2Background, playerFrame: player2Frame, data: player2Data)
        scrollContentOfGame.addSubview(player2FrameView)
        if gameLogic.gameMode == .oneScreen {
            player2FrameView.transform = player2FrameView.transform.rotated(by: .pi)
        }
        scrollContentOfGame.bringSubviewToFront(player2TitleView)
    }
    
    private func makePlayer1Frame() {
        let player1Background = gameLogic.players.first!.playerBackground
        let player1Frame = gameLogic.players.first!.frame
        let player1Data = makeLabel(text: gameLogic.players.first!.name + " " + String(gameLogic.players.first!.points))
        player1FrameView = PlayerFrame(background: player1Background, playerFrame: player1Frame, data: player1Data)
        scrollContentOfGame.addSubview(player1FrameView)
    }
    
    private func makePlayer2Title() {
        let player2Background = gameLogic.players.second!.playerBackground
        let player2Frame = gameLogic.players.second!.frame
        let player2Title = makeLabel(text: gameLogic.players.second!.title.rawValue.capitalizingFirstLetter().replacingOccurrences(of: "_", with: " "))
        player2TitleView = PlayerFrame(background: player2Background, playerFrame: player2Frame, data: player2Title)
        scrollContentOfGame.addSubview(player2TitleView)
        if gameLogic.gameMode == .oneScreen {
            player2TitleView.transform = player2TitleView.transform.rotated(by: .pi)
        }
    }
    
    private func makePlayer1Title() {
        let player1Background = gameLogic.players.first!.playerBackground
        let player1Frame = gameLogic.players.first!.frame
        let player1Title = makeLabel(text: gameLogic.players.first!.title.rawValue.capitalizingFirstLetter().replacingOccurrences(of: "_", with: " "))
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
        player2FrameForDF.image = UIImage(named: "frames/\(gameLogic.players.second!.frame.rawValue)")
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
        player1FrameForDF.image = UIImage(named: "frames/\(gameLogic.players.first!.frame.rawValue)")
        scrollContentOfGame.addSubview(player1FrameForDF)
        destroyedFigures2 = makeDestroyedFiguresView(destroyedFigures1: player2DestroyedFigures1, destroyedFigures2: player2DestroyedFigures2)
        scrollContentOfGame.addSubview(destroyedFigures2)
    }
    
    private func addPlayersBackgrounds() {
        let bottomPlayerBackground = UIImageView()
        bottomPlayerBackground.defaultSettings()
        bottomPlayerBackground.image = UIImage(named: "backgrounds/\(gameLogic.players.second!.background.rawValue)")
        if gameLogic.gameMode == .multiplayer {
            let topPlayerBackground = UIImageView()
            topPlayerBackground.defaultSettings()
            topPlayerBackground.image = UIImage(named: "backgrounds/\(gameLogic.players.first!.background.rawValue)")
            view.addSubview(topPlayerBackground)
            view.addSubview(bottomPlayerBackground)
            let topConstraints = [topPlayerBackground.topAnchor.constraint(equalTo: view.topAnchor), topPlayerBackground.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: constants.multiplierForBackground), topPlayerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor), topPlayerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
            let bottomConstraints = [bottomPlayerBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor), bottomPlayerBackground.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: constants.multiplierForBackground), bottomPlayerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor), bottomPlayerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
            NSLayoutConstraint.activate(topConstraints + bottomConstraints)
        }
        else {
            view.addSubview(bottomPlayerBackground)
            let bottomConstraints = [bottomPlayerBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor), bottomPlayerBackground.topAnchor.constraint(equalTo: view.topAnchor), bottomPlayerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor), bottomPlayerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
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
                            let figuresThemeName = gameLogic.players.second!.figuresTheme.rawValue
                            figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(figure.color.rawValue)_\(figure.name.rawValue)")
                        }
                        else {
                            let figuresThemeName = gameLogic.players.first!.figuresTheme.rawValue
                            figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(figure.color.rawValue)_\(figure.name.rawValue)")
                        }
                        if gameLogic.gameMode == .oneScreen && square.figure?.color == colorToRotate {
                            //we are not using transform here to not have problems with animation
                            figureImage = figureImage?.rotate(radians: .pi)
                        }
                    }
                    let squareView = getSquareView(image: figureImage)
                    switch square.color {
                    case .white:
                        squareView.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.firstColor)
                    case .black:
                        squareView.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.secondColor)
                    }
                    squareView.layer.setValue(square, forKey: constants.keyNameForSquare)
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.chooseSquare(_:)))
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
    
    private func getSquareView(image: UIImage? = nil, multiplier: CGFloat = 1) -> UIImageView {
        let square = UIImageView()
        let width = min(view.frame.width, view.frame.height)  / constants.dividerForSquare * multiplier
        square.rectangleView(width: width)
        square.layer.borderWidth = 0
        //when we animating, border is always on top, so we have to add it as subview instead
        let border = UIImageView()
        border.rectangleView(width: width)
        square.addSubview(border)
        //we are adding image in this way, so we can move figure separately from square
        if image != nil {
            let imageView = UIImageView()
            imageView.rectangleView(width: width)
            imageView.layer.borderWidth = 0
            imageView.image = image
            square.addSubview(imageView)
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
    
    private func makePawnPicker(figureColor: GameColors, squareColor: GameColors) {
        let figures: [Figures] = [.rook, .queen, .bishop, .knight]
        for figure in figures {
            //just random square, it doesnt matter
            let square = Square(column: .A, row: 1, color: .white, figure: Figure(name: figure, color: figureColor, startColumn: .A, startRow: 1))
            let figuresThemeName = gameLogic.currentPlayer.figuresTheme.rawValue
            let figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(figureColor.rawValue)_\(figure.rawValue)")
            let squareView = getSquareView(image: figureImage)
            squareView.layer.setValue(square, forKey: constants.keyNameForSquare)
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.replacePawn(_:)))
            squareView.addGestureRecognizer(tap)
            squareView.subviews.first!.layer.borderColor = squareColor == .black ? UIColor.white.cgColor : UIColor.black.cgColor
            pawnPicker.addArrangedSubview(squareView)
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
        destroyedFigures.addSubview(destroyedFiguresBackground)
        destroyedFigures.addSubview(destroyedFigures1)
        destroyedFigures.addSubview(destroyedFigures2)
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
        var image = UIImage(named: "backgrounds/\(gameLogic.players.first!.playerBackground.rawValue)")
        if player2 {
            image = UIImage(named: "backgrounds/\(gameLogic.players.second!.playerBackground.rawValue)")
            if gameLogic.gameMode == .oneScreen {
                image = image?.rotate(radians: .pi)
            }
        }
        image = image?.alpha(constants.alphaForTrashBackground)
        destroyedFiguresBackground.image = image
        return destroyedFigures
    }
    
    private func makeEndOfTheGameView() {
        showEndOfTheGameView.isEnabled = true
        surenderButton.isEnabled = false
        frameForEndOfTheGameView.image = UIImage(named: "frames/\(gameLogic.winner!.frame.rawValue)")
        let winnerBackground = UIImage(named: "backgrounds/\(gameLogic.winner!.playerBackground.rawValue)")?.alpha(constants.alphaForPlayerBackground)
        let data = makeEndOfTheGameData()
        endOfTheGameView.image = winnerBackground
        view.addSubview(frameForEndOfTheGameView)
        view.addSubview(endOfTheGameView)
        view.addSubview(endOfTheGameScrollView)
        endOfTheGameScrollView.addSubview(data)
        for view in [data, frameForEndOfTheGameView, endOfTheGameView, endOfTheGameScrollView] {
            animateTransition(of: view)
        }
        let contentHeight = data.heightAnchor.constraint(equalTo: endOfTheGameScrollView.heightAnchor)
        contentHeight.priority = .defaultLow;
        let scrollViewConstraints = [endOfTheGameScrollView.leadingAnchor.constraint(equalTo: endOfTheGameView.leadingAnchor), endOfTheGameScrollView.trailingAnchor.constraint(equalTo: endOfTheGameView.trailingAnchor), endOfTheGameScrollView.topAnchor.constraint(equalTo: endOfTheGameView.topAnchor), endOfTheGameScrollView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)]
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
    private func animateAdditionalButtons() {
        let currentTransformOfArrow = self.currentTransformOfArrow
        let positionOfAdditionalButton = getFrameForAnimation(firstView: scrollContentOfGame, secondView: additionalButton).origin
        let positionOfArrow = arrowToAdditionalButtons.layer.position
        let positionOfAdditButtons = additionalButtons.layer.position
        if additionalButtons.alpha == 0 {
            //curtain animation
            additionalButtons.transform = constants.transformForAdditionalButtons
            arrowToAdditionalButtons.transform = currentTransformOfArrow.concatenating(constants.transformForAdditionalButtons)
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
            arrowToAdditionalButtons.layer.position = positionOfAdditionalButton
            additionalButtons.layer.position = positionOfAdditionalButton
            arrowToAdditionalButtons.layer.moveTo(position: positionOfArrow, animated: true, duration: constants.animationDuration)
            additionalButtons.layer.moveTo(position: positionOfAdditButtons, animated: true, duration: constants.animationDuration)
            UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
                self?.arrowToAdditionalButtons.transform = currentTransformOfArrow.rotated(by: .pi)
                self?.additionalButtons.transform = .identity
                self?.additionalButtons.alpha = 1
                self?.arrowToAdditionalButtons.alpha = 1
            })
        }
        else {
            arrowToAdditionalButtons.layer.moveTo(position: positionOfAdditionalButton, animated: true, duration: constants.animationDuration)
            additionalButtons.layer.moveTo(position: positionOfAdditionalButton, animated: true, duration: constants.animationDuration)
            arrowToAdditionalButtons.layer.position = positionOfArrow
            additionalButtons.layer.position = positionOfAdditButtons
            UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
                self?.additionalButtons.transform = constants.transformForAdditionalButtons
                self?.arrowToAdditionalButtons.transform = currentTransformOfArrow.concatenating(constants.transformForAdditionalButtons)
                self?.arrowToAdditionalButtons.alpha = 0
                self?.additionalButtons.alpha = 0
            }) {[weak self] _ in
                self?.additionalButtons.transform = .identity
                self?.arrowToAdditionalButtons.transform = currentTransformOfArrow
            }
        }
    }
    
    private func makeInfoStack() -> UIStackView {
        //just for animation
        let startPoints = gameLogic.players.first!.points - gameLogic.players.first!.pointsForGame
        var endPoints = gameLogic.players.first!.points
        let startRank = gameLogic.players.first!.getRank(from: startPoints)
        let factor = endPoints > startPoints ? gameLogic.players.first!.pointsForGame / constants.dividerForFactorForPointsAnimation : -(gameLogic.players.first!.pointsForGame / constants.dividerForFactorForPointsAnimation)
        let infoStack = UIStackView()
        infoStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let rankLabel = makeLabel(text: startRank.rawValue)
        let pointsLabel = makeLabel(text: String(startPoints))
        playerProgress.backgroundColor = constants.backgroundColorForProgressBar
        //how much percentage is filled
        playerProgress.progress = CGFloat(startPoints * 100 / gameLogic.players.first!.rank.maximumPoints) / 100.0
        playerProgress.translatesAutoresizingMaskIntoConstraints = false
        if endPoints < 0 {
            endPoints = 0
        }
        animatePoints(interval: constants.intervalForPointsAnimation, startPoints: startPoints, endPoints: endPoints, playerProgress: playerProgress, pointsLabel: pointsLabel, factor: factor, rank: startRank, rankLabel: rankLabel)
        infoStack.addArrangedSubview(rankLabel)
        infoStack.addArrangedSubview(playerProgress)
        infoStack.addArrangedSubview(pointsLabel)
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
        turns.isUserInteractionEnabled = true
        turnBackward.isEnabled = true
        let hideButton = UIButton()
        hideButton.buttonWith(image: UIImage(systemName: "eye.slash"), and: #selector(transitEndOfTheGameView))
        let data = UIImageView()
        data.defaultSettings()
        data.isUserInteractionEnabled = true
        data.backgroundColor = data.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        let playerBackground = UIImage(named: "backgrounds/\(gameLogic.players.first!.playerBackground.rawValue)")?.alpha(constants.alphaForPlayerBackground)
        let playerAvatar = UIImageView()
        playerAvatar.rectangleView(width: min(view.frame.width, view.frame.height) / constants.dividerForCurrentPlayerAvatar)
        playerAvatar.image = playerBackground
        let wheel = WheelOfFortune(figuresTheme: gameLogic.players.first!.figuresTheme, maximumCoins: gameLogic.maximumCoinsForWheel)
        wheel.translatesAutoresizingMaskIntoConstraints = false
        gameLogic.addCoinsToPlayer(coins: wheel.winCoins)
        var titleText = "Congrats!"
        if gameLogic.draw {
            titleText = "What a game, but it is a draw!"
        }
        else if gameLogic.winner == gameLogic.players.second! {
            titleText = "Better luck next time!"
        }
        let infoStack = makeInfoStack()
        let titleLabel = makeLabel(text: titleText)
        let nameLabel = makeLabel(text: "\(gameLogic.players.first!.name)")
        data.addSubview(nameLabel)
        data.addSubview(titleLabel)
        data.addSubview(infoStack)
        data.addSubview(playerAvatar)
        data.addSubview(wheel)
        data.addSubview(hideButton)
        let titleLabelConstraints = [titleLabel.centerXAnchor.constraint(equalTo: data.centerXAnchor), titleLabel.topAnchor.constraint(equalTo: data.topAnchor, constant: constants.optimalDistance), titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: data.leadingAnchor, constant: constants.optimalDistance), titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: data.trailingAnchor, constant: -constants.optimalDistance)]
        let playerDataConstraints = [nameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: constants.optimalDistance), nameLabel.centerXAnchor.constraint(equalTo: data.centerXAnchor), nameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: data.layoutMarginsGuide.leadingAnchor), nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: data.layoutMarginsGuide.trailingAnchor), playerAvatar.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: constants.optimalDistance), playerAvatar.leadingAnchor.constraint(equalTo: data.leadingAnchor, constant: constants.optimalDistance), infoStack.centerYAnchor.constraint(equalTo: playerAvatar.centerYAnchor),  infoStack.leadingAnchor.constraint(equalTo: playerAvatar.trailingAnchor, constant: constants.optimalDistance), infoStack.trailingAnchor.constraint(equalTo: data.trailingAnchor, constant: -constants.optimalDistance)]
        let wheelConstraints = [wheel.topAnchor.constraint(equalTo: playerAvatar.bottomAnchor, constant: constants.optimalDistance), wheel.centerXAnchor.constraint(equalTo: data.centerXAnchor), wheel.heightAnchor.constraint(equalTo: wheel.widthAnchor), wheel.leadingAnchor.constraint(equalTo: data.layoutMarginsGuide.leadingAnchor, constant: constants.optimalDistance), wheel.trailingAnchor.constraint(equalTo: data.layoutMarginsGuide.trailingAnchor, constant: -constants.optimalDistance)]
        let hideButtonConstraints = [hideButton.centerXAnchor.constraint(equalTo: data.centerXAnchor), hideButton.topAnchor.constraint(equalTo: wheel.bottomAnchor, constant: constants.optimalDistance), hideButton.widthAnchor.constraint(equalToConstant: min(view.frame.width, view.frame.height) / constants.dividerForButton), hideButton.heightAnchor.constraint(equalTo: hideButton.widthAnchor), hideButton.bottomAnchor.constraint(equalTo: data.layoutMarginsGuide.bottomAnchor)]
        NSLayoutConstraint.activate(titleLabelConstraints + playerDataConstraints + wheelConstraints + hideButtonConstraints)
        return data
    }
    
    //makes chess timers
    private func makeTimers() {
        scrollContentOfGame.addSubview(player1Timer)
        scrollContentOfGame.addSubview(player2Timer)
        if gameLogic.gameMode == .oneScreen {
            player2Timer.transform = player2Timer.transform.rotated(by: .pi)
        }
    }
    
    //converts timer time into human readable string
    private func prodTimeString(_ time: Int) -> String {
        let prodMinutes = time / 60 % 60
        let prodSeconds = time % 60
        return String(format: "%02d:%02d", prodMinutes, prodSeconds)
    }
    
    private func makeTurnsView() {
        let heightForButtons = min(view.frame.width, view.frame.height)  / constants.dividerForSquare
        let playerBackground = UIImage(named: "backgrounds/\(gameLogic.players.first!.playerBackground.rawValue)")
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
        let hideTimers = UIButton()
        hideTimers.buttonWith(image: UIImage(systemName: "timer"), and: #selector(transitTimers))
        turnsButtons.addArrangedSubview(turnBackward)
        turnsButtons.addArrangedSubview(turnAction)
        turnsButtons.addArrangedSubview(turnForward)
        turnsButtons.addArrangedSubview(hideButton)
        turnsButtons.addArrangedSubview(hideTimers)
        turnsView.addSubview(background)
        turnsView.addSubview(turnsScrollView)
        turnsView.addSubview(turnsButtons)
        turnsScrollView.addSubview(turnsContent)
        scrollContentOfGame.addSubview(turnsView)
        turnsContent.addSubview(turns)
        let contentHeight = turnsContent.heightAnchor.constraint(equalTo: turnsScrollView.heightAnchor)
        contentHeight.priority = .defaultLow;
        let turnsViewConstraints = [turnsView.leadingAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.leadingAnchor), turnsView.trailingAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.trailingAnchor), turnsView.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.distanceForTurns), turnsView.bottomAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.bottomAnchor)]
        let turnsScrollViewConstraints = [turnsScrollView.leadingAnchor.constraint(equalTo: turnsView.leadingAnchor), turnsScrollView.trailingAnchor.constraint(equalTo: turnsView.trailingAnchor), turnsScrollView.topAnchor.constraint(equalTo: turnsButtons.bottomAnchor), turnsScrollView.bottomAnchor.constraint(equalTo: turnsView.bottomAnchor)]
        let contentConstraints = [turnsContent.topAnchor.constraint(equalTo: turnsScrollView.topAnchor), turnsContent.bottomAnchor.constraint(equalTo: turnsScrollView.bottomAnchor), turnsContent.leadingAnchor.constraint(equalTo: turnsScrollView.leadingAnchor), turnsContent.trailingAnchor.constraint(equalTo: turnsScrollView.trailingAnchor), turnsContent.widthAnchor.constraint(equalTo: turnsScrollView.widthAnchor), contentHeight]
        let buttonsConstraints = [turnsButtons.topAnchor.constraint(equalTo: turnsView.topAnchor), turnsButtons.centerXAnchor.constraint(equalTo: turnsView.centerXAnchor), turnsButtons.heightAnchor.constraint(equalToConstant: heightForButtons), turnBackward.widthAnchor.constraint(equalToConstant: heightForButtons)]
        let turnsConstraints = [turns.topAnchor.constraint(equalTo: turnsContent.layoutMarginsGuide.topAnchor), turns.bottomAnchor.constraint(equalTo: turnsContent.layoutMarginsGuide.bottomAnchor), turns.leadingAnchor.constraint(equalTo: turnsContent.layoutMarginsGuide.leadingAnchor), turns.trailingAnchor.constraint(equalTo: turnsContent.layoutMarginsGuide.trailingAnchor)]
        let backgroundConstraints = [background.widthAnchor.constraint(equalTo: turnsView.widthAnchor), background.heightAnchor.constraint(equalTo: turnsView.heightAnchor), background.centerXAnchor.constraint(equalTo: turnsView.centerXAnchor), background.centerYAnchor.constraint(equalTo: turnsView.centerYAnchor)]
        NSLayoutConstraint.activate(turnsViewConstraints + contentConstraints + buttonsConstraints + turnsConstraints + backgroundConstraints + turnsScrollViewConstraints)
    }
    
}

private struct GameVC_Constants {
    static let heightMultiplierForEndOfTheGameView = 0.5
    static let defaultPlayerDataColor = UIColor.white
    static let dangerPlayerDataColor = UIColor.red
    static let dangerTimeleft = 20
    static let currentPlayerDataColor = UIColor.green
    static let multiplierForBackground: CGFloat = 0.5
    static let alphaForTrashBackground: CGFloat = 1
    static let alphaForPlayerBackground: CGFloat = 0.5
    static let optimalAlpha: CGFloat = 0.7
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
    static let heightDividerForFrame: CGFloat = dividerForSquare / 1.5
    static let heightDividerForTitle: CGFloat = dividerForSquare / 0.8
    static let distanceForTitle: CGFloat = 1
    static let optimalSpacing: CGFloat = 5
    static let keyNameForSquare = "Square"
    static let keyNameForTurn = "Turn"
    static let dividerForWheelRadius: CGFloat = 1.7
    static let dividerForFactorForPointsAnimation = 2
    static let intervalForPointsAnimation = 0.1
    static let muttiplierForIntervalForPointsAnimation = 1.8
    static let pointsAnimationStep = 1
    static let dividerForCurrentPlayerAvatar = 3.0
    static let dividerForEndDataDistance = 2.0
    static let dividerForButton = 6.0
    static let distanceAfterWheel: CGFloat = 80
    static let backgroundColorForProgressBar = UIColor.white
    static let backgroundForArrow = UIColor.clear
    static let configurationForArrow = UIImage.SymbolConfiguration(weight: .heavy)
    static let weightForAddionalButtons = UIImage.SymbolWeight.light
    static let scaleForAddionalButtons = UIImage.SymbolScale.small
    static let cornerRadiusForChessTime = 7.0
    static let weightForChessTime = UIFont.Weight.regular
    static let transformForAdditionalButtons = CGAffineTransform(scaleX: 0.1,y: 0.1)
    static let shortCastleNotation = "0-0"
    static let longCastleNotation = "0-0-0"
    static let checkmateNotation = "#"
    static let checkNotation = "+"
    static let figureEatenNotation = "x"
    
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

