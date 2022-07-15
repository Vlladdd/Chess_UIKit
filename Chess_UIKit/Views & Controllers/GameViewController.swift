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
        updateCurrentPlayer()
    }
    
    // MARK: - Properties
    
    private let gameLogic = GameLogic()
    
    private typealias constants = GameVC_Constants
    
    // MARK: - User Initiated Methods
    
    @objc func makeTurn(_ sender: UITapGestureRecognizer? = nil) {
        if let square = sender?.view?.layer.value(forKey: constants.keyNameForSquare) as? Square {
            gameLogic.makeTurn(square: square)
            updateUI()
        }
    }
    
    //when pawn reached last row
    @objc func replacePawn(_ sender: UITapGestureRecognizer? = nil) {
        if let square = sender?.view?.layer.value(forKey: constants.keyNameForSquare) as? Square {
            gameLogic.makeTurn(square: square)
            updateSquare(figure: square.figure)
        }
    }
    
    //shows/hides end of the game view
    @objc func transitEndOfTheGameView(_ sender: UIButton? = nil) {
        animateTransition(of: frameForEndOfTheGameView, startAlpha: frameForEndOfTheGameView.alpha)
        animateTransition(of: endOfTheGameScrollView, startAlpha: endOfTheGameScrollView.alpha)
        animateTransition(of: endOfTheGameView, startAlpha: endOfTheGameView.alpha)
    }
    
    //shows/hides additional buttons
    @objc func transitAdditonalButtons(_ sender: UIButton? = nil) {
        animateAdditionalButtons()
        if let sender = sender {
            if sender.currentBackgroundImage == UIImage(systemName: "arrowtriangle.up.fill") {
                sender.setBackgroundImage(UIImage(systemName: "arrowtriangle.down.fill"), for: .normal)
            }
            else {
                sender.setBackgroundImage(UIImage(systemName: "arrowtriangle.up.fill"), for: .normal)
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
    
    //lets player surender
    @objc func surender(_ sender: UIButton? = nil) {
        let surenderAlert = UIAlertController(title: "Surender", message: "Are you sure?", preferredStyle: .alert)
        surenderAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            if let self = self {
                sender?.isEnabled = false
                self.gameLogic.surender()
                self.makeEndOfTheGameView()
            }
        }))
        surenderAlert.addAction(UIAlertAction(title: "No", style: .cancel))
        present(surenderAlert, animated: true, completion: nil)
    }
    
    //TODO: -
    
    //shows/hides turns view
    @objc func transitTurnsView(_ sender: UIButton? = nil) {
        
    }
    
    //exits from game
    @objc func exit(_ sender: UIButton? = nil) {
        
    }
    
    //
    
    // MARK: - Local Methods
    
    private func updateSquare(figure: Figure?) {
        if let turn = gameLogic.turns.last, let square = turn.squares.last, let figure = figure {
            if let squareView = squares.first(where: {$0.layer.value(forKey: constants.keyNameForSquare) as? Square == square}) {
                var square = squareView.layer.value(forKey: constants.keyNameForSquare) as? Square
                square?.figure = figure
                squareView.layer.setValue(square, forKey: constants.keyNameForSquare)
                for subview in squareView.subviews {
                    subview.removeFromSuperview()
                }
                let themeName = gameLogic.currentPlayer.figuresTheme.rawValue
                let figureImage = UIImage(named: "figuresThemes/\(themeName)/\(figure.color.rawValue)_\(figure.name.rawValue)")
                let figureView = getSquareView(image: figureImage)
                squareView.addSubview(figureView)
                let figureViewConstraints = [figureView.centerXAnchor.constraint(equalTo: squareView.centerXAnchor), figureView.centerYAnchor.constraint(equalTo: squareView.centerYAnchor)]
                NSLayoutConstraint.activate(figureViewConstraints)
                pawnPicker.removeFromSuperview()
            }
        }
        updateUI()
    }
    
    //updates Ui after player turn
    private func updateUI() {
        updateSquares()
        if gameLogic.shortCastle || gameLogic.longCastle {
            animateTurn(gameLogic.turns.beforeLast!)
            animateTurn(gameLogic.turns.last!)
            gameLogic.resetCastle()
            updateUI()
        }
        else if gameLogic.pickedSquares.count > 1 {
            if gameLogic.timerEnabled && !gameLogic.gameEnded {
                player1Timer.text = prodTimeString(gameLogic.players.first!.timeLeft)
                player2Timer.text = prodTimeString(gameLogic.players.second!.timeLeft)
                Timer.scheduledTimer(withTimeInterval: constants.animationDuration, repeats: false, block: {[weak self] _ in
                    if let self = self {
                        self.gameLogic.activateTime(callback: {time in
                            if time == 0 {
                                self.makeEndOfTheGameView()
                            }
                            if self.gameLogic.currentPlayer.type == .player1 {
                                self.player1Timer.text = self.prodTimeString(time)
                            }
                            else {
                                self.player2Timer.text = self.prodTimeString(time)
                            }
                        })
                    }
                })
            }
            updateCurrentPlayer()
            if let turn = gameLogic.turns.last{
                if gameLogic.pawnWizard {
                    if let square = turn.squares.first, let figure = square.figure {
                        showPawnPicker(square: square, figureColor: figure.color)
                    }
                }
                animateTurn(turn)
            }
        }
    }
    
    private func updateCurrentPlayer() {
        switch gameLogic.currentPlayer.type {
        case .player1:
            player1FrameView.updateTextBackgroundColor(constants.currentPlayerDataColor)
            player2FrameView.updateTextBackgroundColor(constants.defaultPlayerDataColor)
            UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
                if let self = self {
                    self.player1Timer.layer.backgroundColor = constants.currentPlayerDataColor.withAlphaComponent(constants.optimalAlpha).cgColor
                    self.player2Timer.layer.backgroundColor = constants.defaultPlayerDataColor.withAlphaComponent(constants.optimalAlpha).cgColor
                }
            })
        case .player2:
            player1FrameView.updateTextBackgroundColor(constants.defaultPlayerDataColor)
            player2FrameView.updateTextBackgroundColor(constants.currentPlayerDataColor)
            UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
                if let self = self {
                    self.player2Timer.layer.backgroundColor = constants.currentPlayerDataColor.withAlphaComponent(constants.optimalAlpha).cgColor
                    self.player1Timer.layer.backgroundColor = constants.defaultPlayerDataColor.withAlphaComponent(constants.optimalAlpha).cgColor
                }
            })
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
        if figureColor == .white {
            pawnPickerConstraints = [pawnPicker.topAnchor.constraint(equalTo: gameBoard.bottomAnchor), pawnPicker.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        }
        else {
            pawnPickerConstraints = [pawnPicker.bottomAnchor.constraint(equalTo: gameBoard.topAnchor), pawnPicker.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        }
        NSLayoutConstraint.activate(pawnPickerConstraints)
    }
    
    private func updateSquares() {
        for view in squares {
            if let square = view.layer.value(forKey: constants.keyNameForSquare) as? Square {
                if let turn = gameLogic.turns.last, turn.squares.contains(square) {
                    view.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.turnColor)
                }
                else {
                    switch square.color {
                    case .white:
                        view.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.firstColor)
                    case .black:
                        view.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.secondColor)
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
                        view.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.pickColor)
                    }
                    else if gameLogic.availableSquares.contains(square) {
                        view.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.availableSquaresColor)
                        view.isUserInteractionEnabled = true
                    }
                }
                if gameLogic.check {
                    if square.figure?.name == .king && square.figure?.color != gameLogic.turns.last?.squares.first?.figure?.color {
                        view.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.checkColor)
                    }
                }
            }
        }
    }
    
    private func animateTurn(_ turn: Turn) {
        gameLogic.resetPickedSquares() 
        //waiting for the end of animation
        for square in squares {
            square.isUserInteractionEnabled = false
        }
        let firstSquare = gameLogic.getUpdatedSquares(from: turn).first
        let secondSquare = gameLogic.getUpdatedSquares(from: turn).second
        let firstSquareView = squares.first(where: {$0.layer.value(forKey: constants.keyNameForSquare) as? Square == firstSquare})
        let secondSquareView = squares.first(where: {$0.layer.value(forKey: constants.keyNameForSquare) as? Square == secondSquare})
        //if en passant
        let pawnSquare = gameLogic.pawnSquare
        gameLogic.resetPawnSquare()
        var thirdSquareView: UIImageView?
        if let pawnSquare = pawnSquare {
            thirdSquareView = squares.first(where: {$0.layer.value(forKey: constants.keyNameForSquare) as? Square == pawnSquare})
        }
        if let firstSquareView = firstSquareView, let secondSquareView = secondSquareView, let firstSquare = firstSquare, let secondSquare = secondSquare {
            animateFigures(firstSquareView: firstSquareView, secondSquareView: secondSquareView, thirdSquareView: thirdSquareView, firstSquare: firstSquare, secondSquare: secondSquare, pawnSquare: pawnSquare)
        }
    }
    
    private func animateFigures(firstSquareView: UIImageView, secondSquareView: UIImageView, thirdSquareView: UIImageView?, firstSquare: Square, secondSquare: Square, pawnSquare: Square?) {
        bringFigureToFront(figureView: firstSquareView)
        let frame = getFrameForAnimation(firstView: firstSquareView, secondView: secondSquareView)
        //turn animation
        UIView.animate(withDuration: constants.animationDuration, animations: {
            for subview in firstSquareView.subviews {
                subview.transform = CGAffineTransform(translationX: frame.minX - firstSquareView.bounds.minX, y: frame.minY - firstSquareView.bounds.minY)
            }
        }) { [weak self] _ in
            if let self = self {
                self.moveFigureToTrash(squareView: secondSquareView)
                for subview in firstSquareView.subviews {
                    subview.transform = .identity
                    secondSquareView.addSubview(subview)
                    let imageViewConstraints = [subview.centerXAnchor.constraint(equalTo: secondSquareView.centerXAnchor), subview.centerYAnchor.constraint(equalTo: secondSquareView.centerYAnchor)]
                    NSLayoutConstraint.activate(imageViewConstraints)
                }
                secondSquareView.layer.setValue(secondSquare, forKey: constants.keyNameForSquare)
                firstSquareView.layer.setValue(firstSquare, forKey: constants.keyNameForSquare)
                if let thirdSquareView = thirdSquareView, let pawnSquare = pawnSquare {
                    thirdSquareView.layer.setValue(pawnSquare, forKey: constants.keyNameForSquare)
                    self.moveFigureToTrash(squareView: thirdSquareView)
                }
                self.updateUI()
                if self.gameLogic.gameEnded {
                    self.makeEndOfTheGameView()
                }
            }
        }
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
        figureView.bringSubviewToFront(figureView.subviews.first!)
        scrollContentOfGame.bringSubviewToFront(additionalButtons)
    }
    
    private func getFrameForAnimation(firstView: UIView, secondView: UIView) -> CGRect {
        return firstView.convert(secondView.bounds, from: secondView)
    }
    
    private func moveFigureToTrash(squareView: UIImageView) {
        for subview in squareView.subviews {
            bringFigureToFront(figureView: squareView)
            if gameLogic.gameMode == .oneScreen {
                if let subview = subview as? UIImageView {
                    subview.image = subview.image?.rotate(radians: .pi)
                }
            }
            var coordinates: (xCoordinate: CGFloat, yCoordinate: CGFloat) = (0, 0)
            switch gameLogic.currentPlayer.type {
            case .player1:
                coordinates = coordinatesForTrashAnimation(player: .player1, squareView: squareView, destroyedFiguresStack1: player1DestroyedFigures1, destroyedFiguresStack2: player1DestroyedFigures2)
            case .player2:
                coordinates = coordinatesForTrashAnimation(player: .player2, squareView: squareView, destroyedFiguresStack1: player2DestroyedFigures1, destroyedFiguresStack2: player2DestroyedFigures2)
            }
            animateFigureToTrash(figure: subview, x: coordinates.xCoordinate, y: coordinates.yCoordinate)
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
    
    private func animateFigureToTrash(figure: UIView, x: CGFloat, y: CGFloat) {
        UIView.animate(withDuration: constants.animationDuration, animations: {
            figure.transform = CGAffineTransform(translationX: x, y: y)
        }) {[weak self] _ in
            if let self = self {
                figure.transform = .identity
                switch self.gameLogic.currentPlayer.type {
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
    
    private var player1Timer = UILabel()
    private var player2Timer = UILabel()
    private var squares = [UIImageView]()
    private var destroyedFigures1 = UIView()
    private var destroyedFigures2 = UIView()
    private var player1FrameView = PlayerFrame()
    private var player2FrameView = PlayerFrame()
    private var player1TitleView = PlayerFrame()
    private var player2TitleView = PlayerFrame()
    
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
        arrowToAdditionalButtons.defaultSettings()
        arrowToAdditionalButtons.layer.borderWidth = 0
        arrowToAdditionalButtons.backgroundColor = constants.backgroundForArrow
        arrowToAdditionalButtons.alpha = 0
        arrowToAdditionalButtons.contentMode = .scaleAspectFit
        let figuresThemeName = gameLogic.players.first!.figuresTheme.rawValue
        let figureColor = traitCollection.userInterfaceStyle == .dark ? GameColors.black.rawValue : GameColors.white.rawValue
        let figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(figureColor)_pawn")
        arrowToAdditionalButtons.image = figureImage
        scrollContentOfGame.addSubview(arrowToAdditionalButtons)
        let additionalButton = UIButton()
        additionalButton.buttonWith(image: UIImage(systemName: "arrowtriangle.down.fill"), and: #selector(transitAdditonalButtons))
        if let stackWhereToAdd = gameBoard.arrangedSubviews.last {
            if let stackWhereToAdd = stackWhereToAdd as? UIStackView {
                if let viewWhereToAdd = stackWhereToAdd.arrangedSubviews.first {
                    viewWhereToAdd.addSubview(additionalButton)
                    let additionalButtonConstraints = [additionalButton.widthAnchor.constraint(equalTo: viewWhereToAdd.widthAnchor, multiplier: constants.multiplierForNumberView), additionalButton.heightAnchor.constraint(equalTo: viewWhereToAdd.heightAnchor, multiplier: constants.multiplierForNumberView), additionalButton.centerXAnchor.constraint(equalTo: viewWhereToAdd.centerXAnchor), additionalButton.centerYAnchor.constraint(equalTo: viewWhereToAdd.centerYAnchor), arrowToAdditionalButtons.topAnchor.constraint(equalTo: viewWhereToAdd.bottomAnchor), arrowToAdditionalButtons.centerXAnchor.constraint(equalTo: viewWhereToAdd.centerXAnchor), arrowToAdditionalButtons.widthAnchor.constraint(equalTo: viewWhereToAdd.widthAnchor), arrowToAdditionalButtons.heightAnchor.constraint(equalTo: viewWhereToAdd.heightAnchor)]
                    NSLayoutConstraint.activate(additionalButtonConstraints)
                }
            }
        }
    }
    
    private func makeAdditionalButtons() {
        let heightForAdditionalButtons = min(view.frame.width, view.frame.height)  / constants.dividerForSquare
        let configForAdditionalButtons = UIImage.SymbolConfiguration(pointSize: heightForAdditionalButtons, weight: constants.weightForAddionalButtons, scale: constants.scaleForAddionalButtons)
        let surenderButton = UIButton()
        surenderButton.buttonWith(image: UIImage(systemName: "flag.fill", withConfiguration: configForAdditionalButtons), and: #selector(surender))
        let lockScrolling = UIButton()
        lockScrolling.buttonWith(image: UIImage(systemName: "lock.open", withConfiguration: configForAdditionalButtons), and: #selector(lockGameView))
        let turnsViewButton = UIButton()
        turnsViewButton.buttonWith(image: UIImage(systemName: "backward", withConfiguration: configForAdditionalButtons), and: #selector(transitTurnsView))
        let exitsButton = UIButton()
        exitsButton.buttonWith(image: UIImage(systemName: "rectangle.portrait.and.arrow.right", withConfiguration: configForAdditionalButtons), and: #selector(exit))
        showEndOfTheGameView.buttonWith(image: UIImage(systemName: "doc.text.magnifyingglass", withConfiguration: configForAdditionalButtons), and: #selector(transitEndOfTheGameView))
        additionalButtons.alpha = 0
        additionalButtons.addArrangedSubview(showEndOfTheGameView)
        additionalButtons.addArrangedSubview(lockScrolling)
        additionalButtons.addArrangedSubview(surenderButton)
        additionalButtons.addArrangedSubview(turnsViewButton)
        additionalButtons.addArrangedSubview(exitsButton)
        scrollContentOfGame.addSubview(additionalButtons)
        let additionalButtonsConstraints = [additionalButtons.topAnchor.constraint(equalTo: arrowToAdditionalButtons.bottomAnchor), additionalButtons.leadingAnchor.constraint(equalTo: scrollContentOfGame.leadingAnchor, constant: constants.optimalDistance), additionalButtons.heightAnchor.constraint(equalToConstant: heightForAdditionalButtons), showEndOfTheGameView.widthAnchor.constraint(equalTo: showEndOfTheGameView.heightAnchor)]
        NSLayoutConstraint.activate(additionalButtonsConstraints)
    }
    
    private func makeUI() {
        let widthForFrame = min(view.frame.width, view.frame.height)  / constants.widthDividerForTrash
        let heightForFrame = min(view.frame.width, view.frame.height)  / constants.heightDividerForFrame
        let heightForTitle = min(view.frame.width, view.frame.height)  / constants.heightDividerForTitle
        setupViews()
        addPlayersBackgrounds()
        makeScrollViewOfGame()
        makePlayer2Title(width: widthForFrame, height: heightForTitle)
        makePlayer2Frame(width: widthForFrame, height: heightForFrame)
        makePlayer2DestroyedFiguresView()
        makeGameBoard()
        makePlayer1DestroyedFiguresView()
        makePlayer1Frame(width: widthForFrame, height: heightForFrame)
        makePlayer1Title(width: widthForFrame, height: heightForTitle)
        makeAdditionalButton()
        makeAdditionalButtons()
        if gameLogic.timerEnabled {
            makeTimers()
        }
    }
    
    private func setupViews() {
        showEndOfTheGameView.isEnabled = false
        pawnPicker.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        gameBoard.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player1DestroyedFigures1.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player1DestroyedFigures2.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player2DestroyedFigures1.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player2DestroyedFigures2.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        additionalButtons.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.spacingForPlayerData)
        endOfTheGameView.defaultSettings()
        player1Timer = makeLabel(text: prodTimeString(gameLogic.players.first!.timeLeft))
        player2Timer = makeLabel(text: prodTimeString(gameLogic.players.second!.timeLeft))
        additionalButtons.defaultSettings()
    }
    
    private func makeScrollViewOfGame() {
        scrollContentOfGame.translatesAutoresizingMaskIntoConstraints = false
        scrollViewOfGame.translatesAutoresizingMaskIntoConstraints = false
        scrollViewOfGame.delaysContentTouches = false
        view.addSubview(scrollViewOfGame)
        scrollViewOfGame.addSubview(scrollContentOfGame)
        let contentHeight = scrollContentOfGame.heightAnchor.constraint(equalTo: scrollViewOfGame.heightAnchor)
        contentHeight.priority = .defaultLow;
        let scrollViewConstraints = [scrollViewOfGame.leadingAnchor.constraint(equalTo: view.leadingAnchor), scrollViewOfGame.trailingAnchor.constraint(equalTo: view.trailingAnchor), scrollViewOfGame.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor), scrollViewOfGame.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)]
        let contentConstraints = [scrollContentOfGame.topAnchor.constraint(equalTo: scrollViewOfGame.topAnchor), scrollContentOfGame.bottomAnchor.constraint(equalTo: scrollViewOfGame.bottomAnchor), scrollContentOfGame.leadingAnchor.constraint(equalTo: scrollViewOfGame.leadingAnchor), scrollContentOfGame.trailingAnchor.constraint(equalTo: scrollViewOfGame.trailingAnchor), scrollContentOfGame.widthAnchor.constraint(equalTo: scrollViewOfGame.widthAnchor), contentHeight]
        NSLayoutConstraint.activate(scrollViewConstraints + contentConstraints)
    }
    
    private func makePlayer2Frame(width: CGFloat, height: CGFloat) {
        let player2Background = gameLogic.players.second!.playerBackground
        let player2Frame = gameLogic.players.second!.frame
        let player2Data = UIStackView()
        player2Data.setup(axis: .horizontal, alignment: .fill, distribution: .equalSpacing, spacing: constants.spacingForPlayerData)
        let player2Name = makeLabel(text: gameLogic.players.second!.name)
        let player2Points = makeLabel(text: String(gameLogic.players.second!.points))
        player2Data.addArrangedSubview(player2Name)
        player2Data.addArrangedSubview(player2Points)
        player2FrameView = PlayerFrame(background: player2Background, playerFrame: player2Frame, data: player2Data)
        player2FrameView.translatesAutoresizingMaskIntoConstraints = false
        player2FrameView.backgroundColor = .clear
        scrollContentOfGame.addSubview(player2FrameView)
        let player2FrameViewConstraints = [player2FrameView.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player2FrameView.topAnchor.constraint(equalTo: player2TitleView.bottomAnchor, constant: constants.distanceForTitle), player2FrameView.widthAnchor.constraint(equalToConstant: width), player2FrameView.heightAnchor.constraint(equalToConstant: height)]
        NSLayoutConstraint.activate(player2FrameViewConstraints)
        if gameLogic.gameMode == .oneScreen {
            player2FrameView.transform = player2FrameView.transform.rotated(by: .pi)
        }
        scrollContentOfGame.bringSubviewToFront(player2TitleView)
    }
    
    private func makePlayer1Frame(width: CGFloat, height: CGFloat) {
        let player1Background = gameLogic.players.first!.playerBackground
        let player1Frame = gameLogic.players.first!.frame
        let player1Data = UIStackView()
        player1Data.setup(axis: .horizontal, alignment: .fill, distribution: .equalSpacing, spacing: constants.spacingForPlayerData)
        let player1Name = makeLabel(text: gameLogic.players.first!.name)
        let player1Points = makeLabel(text: String(gameLogic.players.first!.points))
        player1Data.addArrangedSubview(player1Name)
        player1Data.addArrangedSubview(player1Points)
        player1FrameView = PlayerFrame(background: player1Background, playerFrame: player1Frame, data: player1Data)
        player1FrameView.translatesAutoresizingMaskIntoConstraints = false
        player1FrameView.backgroundColor = .clear
        scrollContentOfGame.addSubview(player1FrameView)
        let player1FrameViewConstraints = [player1FrameView.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player1FrameView.topAnchor.constraint(equalTo: destroyedFigures2.bottomAnchor, constant: constants.optimalDistance), player1FrameView.widthAnchor.constraint(equalToConstant: width), player1FrameView.heightAnchor.constraint(equalToConstant: height)]
        NSLayoutConstraint.activate(player1FrameViewConstraints)
    }
    
    private func makePlayer2Title(width: CGFloat, height: CGFloat) {
        let player2Background = gameLogic.players.second!.playerBackground
        let player2Frame = gameLogic.players.second!.frame
        let player2Title = makeLabel(text: gameLogic.players.second!.title.rawValue.capitalizingFirstLetter().replacingOccurrences(of: "_", with: " "))
        player2TitleView = PlayerFrame(background: player2Background, playerFrame: player2Frame, data: player2Title)
        player2TitleView.translatesAutoresizingMaskIntoConstraints = false
        player2TitleView.backgroundColor = .clear
        scrollContentOfGame.addSubview(player2TitleView)
        let player2TitleViewConstraints = [player2TitleView.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player2TitleView.widthAnchor.constraint(equalToConstant: width), player2TitleView.heightAnchor.constraint(equalToConstant: height), player2TitleView.topAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.topAnchor)]
        NSLayoutConstraint.activate(player2TitleViewConstraints)
        if gameLogic.gameMode == .oneScreen {
            player2TitleView.transform = player2TitleView.transform.rotated(by: .pi)
        }
    }
    
    private func makePlayer1Title(width: CGFloat, height: CGFloat) {
        let player1Background = gameLogic.players.first!.playerBackground
        let player1Frame = gameLogic.players.first!.frame
        let player1Title = makeLabel(text: gameLogic.players.first!.title.rawValue.capitalizingFirstLetter().replacingOccurrences(of: "_", with: " "))
        player1TitleView = PlayerFrame(background: player1Background, playerFrame: player1Frame, data: player1Title)
        player1TitleView.translatesAutoresizingMaskIntoConstraints = false
        player1TitleView.backgroundColor = .clear
        scrollContentOfGame.addSubview(player1TitleView)
        let player1TitleViewConstraints = [player1TitleView.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player1TitleView.widthAnchor.constraint(equalToConstant: width), player1TitleView.heightAnchor.constraint(equalToConstant: height), player1TitleView.topAnchor.constraint(equalTo: player1FrameView.bottomAnchor, constant: constants.distanceForTitle), player1TitleView.bottomAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.bottomAnchor)]
        NSLayoutConstraint.activate(player1TitleViewConstraints)
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
        let player2Frame = UIImageView()
        player2Frame.defaultSettings()
        player2Frame.image = UIImage(named: "frames/\(gameLogic.players.second!.frame.rawValue)")
        scrollContentOfGame.addSubview(player2Frame)
        //in oneScreen second stack should be first, in other words upside down
        if gameLogic.gameMode == .oneScreen {
            player2Frame.transform = player2Frame.transform.rotated(by: .pi)
            destroyedFigures1 = makeDestroyedFiguresView(destoyedFigures1: player1DestroyedFigures2, destoyedFigures2: player1DestroyedFigures1, player2: true)
        }
        else if gameLogic.gameMode == .multiplayer{
            destroyedFigures1 = makeDestroyedFiguresView(destoyedFigures1: player1DestroyedFigures1, destoyedFigures2: player1DestroyedFigures2, player2: true)
        }
        scrollContentOfGame.addSubview(destroyedFigures1)
        let player2FrameConstraints = [player2Frame.topAnchor.constraint(equalTo: player2FrameView.bottomAnchor, constant: constants.distanceForFrame), player2Frame.widthAnchor.constraint(equalTo: destroyedFigures1.widthAnchor, constant: constants.optimalDistance), player2Frame.heightAnchor.constraint(equalTo: destroyedFigures1.heightAnchor, constant: constants.optimalDistance), player2Frame.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        let destroyedFigures1Constraints = [destroyedFigures1.topAnchor.constraint(equalTo: player2FrameView.bottomAnchor, constant: constants.optimalDistance), destroyedFigures1.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        NSLayoutConstraint.activate(destroyedFigures1Constraints + player2FrameConstraints)
    }
    
    private func makePlayer1DestroyedFiguresView() {
        let player1Frame = UIImageView()
        player1Frame.defaultSettings()
        player1Frame.image = UIImage(named: "frames/\(gameLogic.players.first!.frame.rawValue)")
        scrollContentOfGame.addSubview(player1Frame)
        destroyedFigures2 = makeDestroyedFiguresView(destoyedFigures1: player2DestroyedFigures1, destoyedFigures2: player2DestroyedFigures2)
        scrollContentOfGame.addSubview(destroyedFigures2)
        let player1FrameConstraints = [player1Frame.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.distanceForFrame), player1Frame.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor), player1Frame.widthAnchor.constraint(equalTo: destroyedFigures1.widthAnchor, constant: constants.optimalDistance), player1Frame.heightAnchor.constraint(equalTo: destroyedFigures1.heightAnchor, constant: constants.optimalDistance)]
        let destroyedFigures2Constraints = [destroyedFigures2.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.optimalDistance), destroyedFigures2.centerXAnchor.constraint(equalTo: scrollContentOfGame.layoutMarginsGuide.centerXAnchor)]
        NSLayoutConstraint.activate(destroyedFigures2Constraints + player1FrameConstraints)
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
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.makeTurn(_:)))
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
        numberView.layer.borderWidth = 0
        square.addSubview(numberView)
        let numberViewConstraints = [numberView.centerXAnchor.constraint(equalTo: square.centerXAnchor), numberView.centerYAnchor.constraint(equalTo: square.centerYAnchor)]
        NSLayoutConstraint.activate(numberViewConstraints)
        return square
    }
    
    private func makeLabel(text: String) -> UILabel {
        let label = UILabel()
        label.setup(text: text, alignment: .center, font: UIFont.systemFont(ofSize: view.frame.width / constants.dividerForFont))
        return label
    }
    
    private func makePawnPicker(figureColor: GameColors, squareColor: GameColors) {
        let figures: [Figures] = [.rook, .queen, .bishop, .knight]
        for figure in figures {
            //just random square, it doesnt matter
            let square = Square(column: .A, row: 1, color: .white, figure: Figure(name: figure, color: figureColor))
            let figuresThemeName = gameLogic.currentPlayer.figuresTheme.rawValue
            let figureImage = UIImage(named: "figuresThemes/\(figuresThemeName)/\(figureColor.rawValue)_\(figure.rawValue)")
            let squareView = getSquareView(image: figureImage)
            squareView.layer.setValue(square, forKey: constants.keyNameForSquare)
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.replacePawn(_:)))
            squareView.addGestureRecognizer(tap)
            squareView.layer.borderColor = squareColor == .black ? UIColor.white.cgColor : UIColor.black.cgColor
            pawnPicker.addArrangedSubview(squareView)
        }
    }

    private func makeDestroyedFiguresView(destoyedFigures1: UIStackView, destoyedFigures2: UIStackView, player2: Bool = false) -> UIView {
        let width = min(view.frame.width, view.frame.height)  / constants.widthDividerForTrash
        let height = min(view.frame.width, view.frame.height)  / constants.heightDividerForTrash
        let destroyedFigures = UIImageView()
        destroyedFigures.defaultSettings()
        destroyedFigures.addSubview(destoyedFigures1)
        destroyedFigures.addSubview(destoyedFigures2)
        let destroyedFiguresConstraints1 = [destroyedFigures.widthAnchor.constraint(equalToConstant: width), destroyedFigures.heightAnchor.constraint(equalToConstant: height)]
        let destroyedFiguresConstraints2 = [destoyedFigures1.topAnchor.constraint(equalTo: destroyedFigures.topAnchor, constant: constants.distanceForFigureInTrash), destoyedFigures2.bottomAnchor.constraint(equalTo: destroyedFigures.bottomAnchor, constant: -constants.distanceForFigureInTrash)]
        var destroyedFiguresConstraints3: [NSLayoutConstraint] = []
        //here we add this, because stacks start from left side, but for player 2 they should start from right side
        if player2 && gameLogic.gameMode == .oneScreen {
            destroyedFiguresConstraints3 = [destoyedFigures1.trailingAnchor.constraint(equalTo: destroyedFigures.trailingAnchor), destoyedFigures2.trailingAnchor.constraint(equalTo: destroyedFigures.trailingAnchor)]
        }
        NSLayoutConstraint.activate(destroyedFiguresConstraints1 + destroyedFiguresConstraints2 + destroyedFiguresConstraints3)
        var image = UIImage(named: "backgrounds/\(gameLogic.players.first!.playerBackground.rawValue)")
        if player2 {
            image = UIImage(named: "backgrounds/\(gameLogic.players.second!.playerBackground.rawValue)")
            if gameLogic.gameMode == .oneScreen {
                image = image?.rotate(radians: .pi)
            }
        }
        image = image?.alpha(constants.alphaForTrashBackground)
        destroyedFigures.image = image
        return destroyedFigures
    }
    
    private func makeEndOfTheGameView() {
        showEndOfTheGameView.isEnabled = true
        frameForEndOfTheGameView.defaultSettings()
        frameForEndOfTheGameView.image = UIImage(named: "frames/\(gameLogic.winner!.frame.rawValue)")
        let winnerBackground = UIImage(named: "backgrounds/\(gameLogic.winner!.playerBackground.rawValue)")?.alpha(constants.alphaForPlayerBackground)
        let data = makeEndOfTheGameData()
        endOfTheGameView.image = winnerBackground
        view.addSubview(frameForEndOfTheGameView)
        view.addSubview(endOfTheGameView)
        endOfTheGameScrollView.translatesAutoresizingMaskIntoConstraints = false
        endOfTheGameScrollView.delaysContentTouches = false
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
    
    //shows/hides additional buttons with animation
    private func animateAdditionalButtons() {
        let arrowBounds = arrowToAdditionalButtons.bounds
        let additionalButtonsBounds = additionalButtons.bounds
        let centerYOfArrow = arrowToAdditionalButtons.center.y
        let centerYOfAdditionalButtons = additionalButtons.center.y
        if additionalButtons.alpha == 0 {
            //curtain animation
            additionalButtons.transform = constants.transformForAdditionalButtons
            arrowToAdditionalButtons.transform = constants.transformForAdditionalButtons
            //as i realized, we can`t rotate and translate view at the same time, cuz weird
            //animation occurs, so i decided to make it in this way (change center and then
            //comeback to original value in animation block), which leads to beautiful
            //animation (now it really looks like the additional buttons are pop out from button
            //or enters the button, which shows/hides them), exactly as i wanted to :)
            arrowToAdditionalButtons.center.y = centerYOfArrow - arrowBounds.maxY
            additionalButtons.center.y = centerYOfAdditionalButtons - additionalButtonsBounds.maxY
            UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
                self?.arrowToAdditionalButtons.transform = .identity.rotated(by: .pi)
                self?.additionalButtons.transform = .identity
                self?.additionalButtons.alpha = 1
                self?.arrowToAdditionalButtons.alpha = 1
                self?.arrowToAdditionalButtons.center.y = centerYOfArrow
                self?.additionalButtons.center.y = centerYOfAdditionalButtons
            })
        }
        else {
            UIView.animate(withDuration: constants.animationDuration, animations: {[weak self] in
                self?.additionalButtons.transform = constants.transformForAdditionalButtons
                self?.arrowToAdditionalButtons.transform = constants.transformForAdditionalButtons
                self?.arrowToAdditionalButtons.center.y = centerYOfArrow - arrowBounds.maxY
                self?.additionalButtons.center.y = centerYOfAdditionalButtons - additionalButtonsBounds.maxY
            }) {[weak self] _ in
                self?.additionalButtons.transform = .identity
                self?.arrowToAdditionalButtons.transform = .identity
                self?.arrowToAdditionalButtons.alpha = 0
                self?.additionalButtons.alpha = 0
                self?.arrowToAdditionalButtons.center.y = centerYOfArrow
                self?.additionalButtons.center.y = centerYOfAdditionalButtons
            }
        }
    }
    
    private func makeInfoStack() -> UIStackView {
        //just for animation
        let startPoints = gameLogic.players.first!.points - gameLogic.players.first!.pointsForGame
        var endPoints = gameLogic.players.first!.points
        let factor = endPoints > startPoints ? gameLogic.players.first!.pointsForGame / constants.dividerForFactorForPointsAnimation : -(gameLogic.players.first!.pointsForGame / constants.dividerForFactorForPointsAnimation)
        let infoStack = UIStackView()
        infoStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.spacingForEndInfoStack)
        let rankLabel = makeLabel(text: gameLogic.players.first!.rank.rawValue)
        let pointsLabel = makeLabel(text: String(startPoints))
        let playerProgress = ProgressBar()
        playerProgress.backgroundColor = constants.backgroundColorForProgressBar
        //how much percentage is filled
        playerProgress.progress = CGFloat(gameLogic.players.first!.points * 100 / gameLogic.players.first!.rank.maximumPoints) / 100.0
        playerProgress.translatesAutoresizingMaskIntoConstraints = false
        if endPoints < 0 {
            endPoints = 0
        }
        animatePoints(interval: constants.intervalForPointsAnimation, startPoints: startPoints, endPoints: endPoints, playerProgress: playerProgress, pointsLabel: pointsLabel, factor: factor, rank: gameLogic.players.first!.rank, rankLabel: rankLabel)
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
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: {[weak self] timer in
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
    }
    
    private func makeEndOfTheGameData() -> UIImageView {
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
        let radius = min(view.frame.width, view.frame.height) / constants.dividerForWheelRadius
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
        titleLabel.adjustsFontSizeToFitWidth = true
        let nameLabel = makeLabel(text: "\(gameLogic.players.first!.name)")
        data.addSubview(nameLabel)
        data.addSubview(titleLabel)
        data.addSubview(infoStack)
        data.addSubview(playerAvatar)
        data.addSubview(wheel)
        data.addSubview(hideButton)
        let titleLabelConstraints = [titleLabel.centerXAnchor.constraint(equalTo: data.centerXAnchor), titleLabel.topAnchor.constraint(equalTo: data.topAnchor, constant: constants.optimalDistance), titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: data.leadingAnchor, constant: constants.optimalDistance), titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: data.trailingAnchor, constant: -constants.optimalDistance)]
        let playerDataConstraints = [nameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: constants.optimalDistance), nameLabel.centerXAnchor.constraint(equalTo: data.centerXAnchor), playerAvatar.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: constants.optimalDistance), playerAvatar.leadingAnchor.constraint(equalTo: data.leadingAnchor, constant: constants.optimalDistance), infoStack.centerYAnchor.constraint(equalTo: playerAvatar.centerYAnchor),  infoStack.leadingAnchor.constraint(equalTo: playerAvatar.trailingAnchor, constant: constants.optimalDistance), infoStack.trailingAnchor.constraint(equalTo: data.trailingAnchor, constant: -constants.optimalDistance)]
        let wheelConstraints = [wheel.topAnchor.constraint(equalTo: playerAvatar.bottomAnchor, constant: constants.optimalDistance), wheel.centerXAnchor.constraint(equalTo: data.centerXAnchor), wheel.bottomAnchor.constraint(lessThanOrEqualTo: data.bottomAnchor, constant: -radius / constants.dividerForEndDataDistance), wheel.heightAnchor.constraint(equalToConstant: radius), wheel.widthAnchor.constraint(equalToConstant: radius)]
        let hideButtonConstaints = [hideButton.centerXAnchor.constraint(equalTo: data.centerXAnchor), hideButton.topAnchor.constraint(equalTo: wheel.bottomAnchor, constant: constants.distanceAfterWheel), hideButton.widthAnchor.constraint(equalToConstant: min(view.frame.width, view.frame.height) / constants.dividerForButton), hideButton.heightAnchor.constraint(equalTo: hideButton.widthAnchor), hideButton.bottomAnchor.constraint(equalTo: data.bottomAnchor, constant: -constants.optimalDistance)]
        NSLayoutConstraint.activate(titleLabelConstraints + playerDataConstraints + wheelConstraints + hideButtonConstaints)
        return data
    }
    
    //makes chess timers
    private func makeTimers() {
        player1Timer.layer.cornerRadius = constants.cornerRadiusForChessTime
        player2Timer.layer.cornerRadius = constants.cornerRadiusForChessTime
        player1Timer.layer.masksToBounds = true
        player2Timer.layer.masksToBounds = true
        player1Timer.font = UIFont.monospacedDigitSystemFont(ofSize: player1Timer.font.pointSize, weight: constants.weightForChessTime)
        player2Timer.font = UIFont.monospacedDigitSystemFont(ofSize: player2Timer.font.pointSize, weight: constants.weightForChessTime)
        scrollContentOfGame.addSubview(player1Timer)
        scrollContentOfGame.addSubview(player2Timer)
        let player1TimerConstaints = [player1Timer.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.optimalDistance), player1Timer.trailingAnchor.constraint(equalTo: scrollContentOfGame.trailingAnchor, constant: -constants.optimalDistance)]
        let player2TimerConstaints = [player2Timer.bottomAnchor.constraint(equalTo: gameBoard.topAnchor, constant: -constants.optimalDistance), player2Timer.trailingAnchor.constraint(equalTo: scrollContentOfGame.trailingAnchor, constant: -constants.optimalDistance)]
        NSLayoutConstraint.activate(player1TimerConstaints + player2TimerConstaints)
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
    
}

private struct GameVC_Constants {
    static let heightMultiplierForEndOfTheGameView = 0.5
    static let defaultPlayerDataColor = UIColor.white
    static let currentPlayerDataColor = UIColor.green
    static let multiplierForBackground: CGFloat = 0.5
    static let alphaForTrashBackground: CGFloat = 1
    static let alphaForPlayerBackground: CGFloat = 0.5
    static let optimalAlpha: CGFloat = 0.7
    static let distanceForFigureInTrash: CGFloat = 3
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
    static let spacingForPlayerData: CGFloat = 5
    static let keyNameForSquare = "Square"
    static let dividerForWheelRadius: CGFloat = 1.7
    static let dividerForFactorForPointsAnimation = 2
    static let spacingForEndInfoStack = 5.0
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
    static let transformForAdditionalButtons = CGAffineTransform(scaleX: 1,y: 0.1)
    
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

