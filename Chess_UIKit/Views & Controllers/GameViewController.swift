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
        // Do any additional setup after loading the view.
    }
    
    // MARK: - Properties
    
    private let gameLogic = GameLogic()
    
    // MARK: - User Initiated Methods
    
    @objc func makeTurn(_ sender: UITapGestureRecognizer? = nil) {
        if let square = sender?.view?.layer.value(forKey: "Square") as? Square {
            gameLogic.makeTurn(square: square, completion: updateUI)
        }
    }
    
    // MARK: - Local Methods
    
    // updates Ui after player turn
    private func updateUI() {
        for view in squares {
            if let square = view.layer.value(forKey: "Square") as? Square {
                if let turn = gameLogic.turns.last, turn.squares.contains(square) {
                    view.backgroundColor = .orange
                }
                else {
                    switch square.color {
                    case .white:
                        view.backgroundColor = .white
                    case .black:
                        view.backgroundColor = .black
                    }
                }
                view.isUserInteractionEnabled = false
                if gameLogic.currentPlayer == .player1 && square.figure?.color == .white {
                    view.isUserInteractionEnabled = true
                }
                else if gameLogic.currentPlayer == .player2 && square.figure?.color == .black{
                    view.isUserInteractionEnabled = true
                }
                if gameLogic.pickedSquares.count == 1 {
                    if gameLogic.pickedSquares.contains(square) {
                        view.backgroundColor = .red
                    }
                    else if gameLogic.availableSquares.contains(square) {
                        view.backgroundColor = .green
                        view.isUserInteractionEnabled = true
                    }
                }
            }
        }
        if gameLogic.pickedSquares.count > 1 {
            if let turn = gameLogic.turns.last{
                for square in squares {
                    square.isUserInteractionEnabled = false
                }
                let firstSquareView = squares.first(where: {$0.layer.value(forKey: "Square") as? Square == turn.squares[0]})
                let secondSquareView = squares.first(where: {$0.layer.value(forKey: "Square") as? Square == turn.squares[1]})
                let square = gameLogic.gameBoard.squares.first(where: {$0 == gameLogic.pickedSquares[1]})
                // if en passant
                var pawnSquare: Square?
                var thirdSquareView: UIImageView?
                if gameLogic.pickedSquares.count == 3 {
                    thirdSquareView = squares.first(where: {$0.layer.value(forKey: "Square") as? Square == gameLogic.pickedSquares[2]})
                    pawnSquare = gameLogic.pickedSquares[2]
                    pawnSquare?.figure = nil
                }
                if let firstSquareView = firstSquareView, let secondSquareView = secondSquareView {
                    // we need to move figure image to the top
                    let verticalStackView = firstSquareView.superview?.superview
                    let horizontalStackView = firstSquareView.superview
                    if let verticalStackView = verticalStackView, let horizontalStackView = horizontalStackView {
                        view.bringSubviewToFront(verticalStackView)
                        verticalStackView.bringSubviewToFront(horizontalStackView)
                        horizontalStackView.bringSubviewToFront(firstSquareView)
                    }
                    firstSquareView.bringSubviewToFront(firstSquareView.subviews[0])
                    let frame = firstSquareView.convert(secondSquareView.bounds, from: secondSquareView)
                    // turn animation
                    UIView.animate(withDuration: 0.5, animations: {
                        for subview in firstSquareView.subviews {
                            subview.transform = CGAffineTransform(translationX: frame.minX - firstSquareView.bounds.minX, y: frame.minY - firstSquareView.bounds.minY)
                        }
                    }) { [weak self] _ in
                        for subview in secondSquareView.subviews {
                            subview.removeFromSuperview()
                        }
                        for subview in firstSquareView.subviews {
                            subview.transform = .identity
                            secondSquareView.addSubview(subview)
                            let imageViewConstraints = [subview.centerXAnchor.constraint(equalTo: secondSquareView.centerXAnchor), subview.centerYAnchor.constraint(equalTo: secondSquareView.centerYAnchor)]
                            NSLayoutConstraint.activate(imageViewConstraints)
                        }
                        if let square = square {
                            secondSquareView.layer.setValue(square, forKey: "Square")
                        }
                        if let self = self {
                            if let thirdSquareView = thirdSquareView, let pawnSquare = pawnSquare {
                                thirdSquareView.layer.setValue(pawnSquare, forKey: "Square")
                                for subview in thirdSquareView.subviews {
                                    subview.removeFromSuperview()
                                }
                            }
                            self.updateUI()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private var squares = [UIImageView]()
    
    private var lettersLine: UIStackView {
        let lettersLine = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
        if traitCollection.userInterfaceStyle == .light || !gameLogic.gameBoard.theme.darkMode{
            lettersLine.addArrangedSubview(getSquare(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter")))
            for column in GameBoard.availableColumns {
                lettersLine.addArrangedSubview(getSquare(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter_\(column.rawValue)")))
            }
            lettersLine.addArrangedSubview(getSquare(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter")))
        }
        else {
            lettersLine.addArrangedSubview(getSquare(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter_dark")))
            for column in GameBoard.availableColumns {
                lettersLine.addArrangedSubview(getSquare(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter_\(column.rawValue)_dark")))
            }
            lettersLine.addArrangedSubview(getSquare(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter_dark")))
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
        let gameBoard = UIStackView(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: 0)
        let gameBoardBackground = UIImageView()
        gameBoardBackground.translatesAutoresizingMaskIntoConstraints = false
        gameBoard.addArrangedSubview(lettersLine)
        for coordinate in GameBoard.availableRows {
            // line contains number at the start and end and 8 squares
            let line = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: 0)
            line.addArrangedSubview(getNumberSquare(number: coordinate))
            for column in GameBoard.availableColumns {
                if let square = gameLogic.gameBoard[column, coordinate] {
                    var figureImage: UIImage?
                    if let figure = square.figure {
                        figureImage = UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/\(figure.color.rawValue)_\(figure.name.rawValue)")
                    }
                    let squareView = getSquare(image: figureImage)
                    switch square.color {
                    case .white:
                        squareView.backgroundColor = .white
                    case .black:
                        squareView.backgroundColor = .black
                    }
                    squareView.layer.setValue(square, forKey: "Square")
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.makeTurn(_:)))
                    squareView.addGestureRecognizer(tap)
                    squares.append(squareView)
                    line.addArrangedSubview(squareView)
                }
            }
            line.addArrangedSubview(getNumberSquare(number: coordinate))
            gameBoard.addArrangedSubview(line)
        }
        gameBoard.addArrangedSubview(lettersLine)
        gameBoardBackground.image = UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/board")
        gameBoardBackground.contentMode = .scaleAspectFill
        view.addSubview(gameBoardBackground)
        view.addSubview(gameBoard)
        let gameBoardConstraints = [gameBoardBackground.topAnchor.constraint(equalTo: view.topAnchor), gameBoardBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor), gameBoardBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor), gameBoardBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor), gameBoard.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), gameBoard.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor)]
        NSLayoutConstraint.activate(gameBoardConstraints)
    }
    
    private func getSquare(image: UIImage? = nil, multiplier: CGFloat = 1) -> UIImageView {
        let square = UIImageView(width: min(view.frame.width, view.frame.height)  / GameVC_Constants.dividerForSquare * multiplier)
        // we are adding image in this way, so we can move figure separately from square
        if image != nil {
            let imageView = UIImageView(width: min(view.frame.width, view.frame.height)  / GameVC_Constants.dividerForSquare * multiplier)
            imageView.layer.borderWidth = 0
            imageView.image = image
            square.addSubview(imageView)
        }
        return square
    }
    
    private func getNumberSquare(number: Int) -> UIImageView {
        var square = UIImageView()
        if traitCollection.userInterfaceStyle == .light || !gameLogic.gameBoard.theme.darkMode{
            square = getSquare(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter"))
        } else {
            square = getSquare(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/letter_dark"))
        }
        let numberView = getSquare(image: UIImage(named: "\(gameLogic.gameBoard.theme.name.rawValue)/number_\(number)"), multiplier: 0.6)
        numberView.layer.borderWidth = 0
        square.addSubview(numberView)
        let numberViewConstraints = [numberView.centerXAnchor.constraint(equalTo: square.centerXAnchor), numberView.centerYAnchor.constraint(equalTo: square.centerYAnchor)]
        NSLayoutConstraint.activate(numberViewConstraints)
        return square
    }
    
    private func makeLabel(text: String) -> UILabel {
        return UILabel(text: text, alignment: .center, font: UIFont.systemFont(ofSize: view.frame.width / GameVC_Constants.dividerForFont))
    }
    
}

private struct GameVC_Constants {
    static let dividerForFont: CGFloat = 13
    static let dividerForSquare: CGFloat = 11
}

