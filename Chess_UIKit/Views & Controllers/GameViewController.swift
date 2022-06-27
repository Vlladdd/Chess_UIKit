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
        constants.createThemes()
        theme = constants.getThemeView(with: gameLogic.gameBoard.theme.name)
        makeUI()
        updateUI()
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
                let figureImage = UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/\(figure.color.rawValue)_\(figure.name.rawValue)")
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
    
    private func showPawnPicker(square: Square, figureColor: GameColors) {
        makePawnPicker(figureColor: figureColor, squareColor: square.color)
        view.addSubview(pawnPicker)
        pawnPicker.backgroundColor = square.color == .black ? theme?.squareSecondColor : theme?.squareFirstColor
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
                    view.backgroundColor = theme?.turnColor
                }
                else {
                    switch square.color {
                    case .white:
                        view.backgroundColor = theme?.squareFirstColor
                    case .black:
                        view.backgroundColor = theme?.squareSecondColor
                    }
                }
                if gameLogic.pawnWizard {
                    view.isUserInteractionEnabled = false
                }
                else if gameLogic.currentPlayer.type == .player1 && square.figure?.color == .white {
                    view.isUserInteractionEnabled = true
                }
                else if gameLogic.currentPlayer.type == .player2 && square.figure?.color == .black{
                    view.isUserInteractionEnabled = true
                }
                else {
                    view.isUserInteractionEnabled = false
                }
                if gameLogic.pickedSquares.count == 1 {
                    if gameLogic.pickedSquares.contains(square) {
                        view.backgroundColor = theme?.pickColor
                    }
                    else if gameLogic.availableSquares.contains(square) {
                        view.backgroundColor = theme?.availableFieldsColor
                        view.isUserInteractionEnabled = true
                    }
                }
                if gameLogic.check {
                    if square.figure?.name == .king && square.figure?.color != gameLogic.turns.last?.squares.first?.figure?.color {
                        view.backgroundColor = theme?.checkColor
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
                self.moveFigureToTrash(imageView: secondSquareView)
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
                    self.moveFigureToTrash(imageView: thirdSquareView)
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
    
    private func moveFigureToTrash(imageView: UIImageView) {
        for subview in imageView.subviews {
            bringFigureToFront(view: imageView)
            if let subview = subview as? UIImageView {
                subview.image = subview.image?.rotate(radians: .pi)
            }
            var frame = CGRect.zero
            var xCoordinate: CGFloat = 0
            var yCoordinate: CGFloat = 0
            switch gameLogic.currentPlayer.type {
            case .player1:
                //we have 2 lines of trash figures
                if player1DestroyedFigures1.subviews.count == constants.maxFiguresInTrashLine {
                    frame = getFrameForAnimation(firstView: imageView, secondView: player1DestroyedFigures2)
                }
                else {
                    frame = getFrameForAnimation(firstView: imageView, secondView: player1DestroyedFigures1)
                }
                xCoordinate = frame.minX - imageView.bounds.maxX
                yCoordinate = frame.maxY - imageView.bounds.maxY
                //at the start StackView have height 0
                if player1DestroyedFigures1.subviews.count == constants.maxFiguresInTrashLine && player1DestroyedFigures2.subviews.isEmpty {
                    yCoordinate = frame.maxY - imageView.bounds.minY
                }
            case .player2:
                if player2DestroyedFigures1.subviews.count == constants.maxFiguresInTrashLine {
                    frame = getFrameForAnimation(firstView: imageView, secondView: player2DestroyedFigures2)
                }
                else {
                    frame = getFrameForAnimation(firstView: imageView, secondView: player2DestroyedFigures1)
                }
                xCoordinate = frame.maxX - imageView.bounds.minX
                yCoordinate = frame.minY - imageView.bounds.minY
                if player2DestroyedFigures1.subviews.count == constants.maxFiguresInTrashLine && player2DestroyedFigures2.subviews.isEmpty {
                    yCoordinate = frame.minY - imageView.bounds.maxY
                }
            }
            animateFigureToTrash(view: subview, x: xCoordinate, y: yCoordinate)
        }
    }
    
    private func animateFigureToTrash(view: UIView, x: CGFloat, y: CGFloat) {
        UIView.animate(withDuration: constants.animationDuration, animations: {
            view.transform = CGAffineTransform(translationX: x, y: y)
        }) {_ in
            view.transform = .identity
            switch self.gameLogic.currentPlayer.type {
            case .player1:
                if self.player1DestroyedFigures1.subviews.count == constants.maxFiguresInTrashLine {
                    //here we insert at 0, because stacks start from left side, but for player 2 they should start from right side
                    self.player1DestroyedFigures2.insertArrangedSubview(view, at: 0)
                }
                else {
                    self.player1DestroyedFigures1.insertArrangedSubview(view, at: 0)
                }
            case .player2:
                if self.player2DestroyedFigures1.subviews.count == constants.maxFiguresInTrashLine {
                    self.player2DestroyedFigures2.addArrangedSubview(view)
                }
                else {
                    self.player2DestroyedFigures1.addArrangedSubview(view)
                }
            }
        }
    }
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private var theme: ThemeView?
    
    private let pawnPicker = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
    private let gameBoard = UIStackView(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: 0)
    //2 stacks for destroyed figures, 8 figures each
    private let player1DestroyedFigures1 = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
    private let player1DestroyedFigures2 = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
    private let player2DestroyedFigures1 = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
    private let player2DestroyedFigures2 = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
    
    private var squares = [UIImageView]()
    
    //letters line on top and bottom of the board
    private var lettersLine: UIStackView {
        let lettersLine = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        if traitCollection.userInterfaceStyle == .light || !gameLogic.gameBoard.theme.darkMode{
            lettersLine.addArrangedSubview(getSquareView(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter")))
            for column in GameBoard.availableColumns {
                lettersLine.addArrangedSubview(getSquareView(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter_\(column.rawValue)")))
            }
            lettersLine.addArrangedSubview(getSquareView(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter")))
        }
        else {
            lettersLine.addArrangedSubview(getSquareView(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter_dark")))
            for column in GameBoard.availableColumns {
                lettersLine.addArrangedSubview(getSquareView(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter_\(column.rawValue)_dark")))
            }
            lettersLine.addArrangedSubview(getSquareView(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter_dark")))
        }
        return lettersLine
    }
    
    // MARK: - UI Methods
    
    private func makeUI() {
        if traitCollection.userInterfaceStyle == .dark {
            view.backgroundColor = .black
        } else {
            view.backgroundColor = .white
        }
        makeGameBoard()
    }
    
    private func makeGameBoard() {
        let destroyedFigures1 = makeDestroyedFiguresView(destoyedFigures1: player1DestroyedFigures2, destoyedFigures2: player1DestroyedFigures1, player2: true)
        let destroyedFigures2 = makeDestroyedFiguresView(destoyedFigures1: player2DestroyedFigures1, destoyedFigures2: player2DestroyedFigures2)
        let gameBoardBackground = UIImageView(cornerRadius: constants.cornerRadius)
        gameBoardBackground.image = theme?.image
        let lettersLineTop = lettersLine
        //upside down for player 2
        for subview in lettersLineTop.arrangedSubviews {
            subview.transform = subview.transform.rotated(by: .pi)
        }
        gameBoard.addArrangedSubview(lettersLineTop)
        configureGameBoard()
        gameBoard.addArrangedSubview(lettersLine)
        view.addSubview(gameBoardBackground)
        view.addSubview(gameBoard)
        view.addSubview(destroyedFigures1)
        view.addSubview(destroyedFigures2)
        let gameBoardConstraints = [destroyedFigures1.bottomAnchor.constraint(equalTo: gameBoard.topAnchor, constant: -constants.distanceForDestroyedFigures), destroyedFigures2.topAnchor.constraint(equalTo: gameBoard.bottomAnchor, constant: constants.distanceForDestroyedFigures), destroyedFigures1.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), destroyedFigures2.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), gameBoardBackground.topAnchor.constraint(equalTo: view.topAnchor), gameBoardBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor), gameBoardBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor), gameBoardBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor), gameBoard.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), gameBoard.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor)]
        NSLayoutConstraint.activate(gameBoardConstraints)
    }
    
    private func configureGameBoard() {
        for coordinate in GameBoard.availableRows.sorted(by: >) {
            //line contains number at the start and end and 8 squares
            let line = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
            line.addArrangedSubview(getNumberSquareView(number: coordinate))
            for column in GameBoard.availableColumns {
                if let square = gameLogic.gameBoard[column, coordinate] {
                    var figureImage: UIImage?
                    if let figure = square.figure {
                        figureImage = UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/\(figure.color.rawValue)_\(figure.name.rawValue)")
                    }
                    //we are not using transform here to not have problems with animation
                    if square.figure?.color == .black {
                        figureImage = figureImage?.rotate(radians: .pi)
                    }
                    let squareView = getSquareView(image: figureImage)
                    switch square.color {
                    case .white:
                        squareView.backgroundColor = theme?.squareFirstColor
                    case .black:
                        squareView.backgroundColor = theme?.squareSecondColor
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
        let square = UIImageView(width: min(view.frame.width, view.frame.height)  / GameVC_Constants.dividerForSquare * multiplier)
        //we are adding image in this way, so we can move figure separately from square
        if image != nil {
            let imageView = UIImageView(width: min(view.frame.width, view.frame.height)  / GameVC_Constants.dividerForSquare * multiplier)
            imageView.layer.borderWidth = 0
            imageView.image = image
            square.addSubview(imageView)
        }
        return square
    }
    
    //according to current design, we need to make number image smaller
    private func getNumberSquareView(number: Int) -> UIImageView {
        var square = UIImageView()
        if traitCollection.userInterfaceStyle == .light || !gameLogic.gameBoard.theme.darkMode{
            square = getSquareView(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter"))
        } else {
            square = getSquareView(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter_dark"))
        }
        let numberView = getSquareView(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/number_\(number)"), multiplier: constants.multiplierForNumberView)
        numberView.layer.borderWidth = 0
        square.addSubview(numberView)
        let numberViewConstraints = [numberView.centerXAnchor.constraint(equalTo: square.centerXAnchor), numberView.centerYAnchor.constraint(equalTo: square.centerYAnchor)]
        NSLayoutConstraint.activate(numberViewConstraints)
        return square
    }
    
    private func makeLabel(text: String) -> UILabel {
        return UILabel(text: text, alignment: .center, font: UIFont.systemFont(ofSize: view.frame.width / GameVC_Constants.dividerForFont))
    }
    
    private func makePawnPicker(figureColor: GameColors, squareColor: GameColors) {
        let figures: [Figures] = [.rook, .queen, .bishop, .knight]
        for figure in figures {
            //just random square, it doesnt matter
            let square = Square(column: .A, row: 1, color: .white, figure: Figure(name: figure, color: figureColor))
            let figureImage = UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/\(figureColor.rawValue)_\(figure.rawValue)")
            let squareView = getSquareView(image: figureImage)
            squareView.layer.setValue(square, forKey: constants.keyNameForSquare)
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.replacePawn(_:)))
            squareView.addGestureRecognizer(tap)
            squareView.layer.borderColor = squareColor == .black ? UIColor.white.cgColor : UIColor.black.cgColor
            pawnPicker.addArrangedSubview(squareView)
        }
    }

    private func makeDestroyedFiguresView(destoyedFigures1: UIStackView, destoyedFigures2: UIStackView, player2: Bool = false) -> UIView {
        let destroyedFigures = UIImageView(cornerRadius: constants.cornerRadius)
        destroyedFigures.addSubview(destoyedFigures1)
        destroyedFigures.addSubview(destoyedFigures2)
        let destroyedFiguresConstraints1 = [destroyedFigures.widthAnchor.constraint(equalToConstant: min(view.frame.width, view.frame.height)  / GameVC_Constants.dividerForSquare * constants.widthDividerForTrash), destroyedFigures.heightAnchor.constraint(equalToConstant: min(view.frame.width, view.frame.height)  / GameVC_Constants.dividerForSquare * constants.heightDividerForTrash)]
        let destroyedFiguresConstraints2 = [destoyedFigures1.topAnchor.constraint(equalTo: destroyedFigures.topAnchor, constant: constants.distanceForFigureInTrash), destoyedFigures2.bottomAnchor.constraint(equalTo: destroyedFigures.bottomAnchor, constant: -constants.distanceForFigureInTrash)]
        var destroyedFiguresConstraints3: [NSLayoutConstraint] = []
        //here we add this, because stacks start from left side, but for player 2 they should start from right side
        if player2 {
            destroyedFiguresConstraints3 = [destoyedFigures1.trailingAnchor.constraint(equalTo: destroyedFigures.trailingAnchor), destoyedFigures2.trailingAnchor.constraint(equalTo: destroyedFigures.trailingAnchor)]
        }
        NSLayoutConstraint.activate(destroyedFiguresConstraints1 + destroyedFiguresConstraints2 + destroyedFiguresConstraints3)
        if let theme = theme {
            let image = theme.image?.alpha(constants.alphaForBackground)
            destroyedFigures.image = image
        }
        return destroyedFigures
    }
    
}

private struct GameVC_Constants {
    static let alphaForBackground: CGFloat = 1
    static let distanceForFigureInTrash: CGFloat = 3
    static let multiplierForNumberView: CGFloat = 0.6
    static let distanceForDestroyedFigures: CGFloat = 20
    static let animationDuration = 0.5
    static let maxFiguresInTrashLine = 8
    static let cornerRadius: CGFloat = 10
    static let dividerForFont: CGFloat = 13
    static let dividerForSquare: CGFloat = 11
    static let widthDividerForTrash: CGFloat = 8.5
    static let heightDividerForTrash: CGFloat = 2.5
    static let keyNameForSquare = "Square"
    
    static private var themes: [ThemeView] = []
    
    static func createThemes() {
        let defaultTheme = ThemeView(name: .defaultTheme, squareFirstColor: .white, squareSecondColor: .black, pickColor: .red, availableFIeldsColor: .green, turnColor: .orange, checkColor: .blue, image: UIImage(named: "defaultTheme/board"))
        themes.append(defaultTheme)
    }
    
    //in case if need to use theme as a view
    static func getThemeView(with name: Themes) -> ThemeView? {
        let theme = themes.first(where: {$0.name == name})
        if let theme = theme {
            //ThemeView is a class
            let newElement = ThemeView(name: theme.name, squareFirstColor: theme.squareFirstColor, squareSecondColor: theme.squareSecondColor, pickColor: theme.pickColor, availableFIeldsColor: theme.availableFieldsColor, turnColor: theme.turnColor, checkColor: theme.checkColor, image: theme.image)
            return newElement
        }
        return nil
    }
}

