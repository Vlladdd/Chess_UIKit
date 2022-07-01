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
        case .player2:
            player1FrameView.updateTextBackgroundColor(constants.defaultPlayerDataColor)
            player2FrameView.updateTextBackgroundColor(constants.currentPlayerDataColor)
        }
    }
    
    private func showPawnPicker(square: Square, figureColor: GameColors) {
        makePawnPicker(figureColor: figureColor, squareColor: square.color)
        view.addSubview(pawnPicker)
        pawnPicker.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.secondColor)
        if square.color == .white {
            pawnPicker.backgroundColor = constants.convertLogicColor(gameLogic.squaresTheme.firstColor)
        }
        var pawnPickerConstraints: [NSLayoutConstraint] = []
        if figureColor == .white {
            pawnPickerConstraints = [pawnPicker.topAnchor.constraint(equalTo: gameBoard.bottomAnchor), pawnPicker.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor)]
        }
        else {
            pawnPickerConstraints = [pawnPicker.bottomAnchor.constraint(equalTo: gameBoard.topAnchor), pawnPicker.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor)]
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
        bringFigureToFront(view: firstSquareView)
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
            }
        }
    }
    
    //we need to move figure image to the top
    private func bringFigureToFront(view: UIView) {
        let verticalStackView = view.superview?.superview
        let horizontalStackView = view.superview
        if let verticalStackView = verticalStackView, let horizontalStackView = horizontalStackView {
            self.view.bringSubviewToFront(verticalStackView)
            verticalStackView.bringSubviewToFront(horizontalStackView)
            horizontalStackView.bringSubviewToFront(view)
        }
        view.bringSubviewToFront(view.subviews.first!)
    }
    
    private func getFrameForAnimation(firstView: UIView, secondView: UIView) -> CGRect {
        return firstView.convert(secondView.bounds, from: secondView)
    }
    
    private func moveFigureToTrash(squareView: UIImageView) {
        for subview in squareView.subviews {
            bringFigureToFront(view: squareView)
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
    
    private let pawnPicker = UIStackView()
    private let gameBoard = UIStackView()
    //2 stacks for destroyed figures, 8 figures each
    private let player1DestroyedFigures1 = UIStackView()
    private let player1DestroyedFigures2 = UIStackView()
    private let player2DestroyedFigures1 = UIStackView()
    private let player2DestroyedFigures2 = UIStackView()
    
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
    
    private func makeUI() {
        setupViews()
        addPlayersBackgrounds()
        makeGameBoard()
        makeDestroyedFiguresViews()
        makePlayersFrames()
        makePlayersTitles()
    }
    
    private func setupViews() {
        pawnPicker.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        gameBoard.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player1DestroyedFigures1.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player1DestroyedFigures2.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player2DestroyedFigures1.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        player2DestroyedFigures2.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
    }
    
    private func makePlayersFrames() {
        let width = min(view.frame.width, view.frame.height)  / constants.dividerForSquare * constants.widthDividerForTrash
        let height = min(view.frame.width, view.frame.height)  / constants.dividerForSquare * constants.heightDividerForFrame
        let player1Background = gameLogic.players.first!.playerBackground
        let player1Frame = gameLogic.players.first!.frame
        let player2Background = gameLogic.players.second!.playerBackground
        let player2Frame = gameLogic.players.second!.frame
        player1FrameView = PlayerFrame(frame: CGRect(x: 0, y: 0, width: width, height: height), background: player1Background, playerFrame: player1Frame)
        player2FrameView = PlayerFrame(frame: CGRect(x: 0, y: 0, width: width, height: height), background: player2Background, playerFrame: player2Frame)
        player1FrameView.translatesAutoresizingMaskIntoConstraints = false
        player2FrameView.translatesAutoresizingMaskIntoConstraints = false
        player1FrameView.backgroundColor = .clear
        player2FrameView.backgroundColor = .clear
        let player1Data = UIStackView()
        let player2Data = UIStackView()
        player1Data.setup(axis: .horizontal, alignment: .fill, distribution: .equalSpacing, spacing: constants.spacingForPlayerData)
        player2Data.setup(axis: .horizontal, alignment: .fill, distribution: .equalSpacing, spacing: constants.spacingForPlayerData)
        let player1Name = makeLabel(text: gameLogic.players.first!.name)
        let player2Name = makeLabel(text: gameLogic.players.second!.name)
        let player1Points = makeLabel(text: String(gameLogic.players.first!.points))
        let player2Points = makeLabel(text: String(gameLogic.players.second!.points))
        player1Data.addArrangedSubview(player1Name)
        player1Data.addArrangedSubview(player1Points)
        player2Data.addArrangedSubview(player2Name)
        player2Data.addArrangedSubview(player2Points)
        view.addSubview(player1FrameView)
        view.addSubview(player2FrameView)
        player1FrameView.addSubview(player1Data)
        player2FrameView.addSubview(player2Data)
        let playersFramesViewConstraints = [player1FrameView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), player2FrameView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), player1FrameView.topAnchor.constraint(equalTo: destroyedFigures2.bottomAnchor, constant: constants.distanceForDestroyedFigures), player2FrameView.bottomAnchor.constraint(equalTo: destroyedFigures1.topAnchor, constant: -constants.distanceForDestroyedFigures), player1FrameView.widthAnchor.constraint(equalToConstant: width), player1FrameView.heightAnchor.constraint(equalToConstant: height), player2FrameView.widthAnchor.constraint(equalToConstant: width), player2FrameView.heightAnchor.constraint(equalToConstant: height)]
        let playersDataConstaints = [player1Data.leadingAnchor.constraint(greaterThanOrEqualTo: player1FrameView.leadingAnchor, constant: constants.distanceForTextInFrame), player1Data.centerYAnchor.constraint(equalTo: player1FrameView.centerYAnchor), player2Data.leadingAnchor.constraint(greaterThanOrEqualTo: player2FrameView.leadingAnchor, constant: constants.distanceForTextInFrame), player2Data.centerYAnchor.constraint(equalTo: player2FrameView.centerYAnchor), player1Data.trailingAnchor.constraint(lessThanOrEqualTo: player1FrameView.trailingAnchor, constant: -constants.distanceForTextInFrame), player2Data.trailingAnchor.constraint(lessThanOrEqualTo: player2FrameView.trailingAnchor, constant: -constants.distanceForTextInFrame), player1Data.centerXAnchor.constraint(equalTo: player1FrameView.centerXAnchor), player2Data.centerXAnchor.constraint(equalTo: player2FrameView.centerXAnchor)]
        NSLayoutConstraint.activate(playersFramesViewConstraints + playersDataConstaints)
        if gameLogic.gameMode == .oneScreen {
            player2FrameView.transform = player2FrameView.transform.rotated(by: .pi)
        }
    }
    
    private func makePlayersTitles() {
        let width = min(view.frame.width, view.frame.height)  / constants.dividerForSquare * constants.widthDividerForTrash
        let height = min(view.frame.width, view.frame.height)  / constants.dividerForSquare * constants.heightDividerForTitle
        let player1Background = gameLogic.players.first!.playerBackground
        let player1Frame = gameLogic.players.first!.frame
        let player2Background = gameLogic.players.second!.playerBackground
        let player2Frame = gameLogic.players.second!.frame
        player1TitleView = PlayerFrame(frame: CGRect(x: 0, y: 0, width: width, height: height), background: player1Background, playerFrame: player1Frame)
        player2TitleView = PlayerFrame(frame: CGRect(x: 0, y: 0, width: width, height: height), background: player2Background, playerFrame: player2Frame)
        player1TitleView.translatesAutoresizingMaskIntoConstraints = false
        player2TitleView.translatesAutoresizingMaskIntoConstraints = false
        player1TitleView.backgroundColor = .clear
        player2TitleView.backgroundColor = .clear
        let player1Title = makeLabel(text: gameLogic.players.first!.title.rawValue.capitalizingFirstLetter().replacingOccurrences(of: "_", with: " "))
        let player2Title = makeLabel(text: gameLogic.players.second!.title.rawValue.capitalizingFirstLetter().replacingOccurrences(of: "_", with: " "))
        view.addSubview(player1TitleView)
        view.addSubview(player2TitleView)
        player1TitleView.addSubview(player1Title)
        player2TitleView.addSubview(player2Title)
        let playersTitlesViewConstraints = [player1TitleView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), player2TitleView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), player1TitleView.topAnchor.constraint(equalTo: player1FrameView.bottomAnchor, constant: constants.distanceForTitle), player2TitleView.bottomAnchor.constraint(equalTo: player2FrameView.topAnchor, constant: -constants.distanceForTitle), player1TitleView.widthAnchor.constraint(equalToConstant: width), player1TitleView.heightAnchor.constraint(equalToConstant: height), player2TitleView.widthAnchor.constraint(equalToConstant: width), player2TitleView.heightAnchor.constraint(equalToConstant: height)]
        let playersTitlesConstraints = [player1Title.leadingAnchor.constraint(equalTo: player1TitleView.leadingAnchor, constant: constants.distanceForTextInFrame), player1Title.centerYAnchor.constraint(equalTo: player1TitleView.centerYAnchor), player2Title.leadingAnchor.constraint(equalTo: player2TitleView.leadingAnchor, constant: constants.distanceForTextInFrame), player2Title.centerYAnchor.constraint(equalTo: player2TitleView.centerYAnchor), player1Title.trailingAnchor.constraint(equalTo: player1TitleView.trailingAnchor, constant: -constants.distanceForTextInFrame), player2Title.trailingAnchor.constraint(equalTo: player2TitleView.trailingAnchor, constant: -constants.distanceForTextInFrame)]
        NSLayoutConstraint.activate(playersTitlesViewConstraints + playersTitlesConstraints)
        if gameLogic.gameMode == .oneScreen {
            player2TitleView.transform = player2TitleView.transform.rotated(by: .pi)
        }
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
        view.addSubview(gameBoard)
        let gameBoardConstraints = [gameBoard.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), gameBoard.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor)]
        NSLayoutConstraint.activate(gameBoardConstraints)
    }
    
    private func makeDestroyedFiguresViews() {
        let player1Frame = UIImageView()
        let player2Frame = UIImageView()
        player1Frame.defaultSettings()
        player2Frame.defaultSettings()
        player1Frame.image = UIImage(named: "frames/\(gameLogic.players.first!.frame.rawValue)")
        player2Frame.image = UIImage(named: "frames/\(gameLogic.players.second!.frame.rawValue)")
        view.addSubview(player1Frame)
        view.addSubview(player2Frame)
        //in oneScreen second stack should be first, in other words upside down
        if gameLogic.gameMode == .oneScreen {
            player2Frame.transform = player2Frame.transform.rotated(by: .pi)
            destroyedFigures1 = makeDestroyedFiguresView(destoyedFigures1: player1DestroyedFigures2, destoyedFigures2: player1DestroyedFigures1, player2: true)
        }
        else if gameLogic.gameMode == .multiplayer{
            destroyedFigures1 = makeDestroyedFiguresView(destoyedFigures1: player1DestroyedFigures1, destoyedFigures2: player1DestroyedFigures2, player2: true)
        }
        destroyedFigures2 = makeDestroyedFiguresView(destoyedFigures1: player2DestroyedFigures1, destoyedFigures2: player2DestroyedFigures2)
        view.addSubview(destroyedFigures1)
        view.addSubview(destroyedFigures2)
        let playersFramesConstraints = [player1Frame.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.distanceForDestroyedFigures / 2), player2Frame.bottomAnchor.constraint(equalTo: gameBoard.topAnchor, constant: -constants.distanceForDestroyedFigures / 2), player1Frame.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), player2Frame.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), player1Frame.widthAnchor.constraint(equalTo: destroyedFigures1.widthAnchor, constant: constants.distanceForDestroyedFigures), player1Frame.heightAnchor.constraint(equalTo: destroyedFigures1.heightAnchor, constant: constants.distanceForDestroyedFigures), player2Frame.widthAnchor.constraint(equalTo: destroyedFigures2.widthAnchor, constant: constants.distanceForDestroyedFigures), player2Frame.heightAnchor.constraint(equalTo: destroyedFigures2.heightAnchor, constant: constants.distanceForDestroyedFigures)]
        let destroyedFiguresConstraints = [destroyedFigures1.bottomAnchor.constraint(equalTo: gameBoard.topAnchor, constant: -constants.distanceForDestroyedFigures), destroyedFigures2.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.distanceForDestroyedFigures), destroyedFigures1.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), destroyedFigures2.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor)]
        NSLayoutConstraint.activate(destroyedFiguresConstraints + playersFramesConstraints)
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
        square.rectangleView(width: min(view.frame.width, view.frame.height)  / constants.dividerForSquare * multiplier)
        //we are adding image in this way, so we can move figure separately from square
        if image != nil {
            let imageView = UIImageView()
            imageView.rectangleView(width: min(view.frame.width, view.frame.height)  / constants.dividerForSquare * multiplier)
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
        let destroyedFigures = UIImageView()
        destroyedFigures.defaultSettings()
        destroyedFigures.addSubview(destoyedFigures1)
        destroyedFigures.addSubview(destoyedFigures2)
        let destroyedFiguresConstraints1 = [destroyedFigures.widthAnchor.constraint(equalToConstant: min(view.frame.width, view.frame.height)  / constants.dividerForSquare * constants.widthDividerForTrash), destroyedFigures.heightAnchor.constraint(equalToConstant: min(view.frame.width, view.frame.height)  / constants.dividerForSquare * constants.heightDividerForTrash)]
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
        image = image?.alpha(constants.alphaForBackground)
        destroyedFigures.image = image
        return destroyedFigures
    }
    
}

private struct GameVC_Constants {
    static let defaultPlayerDataColor = UIColor.white
    static let currentPlayerDataColor = UIColor.green
    static let multiplierForBackground: CGFloat = 0.5
    static let alphaForBackground: CGFloat = 1
    static let distanceForFigureInTrash: CGFloat = 3
    static let multiplierForNumberView: CGFloat = 0.6
    static let distanceForDestroyedFigures: CGFloat = 20
    static let animationDuration = 0.5
    static let maxFiguresInTrashLine = 8
    static let dividerForFont: CGFloat = 13
    static let dividerForSquare: CGFloat = 11
    static let widthDividerForTrash: CGFloat = 8.5
    static let heightDividerForTrash: CGFloat = 2.5
    static let heightDividerForFrame: CGFloat = 1.5
    static let heightDividerForTitle: CGFloat = 0.8
    static let distanceForTitle: CGFloat = 1
    static let spacingForPlayerData: CGFloat = 5
    static let distanceForTextInFrame: CGFloat = 30
    static let keyNameForSquare = "Square"
    
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

