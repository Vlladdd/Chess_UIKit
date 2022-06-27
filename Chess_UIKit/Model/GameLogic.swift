//
//  GameLogic.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.06.2022.
//

import Foundation

//class that represents logic of the game
class GameLogic {
    
    // MARK: - Properties
    
    private(set) var gameBoard = GameBoard()
    //stores picked squares by player
    private(set) var pickedSquares = [Square]()
    private(set) var turns = [Turn]()
    private(set) var currentPlayer: Player
    //stores available squares for picked figure
    private(set) var availableSquares = [Square]()
    //when current player made check
    private(set) var check = false
    //when pawn reached last row and is about to transform
    private(set) var pawnWizard = false
    //when last turn was short or long castle
    private(set) var shortCastle = false
    private(set) var longCastle = false
    //pawn to be destroyed after en passant
    private(set) var pawnSquare: Square?
    
    private var players: [Player]
    //if after player will move current picked figure, there will be check
    //in other words this figure blocking check
    private var possibleCheck = false
    //where we can move to destroy en passant pawn
    private var enPassantSquares = [Square]()
    //squares, to which king can`t move
    private var checkSquares = [Square]()
    //square, where the figure which made check placed
    private var checkSquare: Square?
    //if there is a check, we need to know where we can move to block it
    private var blockFromCheckSquares = [Square]()
    //same, but for possible check
    private var blockFromPossibleCheckSquares = [Square]()
    //this variable made only for pawn, because king actually can move on available fields for pawn, but
    //can`t move on diagonal fields of pawn, so we need to check it in other way
    private var checkingKingSquares = false
    //when we check available squares after check, we can eat a figure, because figure can`t eat same color figure,
    //so this square will not be available for her, but we need to make him available,
    //so we can check, if a king can actually eat a figure, which made check
    private var checkingKingSquaresWhenCheck = false
    private var gameEnded = false
    private var winner: Player?
    private var draw = false
    
    private typealias constants = GameLogic_Constants
    
    // MARK: - Inits
    
    init() {
        players = [Player(name: "Player1", type: .player1), Player(name: "Player2", type: .player2)]
        currentPlayer = players.first!
    }
    
    // MARK: - Methods
    
    func makeTurn(square: Square) {
        if pawnWizard {
            transformPawn(into: square.figure)
        }
        else if pickedSquares.isEmpty {
            pickSquare(square)
        }
        else if pickedSquares.count == 1 && !pickedSquares.contains(square){
            if availableSquares.contains(square) || shortCastle || longCastle {
                pickedSquares.append(square)
                turns.append(Turn(squares: pickedSquares))
                gameBoard.updateSquares(firstSquare: pickedSquares.first!, secondSquare: pickedSquares.second!)
                checkForRealCheck(color: pickedSquares.first!.figure!.color)
                if pickedSquares.first!.figure!.name == .pawn && constants.lastRowsForPawn.contains(pickedSquares.second!.row) {
                    pawnWizard = true
                }
                if enPassantSquares.contains(square) {
                    destroyEnPassantPawn()
                }
                if currentPlayer.longCastleAvailable || currentPlayer.shortCastleAvailable {
                    checkForCastle()
                }
                if !shortCastle && !longCastle {
                    currentPlayer = currentPlayer == players.first! ? players.second! : players.first!
                }
            }
            //player picks other own figure
            else {
                pickedSquares.removeAll()
                pickSquare(square)
            }
        }
        //player unpicks figure
        else {
            if let index = pickedSquares.firstIndex(of: square) {
                pickedSquares.remove(at: index)
            }
        }
    }
    
    //checks if current player made castle or move king or rook, so castle
    //is no longer available for him
    private func checkForCastle() {
        if let index = players.firstIndex(of: currentPlayer) {
            if pickedSquares.first!.figure?.name == .king {
                if pickedSquares.second!.column == constants.kingColumnForLongCastle {
                    longCastle = true
                }
                else if pickedSquares.second!.column == constants.kingColumnForShortCastle {
                    shortCastle = true
                }
                players[index].updateCastleInfo(short: false, long: false)
            }
            if pickedSquares.first!.figure?.name == .rook {
                if pickedSquares.first!.column == constants.leftRookStartColumn {
                    players[index].updateCastleInfo(short: false)
                }
                else {
                    players[index].updateCastleInfo(long: false)
                }
            }
            currentPlayer = players[index]
        }
        if shortCastle || longCastle {
            makeCastle()
        }
    }
    
    //transforms pawn, when he reached last row
    private func transformPawn(into figure: Figure?) {
        gameBoard.updateSquare(square: turns.last!.squares.second!, figure: figure)
        pawnWizard = false
        checkForRealCheck(color: turns.last!.squares.second!.color)
    }
    
    private func pickSquare(_ square: Square) {
        pickedSquares.append(square)
        findAvailableSquares(square)
    }
    
    private func findAvailableSquares(_ square: Square) {
        checkForPossibleCheck(square: square, color: square.figure?.color == .black ? .white : .black)
        calculateAvailableSquares(square: square)
        filterAvailableSquares(square: square)
    }
    
    func makeCastle() {
        let row = pickedSquares.first!.figure?.color == .black ? constants.rowForBlackCastle : constants.rowForWhiteCastle
        pickedSquares.removeAll()
        if shortCastle {
            moveRookToCastle(startColumn: constants.columnsForRookShortCastle.first!, endColumn: constants.columnsForRookShortCastle.second!, row: row)
        }
        else if longCastle {
            moveRookToCastle(startColumn: constants.columnsForRookLongCastle.first!, endColumn: constants.columnsForRookLongCastle.second!, row: row)
        }
        currentPlayer = currentPlayer == players.first! ? players.second! : players.first!
    }
    
    //moves rook, when castle
    private func moveRookToCastle(startColumn: BoardFiles, endColumn: BoardFiles, row: Int) {
        let startSquare = gameBoard[startColumn, row ]
        let endSquare = gameBoard[endColumn, row ]
        if let startSquare = startSquare, let endSquare = endSquare {
            makeTurn(square: startSquare)
            makeTurn(square: endSquare)
        }
    }
    
    //when en passant (only), the pawn we are about to destroy is on another square, not on that one where we will go,
    //so we need to calculate this and also add that square to pickedSquares for proper UI update
    private func destroyEnPassantPawn() {
        if let figure = pickedSquares.first!.figure {
            //pawns can only move forward, but according to game board coordinates black pawn will move down
            //and white pawn will move up, so distance between new pawn square and old pawn square
            //will be calculated diferently
            let rowDistance = figure.color == .black ? constants.minimumDistance : -constants.minimumDistance
            pawnSquare = gameBoard.squares.first(where: {$0.column == pickedSquares.second!.column && $0.row == pickedSquares.second!.row + rowDistance})
            pawnSquare?.figure = nil
            if let pawnSquare = pawnSquare {
                gameBoard.updateSquare(square: pawnSquare)
            }
        }
        enPassantSquares.removeAll()
    }
    
    //calculates squares where picked figure can be moved
    private func calculateAvailableSquares(square: Square) {
        availableSquares = []
        if let currentFigure = square.figure {
            switch currentFigure.name {
            case .pawn:
                calculateAvailableSquaresForPawn(currentSquare: square, currentFigure: currentFigure)
            case .rook:
                calculateAvailableSquaresForRook(currentSquare: square, currentFigure: currentFigure)
            case .knight:
                calculateAvailableSquaresForKnight(currentSquare: square, currentFigure: currentFigure)
            case .bishop:
                calculateAvailableSquaresForBishop(currentSquare: square, currentFigure: currentFigure)
            case .queen:
                calculateAvailableSquaresForQueen(currentSquare: square, currentFigure: currentFigure)
            case .king:
                calculateAvailableSquaresForKing(currentSquare: square, currentFigure: currentFigure)
            }
        }
    }
    
    //filters available squares based on the situation
    private func filterAvailableSquares(square: Square) {
        if let currentFigure = square.figure {
            if currentFigure.name == .king {
                availableSquares = availableSquares.filter({!checkSquares.contains($0)})
            }
            //if check and possible check at the same time, that means we can`t move picked figure anywhere
            else if check && possibleCheck && blockFromPossibleCheckSquares.contains(square) {
                availableSquares = []
            }
            else if check {
                availableSquares = availableSquares.filter({blockFromCheckSquares.contains($0) || $0 == checkSquare})
            }
            else if possibleCheck && blockFromPossibleCheckSquares.contains(square) {
                availableSquares = availableSquares.filter({blockFromPossibleCheckSquares.contains($0) || $0 == checkSquare})
            }
        }
    }
    
    // MARK: - Logic of figures
    
    // MARK: - Pawn
    
    private func calculateAvailableSquaresForPawn(currentSquare: Square, currentFigure: Figure) {
        let rowDistance = currentFigure.color == .white ? constants.minimumDistance : -constants.minimumDistance
        if !checkingKingSquares {
            availableSquares += gameBoard.squares.filter({$0.row - currentSquare.row == rowDistance && $0.column == currentSquare.column && $0.figure == nil})
            //if pawn at the start position and not blocked
            if !availableSquares.isEmpty  && constants.startRowsForPawn.contains(currentSquare.row) {
                availableSquares += gameBoard.squares.filter({$0.row - currentSquare.row == rowDistance * 2 && $0.column == currentSquare.column && $0.figure == nil})
            }
        }
        for square in gameBoard.squares {
            //pawn can only check diagonally
            if checkingKingSquares {
                if square.row == currentSquare.row + rowDistance && abs(square.column.index - currentSquare.column.index) == constants.minimumDistance {
                    availableSquares.append(square)
                }
            }
            //or eat figures
            else if let figure = square.figure, figure.color != currentFigure.color {
                if square.row == currentSquare.row + rowDistance && abs(square.column.index - currentSquare.column.index) == constants.minimumDistance {
                    availableSquares.append(square)
                }
                //except en passant case, where the figure, which is going to be eaten is left or right from current one
                if abs(square.column.index - currentSquare.column.index) == constants.minimumDistance && square.row == currentSquare.row {
                    if figure.name == .pawn && figure.color != currentFigure.color {
                        if let turn = turns.last, turn.squares.contains(square) && turn.squares.second!.row - turn.squares.first!.row == -rowDistance * 2  {
                            let enPassantSquare = gameBoard.squares.first(where: {$0.column == square.column && $0.row == square.row + rowDistance})
                            if let enPassantSquare = enPassantSquare {
                                availableSquares.append(enPassantSquare)
                                enPassantSquares.append(enPassantSquare)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Rook
    
    private func calculateAvailableSquaresForRook(currentSquare: Square, currentFigure: Figure) {
        var horizontalSquares = gameBoard.squares.filter({$0.column == currentSquare.column && $0 != currentSquare})
        var verticalSquares = gameBoard.squares.filter({$0.row == currentSquare.row && $0 != currentSquare})
        for square in horizontalSquares + verticalSquares {
            if square.figure != nil {
                if square.column == currentSquare.column {
                    horizontalSquares = rookHelperHorizontal(squares: horizontalSquares, square: square, currentSquare: currentSquare)
                }
                else if square.row == currentSquare.row {
                    verticalSquares = rookHelperVertical(squares: verticalSquares, square: square, currentSquare: currentSquare)
                }
            }
            //removes squares with own figures
            if square.figure?.color == currentSquare.figure?.color && !checkingKingSquaresWhenCheck {
                if let index = horizontalSquares.firstIndex(of: square) {
                    horizontalSquares.remove(at: index)
                }
                else if let index = verticalSquares.firstIndex(of: square) {
                    verticalSquares.remove(at: index)
                }
            }
        }
        availableSquares += horizontalSquares + verticalSquares
    }
    
    private func rookHelperHorizontal(squares: [Square], square: Square, currentSquare: Square) -> [Square] {
        let operation: (Int,Int) -> Bool = square.row < currentSquare.row ? (>=) : (<=)
        return squares.filter({operation($0.row, square.row) && $0.column == currentSquare.column})
    }
    
    private func rookHelperVertical(squares: [Square], square: Square, currentSquare: Square) -> [Square] {
        let operation: (BoardFiles,BoardFiles) -> Bool = square.column < currentSquare.column ? (>=) : (<=)
        return squares.filter({operation($0.column, square.column) && $0.row == currentSquare.row})
    }
    
    // MARK: - Knight
    
    private func calculateAvailableSquaresForKnight(currentSquare: Square, currentFigure: Figure) {
        availableSquares += gameBoard.squares.filter({abs(currentSquare.column.index - $0.column.index) == constants.minimumDistance && abs(currentSquare.row - $0.row) == constants.minimumDistance * 2})
        availableSquares += gameBoard.squares.filter({abs(currentSquare.column.index - $0.column.index) == constants.minimumDistance * 2 && abs(currentSquare.row - $0.row) == constants.minimumDistance})
        availableSquares = availableSquares.filter({$0.figure?.color != currentFigure.color})
    }
    
    // MARK: - Bishop
    
    private func calculateAvailableSquaresForBishop(currentSquare: Square, currentFigure: Figure) {
        let squares = gameBoard.squares.filter({abs(currentSquare.row - $0.row) == abs(currentSquare.column.index - $0.column.index)})
        var leftDiagonale = squares.filter({$0.column < currentSquare.column})
        var rightDiagonale = squares.filter({$0.column > currentSquare.column})
        for square in leftDiagonale {
            if square.figure != nil {
                leftDiagonale = bishopHelper(squares: leftDiagonale, square: square, currentSquare: currentSquare)
            }
        }
        for square in rightDiagonale {
            if square.figure != nil {
                rightDiagonale = bishopHelper(squares: rightDiagonale, square: square, currentSquare: currentSquare)
            }
        }
        availableSquares += leftDiagonale + rightDiagonale
        if !checkingKingSquaresWhenCheck {
            for square in availableSquares {
                if square.figure?.color == currentSquare.figure?.color {
                    if let index = availableSquares.firstIndex(of: square) {
                        availableSquares.remove(at: index)
                    }
                }
            }
        }
    }
    
    private func bishopHelper(squares: [Square], square: Square, currentSquare: Square) -> [Square] {
        let operation: (Int,Int) -> Bool = square.row < currentSquare.row ? (>=) : (<=)
        return squares.filter({operation($0.row, square.row)})
    }
    
    // MARK: - Queen
    
    private func calculateAvailableSquaresForQueen(currentSquare: Square, currentFigure: Figure) {
        calculateAvailableSquaresForRook(currentSquare: currentSquare, currentFigure: currentFigure)
        calculateAvailableSquaresForBishop(currentSquare: currentSquare, currentFigure: currentFigure)
    }
    
    // MARK: - King
    
    private func calculateAvailableSquaresForKing(currentSquare: Square, currentFigure: Figure) {
        availableSquares = gameBoard.squares.filter({abs($0.row - currentSquare.row) <= constants.minimumDistance && abs($0.column.index - currentSquare.column.index) <= constants.minimumDistance && $0 != currentSquare})
        availableSquares = availableSquares.filter({$0.figure?.color != currentFigure.color})
        let row = currentFigure.color == .black ? constants.rowForBlackCastle : constants.rowForWhiteCastle
        //adds additional square for short castle, if all conditions met
        if currentPlayer.shortCastleAvailable && !check {
            let firstCondition = gameBoard[constants.leftRookStartColumn, row]?.figure != nil
            let secondCondition = gameBoard[constants.leftKnightStartColumn, row]?.figure == nil
            let thirdCondition = gameBoard[constants.leftBishopStartColumn, row]?.figure == nil
            if firstCondition && secondCondition && thirdCondition {
                if let square = gameBoard[.B, row] {
                    availableSquares.append(square)
                }
            }
        }
        //adds additional square for long castle, if all conditions met
        if currentPlayer.longCastleAvailable && !check {
            let firstCondition = gameBoard[constants.queenStartColumn, row]?.figure == nil
            let secondCondition = gameBoard[constants.rightBishopStartColumn, row]?.figure == nil
            let thirdCondition = gameBoard[constants.rightRookStartColumn, row]?.figure != nil
            let fourthCondition = gameBoard[constants.rightKnightStartColumn, row]?.figure == nil
            if firstCondition && secondCondition && thirdCondition && fourthCondition {
                if let square = gameBoard[.F, row] {
                    availableSquares.append(square)
                }
            }
        }
        //king can`t eat other king :D
        availableSquares = availableSquares.filter({$0.figure?.name != .king})
    }
    
    // MARK: - Check
    
    private func checkForRealCheck(color: GameColors) {
        blockFromCheckSquares = []
        checkingKingSquares = true
        check = false
        blockFromCheckSquares = checkForCheck(color: color)
        if checkSquares.contains(where: {$0.figure?.name == .king}) {
            check = true
            checkForEndGame()
        }
        else {
            checkForPat()
        }
    }
    
    private func checkForPossibleCheck(square: Square, color: GameColors) {
        blockFromPossibleCheckSquares = []
        possibleCheck = false
        if square.figure?.name == .king {
            checkingKingSquaresWhenCheck = true
        }
        //removes figure from board to simulate available squares without her
        gameBoard.updateSquare(square: square)
        blockFromPossibleCheckSquares = checkForCheck(color: color)
        gameBoard.updateSquare(square: square, figure: square.figure)
        if checkSquares.contains(where: {$0.figure?.name == .king}) {
            possibleCheck = true
        }
    }
    
    private func checkForCheck(color: GameColors) -> [Square] {
        availableSquares = []
        checkSquares = []
        checkSquare = nil
        var blockedSquares = [Square]()
        for square in gameBoard.squares {
            if let figure = square.figure, figure.color == color {
                calculateAvailableSquares(square: square)
                checkSquares += availableSquares
                if availableSquares.contains(where: {$0.figure?.name == .king}) {
                    let kingSquare = availableSquares.first(where: {$0.figure?.name == .king})
                    if let kingSquare = kingSquare {
                        switch figure.name {
                        case .pawn:
                            blockedSquares += []
                        case .rook:
                            blockedSquares += findBlockedSquaresForRook(square: square, kingSquare: kingSquare)
                        case .knight:
                            blockedSquares += []
                        case .bishop:
                            blockedSquares += findBlockedSquaresForBishop(square: square, kingSquare: kingSquare)
                        case .queen:
                            blockedSquares += findBlockedSquaresForQueen(square: square, kingSquare: kingSquare)
                        case .king:
                            blockedSquares += []
                        }
                        checkSquare = square
                    }
                }
            }
        }
        checkingKingSquares = false
        checkingKingSquaresWhenCheck = false
        return blockedSquares
    }
    
    private func findBlockedSquaresForRook(square: Square, kingSquare: Square) -> [Square] {
        if square.row == kingSquare.row {
            return rookHelperVertical(squares: availableSquares, square: square, currentSquare: kingSquare)
        }
        else if square.column == kingSquare.column {
            return rookHelperHorizontal(squares: availableSquares, square: square, currentSquare: kingSquare)
        }
        return []
    }
    
    private func findBlockedSquaresForBishop(square: Square, kingSquare: Square) -> [Square] {
        var squares = bishopHelper(squares: availableSquares, square: square, currentSquare: kingSquare)
        let operation: (BoardFiles,BoardFiles) -> Bool = square.column > kingSquare.column ? (<=) : (>=)
        squares = squares.filter({operation($0.column, square.column)})
        return squares
    }
    
    private func findBlockedSquaresForQueen(square: Square, kingSquare: Square) -> [Square] {
        var squares = [Square]()
        squares += findBlockedSquaresForRook(square: square, kingSquare: kingSquare)
        if squares.isEmpty {
            squares += findBlockedSquaresForBishop(square: square, kingSquare: kingSquare)
            squares = squares.filter({$0.row != square.row && $0.column != square.column})
        }
        return squares
    }
    
    // MARK: - End of the game
    
    private func checkForEndGame() {
        checkingKingSquaresWhenCheck = true
        let kingSquare = gameBoard.squares.first(where: {$0.figure?.name == .king && $0.figure?.color != pickedSquares.first?.figure?.color})
        if let kingSquare = kingSquare {
            findAvailableSquares(kingSquare)
            if availableSquares.isEmpty {
                gameEnded = true
                winner = currentPlayer == players.first! ? players.second! : players.first!
            }
        }
    }
    
    private func checkForPat() {
        let color: GameColors = pickedSquares.first?.figure?.color == .black ? .white : .black
        let squares = gameBoard.squares.filter({$0.figure?.color == color})
        var allAvailableSquares = [Square]()
        for square in squares {
            findAvailableSquares(square)
            allAvailableSquares += availableSquares
        }
        if allAvailableSquares.isEmpty {
            gameEnded = true
            draw = true
        }
    }
    
    // MARK: - Other
    
    func resetPickedSquares() {
        pickedSquares = []
    }
    
    func resetCastle() {
        shortCastle = false
        longCastle = false
    }
    
    func resetPawnSquare() {
        pawnSquare = nil
    }
    
    func getUpdatedSquares(from turn: Turn) -> (first: Square?, second: Square?){
        if turn.squares.count == 2 {
            let firstSquare = gameBoard[turn.squares.first!.column, turn.squares.first!.row]
            let secondSquare = gameBoard[turn.squares.second!.column, turn.squares.second!.row]
            return  (firstSquare, secondSquare)
        }
        return (nil, nil)
    }
    
}

// MARK: - Constants

private struct GameLogic_Constants {
    static let startRowsForPawn = [2,7]
    static let lastRowsForPawn = [1,8]
    static let kingColumnForLongCastle: BoardFiles = .F
    static let kingColumnForShortCastle: BoardFiles = .B
    static let rowForWhiteCastle = 1
    static let rowForBlackCastle = 8
    static let columnsForRookShortCastle: [BoardFiles] = [.A, .C]
    static let columnsForRookLongCastle: [BoardFiles] = [.H, .E]
    //minimum distance between rows or columns
    static let minimumDistance = 1
    static let leftRookStartColumn: BoardFiles = .A
    static let leftKnightStartColumn: BoardFiles = .B
    static let leftBishopStartColumn: BoardFiles = .C
    static let queenStartColumn: BoardFiles = .E
    static let rightBishopStartColumn: BoardFiles = .F
    static let rightKnightStartColumn: BoardFiles = .G
    static let rightRookStartColumn: BoardFiles = .H
}
