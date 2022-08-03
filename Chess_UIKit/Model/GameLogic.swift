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
    private(set) var players: [Player]
    private(set) var gameMode: GameModes
    private(set) var winner: Player?
    private(set) var gameEnded = false
    private(set) var draw = false
    private(set) var timerEnabled = true
    //used in rewind
    private(set) var currentTurn: Turn?
    private(set) var rewindEnabled = true
    private(set) var firstTurn = false
    private(set) var lastTurn = false
    private(set) var timeLeft = 300
    
    let squaresTheme: SquaresTheme
    let boardTheme: BoardThemes
    let maximumCoinsForWheel: Int
    
    private var backwardRewind = false
    private var forwardRewind = false
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
    private var timer: Timer?
    //every time player makes a turn, he got extra time for that
    private var additionalTime = 2
    
    private typealias constants = GameLogic_Constants
    
    // MARK: - Inits
    
    init() {
        let randomBool = Bool.random()
        players = [Player(name: "Player1", type: .player1, figuresColor: randomBool ? .white : .black), Player(name: "Player2", type: .player2, figuresColor: randomBool ? .black : .white)]
        currentPlayer = players.first(where: {$0.figuresColor == .white})!
        squaresTheme = players.randomElement()!.squaresTheme
        boardTheme = players.randomElement()!.boardTheme
        gameMode = .oneScreen
        if gameMode == .multiplayer {
            maximumCoinsForWheel = Int.random(in: constants.rangeForCoins)
        }
        else {
            maximumCoinsForWheel = 0
        }
    }
    
    // MARK: - Methods
    
    func makeTurn(square: Square) {
        if pawnWizard {
            transformPawn(turn: currentTurn!, figure: square.figure)
        }
        else if pickedSquares.isEmpty {
            pickSquare(square)
        }
        else if pickedSquares.count == 1 && !pickedSquares.contains(square){
            if availableSquares.contains(square) || shortCastle || longCastle || forwardRewind || backwardRewind {
                var turnDuration = 0
                if !shortCastle && !longCastle && !pawnWizard {
                    turnDuration = currentPlayer.timeLeft - timeLeft - additionalTime
                }
                pickedSquares.append(square)
                if pickedSquares.first!.figure!.name == .pawn && constants.lastRowsForPawn.contains(pickedSquares.second!.row) {
                    pawnWizard = true
                }
                if timerEnabled && !pawnWizard && !shortCastle && !longCastle, let index = players.firstIndex(where: {$0 == currentPlayer}) {
                    timer?.invalidate()
                    if !backwardRewind && !forwardRewind {
                        players[index].timeLeft = timeLeft + additionalTime
                        currentPlayer = players[index]
                    }
                }
                if !forwardRewind && !backwardRewind {
                    //if turn from past changed (when game was rewinded)
                    if currentTurn != turns.last {
                        removeTurnsIfTurnChanged()
                    }
                    let turn = Turn(squares: pickedSquares, turnDuration: turnDuration)
                    turns.append(turn)
                    currentTurn = turn
                    gameBoard.updateSquares(firstSquare: pickedSquares.first!, secondSquare: pickedSquares.second!)
                }
                else {
                    if backwardRewind {
                        gameBoard.updateSquare(square: pickedSquares.first!, figure: pickedSquares.second!.figure)
                        gameBoard.updateSquare(square: pickedSquares.second!, figure: pickedSquares.first!.figure)
                    }
                    else {
                        gameBoard.updateSquare(square: pickedSquares.first!)
                        gameBoard.updateSquare(square: pickedSquares.second!, figure: pickedSquares.first!.figure)
                    }
                }
                var color = pickedSquares.first!.figure!.color
                if backwardRewind {
                    color = color == .black ? .white : .black
                }
                checkForRealCheck(color: color)
                if enPassantSquares.contains(square) || currentTurn?.pawnSquare != nil {
                    destroyEnPassantPawn()
                }
                if (!shortCastle && !longCastle && pickedSquares.first!.figure!.name == .king) || (backwardRewind && pickedSquares.first!.figure!.name == .rook) {
                    checkForCastle()
                }
                if !shortCastle && !longCastle && !backwardRewind && !pawnWizard {
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
    
    //checks if current player made castle and, if is is not rewind, makes castle
    private func checkForCastle() {
        if !backwardRewind {
            let canCastle = canCastle()
            if canCastle.short || canCastle.long {
                checkIfCastled(squares: pickedSquares)
            }
            if shortCastle || longCastle {
                makeCastle()
            }
        }
        else {
            if let currentTurn = currentTurn, let currentTurnIndex = turns.firstIndex(of: currentTurn) {
                if currentTurnIndex > 0 {
                    //if we try to rewind a castle current turn will be with rook, so we need to get turn before that
                    let kingTurn = turns[currentTurnIndex - 1]
                    checkIfCastled(squares: kingTurn.squares)
                }
            }
        }
    }
    
    //checks if current player can castle
    private func canCastle() -> (short: Bool, long: Bool) {
        var kingMoved = true
        var leftRookMoved = true
        var rightRookMoved = true
        for square in gameBoard.squares {
            if let figure = square.figure {
                if figure.name == .king && square.figure?.color == currentPlayer.figuresColor {
                    kingMoved = checkIfFigureMoved(figure: figure)
                }
                if figure.name == .rook && square.figure?.color == currentPlayer.figuresColor{
                    if square.figure?.startColumn == constants.leftRookStartColumn {
                        leftRookMoved = checkIfFigureMoved(figure: figure)
                    }
                    else {
                        rightRookMoved = checkIfFigureMoved(figure: figure)
                    }
                }
            }
        }
        if !kingMoved {
            return (!leftRookMoved, !rightRookMoved)
        }
        else {
            return (false, false)
        }
    }
    
    //checks if figure ever moved before
    private func checkIfFigureMoved(figure: Figure) -> Bool{
        if let currentTurn = currentTurn, let turnIndex = turns.firstIndex(of: currentTurn) {
            let turnsBefore = turns[0..<turnIndex]
            if !turnsBefore.contains(where: {$0.squares.contains(where: {$0.figure == figure}) && $0.squares.first?.column == figure.startColumn}) {
                return false
            }
        }
        return true
    }
    
    //checks if current player made castle
    private func checkIfCastled(squares: [Square]) {
        if squares.first?.figure?.name == .king && squares.first?.row == squares.first?.figure?.startRow && squares.first?.column == squares.first?.figure?.startColumn {
            if squares.second?.column == constants.kingColumnForLongCastle {
                longCastle = true
            }
            else if squares.second?.column == constants.kingColumnForShortCastle {
                shortCastle = true
            }
        }
    }
    
    //transforms pawn, when he reached last row
    private func transformPawn(turn: Turn, figure: Figure? = nil) {
        var turnDuration = 0
        if timerEnabled && !backwardRewind && !forwardRewind, let index = players.firstIndex(where: {$0 == currentPlayer}) {
            timer?.invalidate()
            turnDuration = currentPlayer.timeLeft - timeLeft - additionalTime
            players[index].timeLeft = timeLeft + additionalTime
            currentPlayer = players[index]
        }
        if let turnIndex = turns.firstIndex(of: turn) {
            if let figure = turn.pawnTransform  {
                gameBoard.updateSquare(square: turn.squares.second!, figure: figure)
                checkForRealCheck(color: figure.color)
            }
            else if let figure = figure {
                turns[turnIndex].pawnTransform = figure
                turns[turnIndex].turnDuration = turnDuration
                self.currentTurn = turns[turnIndex]
                gameBoard.updateSquare(square: turn.squares.second!, figure: figure)
                checkForRealCheck(color: figure.color)
            }
        }
        pawnWizard = false
        currentPlayer = currentPlayer == players.first! ? players.second! : players.first!
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
            if let currentTurn = currentTurn, let turnIndex = turns.firstIndex(of: currentTurn), !backwardRewind && !forwardRewind {
                if currentTurn.pawnSquare == nil {
                    self.currentTurn?.pawnSquare = gameBoard.squares.first(where: {$0.column == pickedSquares.second!.column && $0.row == pickedSquares.second!.row + rowDistance})
                }
                turns[turnIndex] = self.currentTurn!
            }
            if let pawnSquare = currentTurn?.pawnSquare {
                if !backwardRewind {
                    gameBoard.updateSquare(square: pawnSquare)
                }
                else {
                    gameBoard.updateSquare(square: pawnSquare, figure: pawnSquare.figure)
                }
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
        if !checkingKingSquaresWhenCheck {
            availableSquares += gameBoard.squares.filter({$0.row - currentSquare.row == rowDistance && $0.column == currentSquare.column && $0.figure == nil})
            //if pawn at the start position and not blocked
            if !availableSquares.isEmpty  && constants.startRowsForPawn.contains(currentSquare.row) {
                availableSquares += gameBoard.squares.filter({$0.row - currentSquare.row == rowDistance * 2 && $0.column == currentSquare.column && $0.figure == nil})
            }
        }
        for square in gameBoard.squares {
            //pawn can only check diagonally
            if checkingKingSquaresWhenCheck {
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
                        if let turn = currentTurn, turn.squares.contains(square) && turn.squares.second!.row - turn.squares.first!.row == -rowDistance * 2  {
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
        if !checkingKingSquaresWhenCheck {
            availableSquares = availableSquares.filter({$0.figure?.color != currentFigure.color})
        }
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
        let canCastle = canCastle()
        //adds additional square for short castle, if all conditions met
        if canCastle.short && !check && !checkSquares.contains(where: {($0.column == constants.leftKnightStartColumn || $0.column == constants.leftBishopStartColumn) && $0.row == row}) {
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
        if canCastle.long && !check && !checkSquares.contains(where: {($0.column == constants.rightBishopStartColumn || $0.column == constants.rightKnightStartColumn || $0.column == constants.queenStartColumn) && $0.row == row}) {
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
        if checkSquares.contains(where: {$0.figure?.name == .king && $0.figure?.color != color}) {
            check = true
            checkForEndGame()
        }
        else {
            checkForDraw()
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
        if checkSquares.contains(where: {$0.figure?.name == .king && $0.figure?.color != color}) {
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
        for square in gameBoard.squares {
            if let figure = square.figure, figure.color != pickedSquares.first?.figure?.color {
                findAvailableSquares(square)
                if !availableSquares.isEmpty {
                    return
                }
            }
        }
        gameEnded = true
        winner = currentPlayer
        calculatePoints()
    }
    
    private func calculatePoints() {
        if gameMode == .multiplayer {
            var points = (abs(players.first!.points - players.second!.points)) / players.first!.rank.factor
            if points < constants.minimumPointsForGame {
                points = constants.minimumPointsForGame
            }
            else if points > constants.maximumPointsForGame {
                points = constants.maximumPointsForGame
            }
            if winner != players.first! {
                points = -points
            }
            if let index = players.firstIndex(where: {$0.type == .player1}) {
                players[index].addPoints(points)
            }
        }
    }
    
    func surender() {
        timer?.invalidate()
        gameEnded = true
        winner = currentPlayer == players.first! ? players.second! : players.first!
        calculatePoints()
    }
    
    //TODO: - Add more ways to draw
    
    private func checkForDraw() {
        let color: GameColors = pickedSquares.first?.figure?.color == .black ? .white : .black
        let squares = gameBoard.squares.filter({$0.figure?.color == color})
        var allAvailableSquares = [Square]()
        for square in squares {
            findAvailableSquares(square)
            allAvailableSquares += availableSquares
        }
        if allAvailableSquares.isEmpty {
            forceDraw()
        }
    }
    
    //
    
    func forceDraw() {
        gameEnded = true
        draw = true
        //just for proper UI update
        winner = currentPlayer
    }
    
    // MARK: - Chess time
    
    func activateTime(callback: @escaping (Int) -> Void) {
        timeLeft = currentPlayer.timeLeft - constants.timerStep
        callback(timeLeft)
        timer = Timer.scheduledTimer(withTimeInterval: constants.timerDelay, repeats: true, block: {[weak self] _ in
            if let self = self {
                self.timeLeft -= constants.timerStep
                if self.timeLeft == 0 {
                    self.timer?.invalidate()
                    self.surender()
                }
                callback(self.timeLeft)
            }
        })
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // MARK: - Rewind
    
    //returns turn to animate, if backward rewind and makes turn
    //switches first and second square for that
    func backward() -> Turn? {
        resetPickedSquares()
        if let currentTurn = currentTurn, let currentTurnIndex = turns.firstIndex(of: currentTurn) {
            backwardRewind.toggle()
            timer?.invalidate()
            if !shortCastle && !longCastle {
                currentPlayer = currentPlayer == players.first! ? players.second! : players.first!
            }
            var firstSquare = turns[currentTurnIndex].squares.second!
            let firstSquareFigure = turns[currentTurnIndex].squares.second!.figure
            firstSquare.figure = turns[currentTurnIndex].squares.first!.figure
            var secondSquare = turns[currentTurnIndex].squares.first!
            secondSquare.figure = firstSquareFigure
            let turn = Turn(squares: [firstSquare, secondSquare], pawnTransform: currentTurn.pawnTransform, pawnSquare: currentTurn.pawnSquare, turnDuration: currentTurn.turnDuration)
            if timerEnabled, let index = players.firstIndex(where: {$0 == currentPlayer}) {
                players[index].timeLeft += turn.turnDuration
                currentPlayer = players[index]
                timeLeft = currentPlayer.timeLeft
            }
            for square in turn.squares {
                makeTurn(square: square)
            }
            backwardRewind.toggle()
            backCurrentTurn()
            return turn
        }
        return nil
    }
    
    //returns turn to animate, if forward rewind and makes turn
    func forward() -> Turn? {
        resetPickedSquares()
        if let currentTurn = currentTurn, let currentTurnIndex = turns.firstIndex(of: currentTurn) {
            forwardRewind.toggle()
            timer?.invalidate()
            var turn = currentTurn
            if currentTurnIndex != turns.count - 1 && !firstTurn {
                turn = turns[currentTurnIndex + 1]
            }
            if timerEnabled, let index = players.firstIndex(where: {$0 == currentPlayer}) {
                players[index].timeLeft -= turn.turnDuration
                currentPlayer = players[index]
                timeLeft = currentPlayer.timeLeft
            }
            for square in turn.squares {
                makeTurn(square: square)
            }
            if pawnWizard {
                transformPawn(turn: turn)
            }
            forwardRewind.toggle()
            forwardCurrentTurn()
            if shortCastle || longCastle {
                forwardCurrentTurn()
            }
            return turn
        }
        return nil
    }
    
    private func backCurrentTurn() {
        if let currentTurn = currentTurn, let currentTurnIndex = turns.firstIndex(of: currentTurn) {
            //we are not making current turn nil, if it is start of the game
            //instead current turn stays the same
            if currentTurnIndex != 0 {
                self.currentTurn = turns[currentTurnIndex - 1]
            }
            else {
                firstTurn = true
            }
        }
        lastTurn = false
    }
    
    private func forwardCurrentTurn() {
        if let currentTurn = currentTurn, let currentTurnIndex = turns.firstIndex(of: currentTurn) {
            //we are not forwarding, if we at the start, because first turn is always current turn
            if currentTurnIndex != turns.count - 1 && !firstTurn {
                self.currentTurn = turns[currentTurnIndex + 1]
            }
            //currentIndex need to be turns.count - 2 here, cuz it is the index of unforwarded turn
            if (currentTurnIndex == turns.count - 2 && !firstTurn) || turns.count == 1  {
                lastTurn = true
            }
        }
        firstTurn = false
    }
    
    //if some turn was changed, erases game after that turn
    private func removeTurnsIfTurnChanged() {
        if let currentTurn = currentTurn, let currentTurnIndex = turns.firstIndex(of: currentTurn) {
            turns = turns.dropLast(turns.count - 1 - currentTurnIndex)
        }
    }
    
    //returns how much turns to current turn and whether it is ahead or behind
    func turnsLeft(to turn: Turn) -> (forward: Bool, count: Int) {
        if let currentTurn = currentTurn, let currentTurnIndex = turns.firstIndex(of: currentTurn), let indexOfTurn = turns.firstIndex(of: turn) {
            var turnsLeft = [Turn]()
            var forward = true
            if indexOfTurn > currentTurnIndex {
                turnsLeft = Array(turns[currentTurnIndex + 1...indexOfTurn])
            }
            else {
                forward = false
                turnsLeft = Array(turns[indexOfTurn + 1...currentTurnIndex])
            }
            var turnsCount = turnsLeft.count
            //we are storing castle turn as 2 turns, but in reality it is one turn (and we are animating it as 1 turn), so
            //we need to check, if turnsLeft contains black or white castle and make it 1 or 2 less
            if turnsLeft.contains(where: {$0.squares.first?.figure?.name == .king && $0.squares.first?.figure?.color == .white && $0.squares.first?.column == $0.squares.first?.figure?.startColumn && ($0.squares.second?.column == constants.kingColumnForLongCastle || $0.squares.second?.column == constants.kingColumnForShortCastle)}) {
                turnsCount -= 1
            }
            if turnsLeft.contains(where: {$0.squares.first?.figure?.name == .king && $0.squares.first?.figure?.color == .black && $0.squares.first?.column == $0.squares.first?.figure?.startColumn && ($0.squares.second?.column == constants.kingColumnForLongCastle || $0.squares.second?.column == constants.kingColumnForShortCastle)}) {
                turnsCount -= 1
            }
            if firstTurn && forward {
                return (forward, turnsCount + 1)
            }
            if !lastTurn || forward == false {
                return (forward, turnsCount)
            }
        }
        return (true, 0)
    }
    
    
    // MARK: - Other
    
    func resetPickedSquares() {
        pickedSquares = []
    }
    
    func resetCastle() {
        shortCastle = false
        longCastle = false
    }
    
    func resetPawnWizard() {
        pawnWizard = false
    }
    
    func switchPlayer() {
        currentPlayer = currentPlayer == players.first! ? players.second! : players.first!
    }
    
    func getUpdatedSquares(from turn: Turn) -> (first: Square?, second: Square?){
        if turn.squares.count == 2 {
            let firstSquare = gameBoard[turn.squares.first!.column, turn.squares.first!.row]
            let secondSquare = gameBoard[turn.squares.second!.column, turn.squares.second!.row]
            return  (firstSquare, secondSquare)
        }
        return (nil, nil)
    }
    
    func addCoinsToPlayer(coins: Int) {
        if let index = players.firstIndex(of: players.first!) {
            players[index].coins += coins
        }
    }
    
    func getCheckSquare() -> Square? {
        return gameBoard.squares.first(where: {$0.figure?.name == .king && $0.figure?.color != currentTurn?.squares.first?.figure?.color})
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
    static let rangeForCoins = 50...500
    static let minimumPointsForGame = 10
    static let maximumPointsForGame = 150
    static let timerDelay = 1.0
    static let timerStep = 1
}
