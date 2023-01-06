//
//  GameLogic.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.06.2022.
//

import Foundation

//class that represents logic of the game
class GameLogic: Codable {
    
    // MARK: - Properties
    
    private(set) var gameBoard = GameBoard()
    //stores picked squares by player
    private(set) var pickedSquares = [Square]()
    private(set) var turns = [Turn]()
    private(set) var storedTurns = [Turn]()
    private(set) var currentPlayer: Player
    //stores available squares for picked figure
    private(set) var availableSquares = [Square]()
    //when pawn reached last row and is about to transform
    private(set) var pawnWizard = false
    private(set) var players = [Player]()
    private(set) var gameMode: GameModes
    //if winner is nil and gameEnded is true, it is a draw
    private(set) var winner: Player?
    private(set) var gameEnded = false
    //used in rewind
    private(set) var currentTurn: Turn?
    private(set) var firstTurn = false
    private(set) var lastTurn = false
    private(set) var timeLeft: Int
    private(set) var startDate = Date()
    
    let timerEnabled: Bool
    //useful for multiplayer games
    let gameID: String?
    let squaresTheme: SquaresThemes
    let boardTheme: BoardThemes
    let maximumCoinsForWheel: Int
    //every time player makes a turn, he got extra time for that
    let additionalTime: Int
    let totalTime: Int
    let rewindEnabled: Bool
    
    //when we updating timeLeft manually and timer is not running at the moment,
    //we don`t need to update it second time, when launching timer
    private var timeLeftIsUpdated = false
    private var storedGameBoard = GameBoard()
    private var storedPlayers = [Player]()
    //when current player made check
    private var check = false
    //when last turn was short or long castle
    private var shortCastle = false
    private var longCastle = false
    private var checkMate = false
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
    private var checkingDeadPosition = false
    private var timer: Timer?
    
    private typealias constants = GameLogic_Constants
    
    enum CodingKeys: String, CodingKey {
        case startDate, players, gameMode, rewindEnabled, timeLeft, additionalTime, turns, gameEnded, timerEnabled, squaresTheme, boardTheme, maximumCoinsForWheel, currentPlayer, totalTime, winner, currentTurn, gameBoard, firstTurn, lastTurn, gameID
    }
    
    // MARK: - Inits
    
    init(firstUser: User, secondUser: User?, gameMode: GameModes, firstPlayerColor: GameColors, rewindEnabled: Bool = false, totalTime: Int, additionalTime: Int, gameID: String? = nil) {
        self.gameID = gameID
        var firstPlayerColor = firstPlayerColor
        if firstPlayerColor == .random {
            firstPlayerColor = firstPlayerColor.opposite()
        }
        let player1 = Player(user: firstUser, type: .player1, figuresColor: firstPlayerColor, timeLeft: totalTime, multiplayerType: gameMode == .multiplayer ? .creator : nil)
        players.append(player1)
        //when we create multiplayer game, it only have 1 user at the start
        if let secondUser = secondUser {
            let player2 = Player(user: secondUser, type: .player2, figuresColor: firstPlayerColor.opposite(), timeLeft: totalTime)
            players.append(player2)
        }
        currentPlayer = players.first(where: {$0.figuresColor == .white}) ?? players.first!
        squaresTheme = players.randomElement()!.user.squaresTheme
        boardTheme = players.randomElement()!.user.boardTheme
        self.gameMode = gameMode
        if gameMode == .multiplayer {
            maximumCoinsForWheel = Int.random(in: constants.rangeForCoins)
        }
        else {
            maximumCoinsForWheel = 0
        }
        self.additionalTime = additionalTime
        self.rewindEnabled = rewindEnabled
        timeLeft = totalTime
        timerEnabled = totalTime > 0 ? true : false
        self.totalTime = totalTime
    }
    
    //Firebase don`t store empty arrays, that`s why we need custom decoder
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        startDate = try values.decode(Date.self, forKey: .startDate)
        players = try values.decode([Player].self, forKey: .players)
        gameMode = try values.decode(GameModes.self, forKey: .gameMode)
        rewindEnabled = try values.decode(Bool.self, forKey: .rewindEnabled)
        timeLeft = try values.decode(Int.self, forKey: .timeLeft)
        additionalTime = try values.decode(Int.self, forKey: .additionalTime)
        turns = (try? values.decode([Turn].self, forKey: .turns)) ?? []
        gameEnded = try values.decode(Bool.self, forKey: .gameEnded)
        timerEnabled = try values.decode(Bool.self, forKey: .timerEnabled)
        squaresTheme = try values.decode(SquaresThemes.self, forKey: .squaresTheme)
        boardTheme = try values.decode(BoardThemes.self, forKey: .boardTheme)
        maximumCoinsForWheel = try values.decode(Int.self, forKey: .maximumCoinsForWheel)
        currentPlayer = try values.decode(Player.self, forKey: .currentPlayer)
        totalTime = try values.decode(Int.self, forKey: .totalTime)
        winner = try? values.decode(Player.self, forKey: .winner)
        currentTurn = try? values.decode(Turn.self, forKey: .currentTurn)
        gameBoard = try values.decode(GameBoard.self, forKey: .gameBoard)
        firstTurn = try values.decode(Bool.self, forKey: .firstTurn)
        lastTurn = try values.decode(Bool.self, forKey: .lastTurn)
        gameID = try? values.decode(String.self, forKey: .gameID)
    }
    
    // MARK: - Methods
    
    //when user choose game to load for the first time
    func configureAfterLoad() {
        saveGameDataForRestore()
        checkForRealCheck(color: currentPlayer.figuresColor.opposite())
    }
    
    //restores game from last saved state
    func restoreFromStoredTurns() {
        turns = storedTurns
        startFromFirstTurn()
    }
    
    func restoreFromStoredTurnsToLastTurn() {
        turns = storedTurns
        gameBoard = storedGameBoard
        players = storedPlayers
        resetPickedSquares()
        currentPlayer = turns.last?.squares.first?.figure?.color == players.first?.figuresColor ? players.second! : players.first!
        timeLeft = currentPlayer.timeLeft
        currentTurn = turns.last
        pawnWizard = false
        shortCastle = false
        longCastle = false
        firstTurn = false
        lastTurn = true
        checkForRealCheck(color: currentPlayer.figuresColor.opposite())
    }
    
    //restarts game
    func startFromFirstTurn() {
        timeLeft = totalTime
        players[0].updateTimeLeft(newValue: totalTime)
        players[1].updateTimeLeft(newValue: totalTime)
        currentPlayer = players.first(where: {$0.figuresColor == .white})!
        currentTurn = turns.first
        gameBoard = GameBoard()
        resetPickedSquares()
        check = false
        pawnWizard = false
        shortCastle = false
        longCastle = false
        firstTurn = true
        lastTurn = false
    }
    
    //turn is used, when we are processing oponnent`s turn, cuz we don`t need to create new turn for that turn
    func makeTurn(square: Square, turn: Turn? = nil) {
        if pawnWizard {
            if let timeLeft = square.timeLeft {
                updateTimeLeft(with: timeLeft, countAdditionalTime: false)
            }
            transformPawn(turn: currentTurn!, figure: square.figure, turnTime: square.time)
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
                        players[index].updateTimeLeft(newValue: (turn != nil ? turn!.timeLeft : timeLeft + additionalTime))
                        currentPlayer = players[index]
                    }
                }
                if !forwardRewind && !backwardRewind {
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
                if let figure = pickedSquares.second?.figure {
                    if let playerIndex = players.firstIndex(where: {$0.type != currentPlayer.type}) {
                        if !backwardRewind {
                            players[playerIndex].addDestroyedFigure(figure)
                        }
                        else {
                            players[playerIndex].removeDestroyedFigure(figure)
                        }
                    }
                }
                var figureColor = pickedSquares.first!.figure!.color
                if backwardRewind {
                    figureColor = figureColor.opposite()
                }
                checkForRealCheck(color: figureColor)
                if !forwardRewind && !backwardRewind {
                    //if turn from past changed (when game was rewinded)
                    if currentTurn != turns.last || (currentTurn == turns.first && currentTurn?.squares.first?.figure?.color == currentPlayer.figuresColor) {
                        removeTurnsIfTurnChanged()
                    }
                    if let turn = turn {
                        turns.append(turn)
                        currentTurn = turn
                    }
                    else {
                        let newTurn = Turn(squares: pickedSquares, turnDuration: turnDuration, shortCastle: shortCastle, longCastle: longCastle, check: check, checkMate: checkMate, timeLeft: currentPlayer.timeLeft, checkSquare: check ? getKingSquare(color: figureColor) : nil, gameID: gameID)
                        turns.append(newTurn)
                        currentTurn = newTurn
                    }
                    lastTurn = true
                    firstTurn = false
                }
                if (enPassantSquares.contains(square) || currentTurn?.pawnSquare != nil) && pickedSquares.first!.figure!.name == .pawn {
                    destroyEnPassantPawn()
                }
                enPassantSquares.removeAll()
                if (!shortCastle && !longCastle && pickedSquares.first!.figure!.name == .king && !backwardRewind && !forwardRewind) {
                    checkForCastle()
                }
                if !shortCastle && !longCastle && !backwardRewind && !pawnWizard {
                    switchPlayer()
                }
            }
            //player picks other own figure
            else {
                resetPickedSquares()
                pickSquare(square)
            }
        }
        //player unpicks figure
        else {
            resetPickedSquares()
        }
    }
    
    //checks if current player made castle and, if is is not rewind, makes castle
    private func checkForCastle() {
        let canCastle = canCastle()
        if canCastle.short || canCastle.long {
            checkIfCastled(squares: pickedSquares)
        }
        if let currentTurn = currentTurn, let turnIndex = turns.firstIndex(of: currentTurn) {
            turns[turnIndex].updateCastle(short: shortCastle, long: longCastle)
            self.currentTurn = turns[turnIndex]
        }
        if shortCastle || longCastle {
            makeCastle()
        }
    }
    
    //checks if current player can castle
    private func canCastle() -> (short: Bool, long: Bool) {
        var kingMoved = true
        var leftRookMoved = true
        var rightRookMoved = true
        outerLoop: for square in gameBoard.squares {
            if let figure = square.figure {
                if figure.name == .king && square.figure?.color == currentPlayer.figuresColor {
                    kingMoved = checkIfFigureMoved(figure: figure)
                    if kingMoved {
                        break outerLoop
                    }
                }
                if figure.name == .rook && square.figure?.color == currentPlayer.figuresColor {
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
            return (!rightRookMoved, !leftRookMoved)
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
    private func transformPawn(turn: Turn, figure: Figure? = nil, turnTime: Date? = nil) {
        if let square = currentTurn?.squares.first {
            pickedSquares.append(square)
        }
        var turnDuration = 0
        if timerEnabled && !backwardRewind && !forwardRewind, let index = players.firstIndex(where: {$0 == currentPlayer}) {
            timer?.invalidate()
            turnDuration = turn.timeLeft - timeLeft - additionalTime
            players[index].updateTimeLeft(newValue: timeLeft + additionalTime)
            currentPlayer = players[index]
        }
        if let turnIndex = turns.firstIndex(of: turn) {
            if let figure = turn.pawnTransform  {
                gameBoard.updateSquare(square: turn.squares.second!, figure: figure)
                checkForRealCheck(color: figure.color)
            }
            else if let figure = figure {
                turns[turnIndex].updateTime(newValue: turnTime ?? Date())
                turns[turnIndex].updatePawnTransform(newValue: figure)
                turns[turnIndex].updateTurnDuration(newValue: turnDuration)
                gameBoard.updateSquare(square: turn.squares.second!, figure: figure)
                checkForRealCheck(color: figure.color)
                turns[turnIndex].updateCheck(check, checkMate: checkMate, checkSquare: check ? getKingSquare(color: figure.color) : nil)
                self.currentTurn = turns[turnIndex]
            }
        }
        resetPickedSquares()
        pawnWizard = false
        switchPlayer()
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
    
    private func makeCastle() {
        let row = pickedSquares.first!.figure?.color == .black ? constants.lastRow : constants.firstRow
        resetPickedSquares()
        if shortCastle {
            moveRookToCastle(startColumn: constants.columnsForRookShortCastle.first!, endColumn: constants.columnsForRookShortCastle.second!, row: row)
        }
        else if longCastle {
            moveRookToCastle(startColumn: constants.columnsForRookLongCastle.first!, endColumn: constants.columnsForRookLongCastle.second!, row: row)
        }
        resetCastle()
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
                    let pawnSquare = gameBoard.squares.first(where: {$0.column == pickedSquares.second!.column && $0.row == pickedSquares.second!.row + rowDistance})
                    self.currentTurn?.updatePawnSquare(newValue: pawnSquare)
                }
                if let figure = self.currentTurn?.pawnSquare?.figure {
                    if let playerIndex = players.firstIndex(where: {$0.type != currentPlayer.type}) {
                        players[playerIndex].addDestroyedFigure(figure)
                    }
                }
                turns[turnIndex] = self.currentTurn!
            }
            if let pawnSquare = currentTurn?.pawnSquare {
                if let figure = pawnSquare.figure {
                    if !backwardRewind {
                        gameBoard.updateSquare(square: pawnSquare)
                        if forwardRewind {
                            if let playerIndex = players.firstIndex(where: {$0.type == currentPlayer.type}) {
                                players[playerIndex].addDestroyedFigure(figure)
                            }
                        }
                    }
                    else {
                        gameBoard.updateSquare(square: pawnSquare, figure: pawnSquare.figure)
                        if let playerIndex = players.firstIndex(where: {$0.type != currentPlayer.type}) {
                            players[playerIndex].removeDestroyedFigure(figure)
                        }
                    }
                }
            }
        }
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
        if !checkingDeadPosition {
            availableSquares = availableSquares.filter({$0.figure?.color != currentFigure.color})
        }
        let row = currentFigure.color == .black ? constants.lastRow : constants.firstRow
        let canCastle = canCastle()
        //adds additional square for short castle, if all conditions met
        if canCastle.short && !check && !checkSquares.contains(where: {($0.column == constants.rightKnightStartColumn || $0.column == constants.rightBishopStartColumn) && $0.row == row}) {
            let firstCondition = gameBoard[constants.rightRookStartColumn, row]?.figure != nil
            let secondCondition = gameBoard[constants.rightKnightStartColumn, row]?.figure == nil
            let thirdCondition = gameBoard[constants.rightBishopStartColumn, row]?.figure == nil
            if firstCondition && secondCondition && thirdCondition {
                if let square = gameBoard[constants.kingColumnForShortCastle, row] {
                    availableSquares.append(square)
                }
            }
        }
        //adds additional square for long castle, if all conditions met
        if canCastle.long && !check && !checkSquares.contains(where: {($0.column == constants.leftKnightStartColumn || $0.column == constants.leftBishopStartColumn || $0.column == constants.queenStartColumn) && $0.row == row}) {
            let firstCondition = gameBoard[constants.queenStartColumn, row]?.figure == nil
            let secondCondition = gameBoard[constants.leftBishopStartColumn, row]?.figure == nil
            let thirdCondition = gameBoard[constants.leftRookStartColumn, row]?.figure != nil
            let fourthCondition = gameBoard[constants.leftKnightStartColumn, row]?.figure == nil
            if firstCondition && secondCondition && thirdCondition && fourthCondition {
                if let square = gameBoard[constants.kingColumnForLongCastle, row] {
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
        checkMate = false
        check = false
        blockFromCheckSquares = checkForCheck(color: color)
        if checkSquares.contains(where: {$0.figure?.name == .king && $0.figure?.color != color}) {
            check = true
            if !forwardRewind && !backwardRewind {
                checkForEndGame()
            }
        }
        else {
            if !forwardRewind && !backwardRewind && !gameEnded {
                checkForDraw(color: color.opposite())
            }
        }
    }
    
    private func checkForPossibleCheck(square: Square, color: GameColors) {
        blockFromPossibleCheckSquares = []
        possibleCheck = false
        if square.figure?.name == .king || checkingDeadPosition {
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
                if let kingSquare = availableSquares.first(where: {$0.figure?.name == .king && $0.figure?.color == color.opposite()}) {
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
        if !gameEnded {
            gameEnded = true
            winner = currentPlayer
            calculatePoints()
        }
        checkMate = true
    }
    
    private func calculatePoints() {
        if gameMode == .multiplayer && turns.count > constants.minimumTurnsToCalculatePoints {
            var points = (abs(players.first!.user.points - players.second!.user.points)) / players.first!.user.rank.factor
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
                players[index].addPointsToUser(points)
                if currentPlayer.type == .player1 {
                    currentPlayer = players[index]
                }
            }
            if let index = players.firstIndex(where: {$0.type == .player2}) {
                players[index].addPointsToUser(-points)
                if currentPlayer.type == .player2 {
                    currentPlayer = players[index]
                }
            }
        }
    }
    
    func surrender(for player: GamePlayers? = nil) {
        if !gameEnded {
            timer?.invalidate()
            gameEnded = true
            if let player = player {
                winner = player == .player2 ? players.first! : players.second!
            }
            else {
                winner = currentPlayer == players.first! ? players.second! : players.first!
            }
            calculatePoints()
        }
    }
    
    // MARK: - Draw
    
    private func checkForDraw(color: GameColors) {
        let squares = gameBoard.squares.filter({$0.figure?.color == color})
        let threeSameTurnsInARow = checkIfTurnsEqual()
        let insufficientMaterial = checkForInsufficientMaterial()
        let deadPosition = checkForDeadPosition()
        var allEnemyAvailableSquares = [Square]()
        //stalemate
        outerLoop: for square in squares {
            findAvailableSquares(square)
            allEnemyAvailableSquares += availableSquares
            if !allEnemyAvailableSquares.isEmpty {
                break outerLoop
            }
        }
        if allEnemyAvailableSquares.isEmpty || threeSameTurnsInARow || insufficientMaterial || deadPosition {
            forceDraw()
        }
    }
    
    private func checkIfTurnsEqual() -> Bool {
        //if turns contains castle, it should be counted as 1 turn, not as 2
        let specialFactor = turns.filter({$0.shortCastle || $0.longCastle}).count
        if turns.count >= constants.sameTurnsForDraw * players.count + specialFactor / 2 {
            let firstPlayerHaveUniqueTurns = checkIfPlayerTurnsEqual(players.first!)
            let secondPlayerHaveUniqueTurns = checkIfPlayerTurnsEqual(players.second!)
            if firstPlayerHaveUniqueTurns  && secondPlayerHaveUniqueTurns {
                return true
            }
        }
        return false
    }
    
    private func checkIfPlayerTurnsEqual(_ player: Player) -> Bool {
        var playerUniqueTurns: [Turn] = []
        let playerTurns = turns.filter({$0.squares.first!.figure?.color == player.figuresColor})
        for turn in playerTurns[playerTurns.count - constants.sameTurnsForDraw...playerTurns.count - 1] {
            if !playerUniqueTurns.contains(where: {$0.squares == turn.squares}) {
                playerUniqueTurns.append(turn)
            }
        }
        if playerUniqueTurns.count == constants.turnsForCountAsSameTurn {
            return true
        }
        return false
    }
    
    private func checkForDeadPosition() -> Bool {
        //if at least 1 figure is not blocked, this is not dead position yet
        var figuresBlocked = true
        //dead position of both players
        var deadPositions: [Bool] = []
        outerLoop: for square in gameBoard.squares.filter({$0.figure != nil}) {
            findAvailableSquares(square)
            if square.figure?.name != .king {
                figuresBlocked = availableSquares.isEmpty
                if !figuresBlocked {
                    break outerLoop
                }
            }
        }
        if figuresBlocked {
            let kingsSquares = gameBoard.squares.filter({$0.figure?.name == .king})
            var kingBlockPawn = false
            checkingDeadPosition.toggle()
            for kingSquare in kingsSquares {
                calculateAvailableSquaresForKing(currentSquare: kingSquare, currentFigure: kingSquare.figure!)
                if availableSquares.contains(where: {pawnBlockedByKing(square: $0, kingSquare: kingSquare)}) {
                    kingBlockPawn = true
                }
            }
            //king can only block pawn and if it`s, it`s also not dead position yet
            if !kingBlockPawn {
                for kingSquare in kingsSquares {
                    checkForPossibleCheck(square: kingSquare, color: kingSquare.figure!.color.opposite())
                    deadPositions.append(checkCheckSquaresForDeadPosition(color: kingSquare.figure!.color))
                }
            }
            checkingDeadPosition.toggle()
        }
        //both player need to have dead position
        if deadPositions.contains(false) || deadPositions.isEmpty {
            return false
        }
        return true
    }
    
    //checks if pawn blocked by king
    private func pawnBlockedByKing(square: Square, kingSquare: Square) -> Bool {
        if square.figure?.name == .pawn && square.column == kingSquare.column {
            var operation: (Int, Int) -> Bool = kingSquare.figure?.color == .white ? (>) : (<)
            if kingSquare.figure?.color == square.figure?.color {
                operation = kingSquare.figure?.color == .white ? (<) : (>)
            }
            if operation(square.row, kingSquare.row) {
                return true
            }
        }
        return false
    }
    
    //one of the cases in dead position, if all pawns can`t move and king can`t find a way to eat at least 1 enemy pawn
    //this function checks this case
    private func checkCheckSquaresForDeadPosition(color: GameColors) -> Bool {
        let squaresSortedByRow = gameBoard.squares.sorted(by: {$0.row < $1.row})
        let condition: (Square) -> Bool = { [weak self] in
            if let self = self {
                return $0.figure?.name == .pawn && $0.figure?.color != color && !self.checkSquares.contains($0)
            }
            return false
        }
        //square with pawn with max row
        let maxPawn = color == .white ? squaresSortedByRow.first(where: {condition($0)}) : squaresSortedByRow.last(where: {condition($0)})
        //if player can pass through column
        var spacersInColumn: [Bool] = []
        //if player can pass through row
        var spacersInRows: [Bool] = []
        var uniqueCheckSquares: [Square] = []
        for checkSquare in checkSquares {
            if !uniqueCheckSquares.contains(checkSquare) {
                uniqueCheckSquares.append(checkSquare)
            }
        }
        if let maxPawn = maxPawn {
            let range = color == .white ? stride(from: constants.firstRow, through: maxPawn.row, by: constants.minimumDistance) : stride(from: constants.lastRow, through: maxPawn.row, by: -constants.minimumDistance)
            for column in BoardFiles.allCases {
                for row in range {
                    var filteredSquare = gameBoard.squares.filter({$0.row == row && $0.column == column})
                    filteredSquare = filteredSquare.filter({$0.figure == nil || checkSquares.contains($0)})
                    //if true, it means player can`t pass through this square
                    if filteredSquare == uniqueCheckSquares.filter({$0.row == row && $0.column == column}) {
                        spacersInRows.append(false)
                    }
                    else {
                        spacersInRows.append(true)
                    }
                }
                //if player can`t pass at least through one square in rows, it means he can`t pass through this column
                if spacersInRows.contains(false) {
                    spacersInColumn.append(false)
                }
                else {
                    spacersInColumn.append(true)
                }
                spacersInRows = []
            }
        }
        //if player can pass at least through one square in columns, it means it`s not a dead position
        if spacersInColumn.contains(true) {
            return false
        }
        return true
    }
    
    //another case of dead position, when player can`t find a way to checkmate opponent
    //according to chess rules, even if player can actually make a checkmate, if it`s
    //not possible without help of enemy, it still counts as insufficient material
    private func checkForInsufficientMaterial(for player: Player? = nil) -> Bool {
        let playersCount = player == nil ? players.count : 1
        //if we check particular player. opponent`s king don`t count, which means, that in second condition,
        //instead of 3, it must be 2
        let figuresFactor = player == nil ? 0 : 1
        var figuresAvailable = gameBoard.squares.filter({$0.figure != nil})
        if let player = player {
            figuresAvailable = figuresAvailable.filter({$0.figure?.color == player.figuresColor})
        }
        //if player have only king
        if figuresAvailable.count == 1 * playersCount {
            return true
        }
        //if player have king and bishop/knight(when checking for 1 player)
        //if one player have only king and another player have king and bishop/knight(when checking for both players)
        else if figuresAvailable.count == 3 - figuresFactor && figuresAvailable.contains(where: {$0.figure?.name == .bishop || $0.figure?.name == .knight}) {
            return true
        }
        //if both players have king and bishop/knight or one player have only king and another player have king and 2 knights
        //we are not checking this for particular player, because according to chess rules, if time runs out and opponent have
        //king and 2 knights, it`s not counts as insufficient material and in all other cases, if oppoent have more then 2 figures
        //it`s not an unsufficient material
        else if figuresAvailable.count == 4 && player == nil {
            let bishopsSquares = figuresAvailable.filter({$0.figure?.name == .bishop})
            let knightSquares = figuresAvailable.filter({$0.figure?.name == .knight})
            if bishopsSquares.count == 2 {
                //checks if bishops don`t belong to same player
                if bishopsSquares.first?.figure?.color != bishopsSquares.second?.figure?.color {
                    return true
                }
            }
            else if knightSquares.count == 2 {
                return true
            }
            else if bishopsSquares.count == 1 && knightSquares.count == 1 {
                //checks if bishop and knight don`t belong to same player
                if bishopsSquares.first?.figure?.color != knightSquares.second?.figure?.color {
                    return true
                }
            }
        }
        return false
    }
    
    func forceDraw() {
        gameEnded = true
    }
    
    // MARK: - Chess time
    
    func activateTime(continueTimer: Bool = false, callback: @escaping (Int) -> Void) {
        if !timeLeftIsUpdated && !continueTimer {
            timeLeft = currentPlayer.timeLeft - constants.timerStep
        }
        else {
            timeLeftIsUpdated = false
        }
        callback(timeLeft)
        timer = Timer.scheduledTimer(withTimeInterval: constants.timerDelay, repeats: true, block: {[weak self] _ in
            if let self = self {
                if self.timeLeft != 0 {
                    self.timeLeft -= constants.timerStep
                }
                if self.timeLeft == 0 {
                    self.timer?.invalidate()
                    let insufficientMaterial = self.checkForInsufficientMaterial(for: self.currentPlayer.type == .player1 ? self.players.second : self.players.first)
                    //in other words, even if current player time runs out, if opponent have insufficient material, it is a draw, instead of lose
                    if insufficientMaterial {
                        self.forceDraw()
                    }
                    else {
                        self.surrender()
                    }
                }
                callback(self.timeLeft)
            }
        })
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func stopTime() {
        timer?.invalidate()
    }
    
    func timerIsValid() -> Bool {
        return timer?.isValid ?? false
    }
    
    // MARK: - Rewind
    
    //returns turn to animate, if backward rewind and makes turn
    //switches first and second square for that
    func backward() -> Turn? {
        resetPickedSquares()
        if !firstTurn {
            if let currentTurn = currentTurn, let currentTurnIndex = turns.firstIndex(of: currentTurn) {
                if (!currentTurn.shortCastle && !currentTurn.longCastle) || currentTurn.squares.first?.figure?.name == .king {
                    switchPlayer()
                }
                backwardRewind.toggle()
                timer?.invalidate()
                var firstSquare = turns[currentTurnIndex].squares.second!
                let firstSquareFigure = turns[currentTurnIndex].squares.second!.figure
                firstSquare.updateFigure(newValue: turns[currentTurnIndex].squares.first!.figure)
                var secondSquare = turns[currentTurnIndex].squares.first!
                secondSquare.updateFigure(newValue: firstSquareFigure)
                let turn = Turn(squares: [firstSquare, secondSquare], turnDuration: currentTurn.turnDuration, shortCastle: currentTurn.shortCastle, longCastle: currentTurn.longCastle, check: currentTurn.check, checkMate: currentTurn.checkMate, timeLeft: currentTurn.timeLeft, pawnTransform: currentTurn.pawnTransform, pawnSquare: currentTurn.pawnSquare, checkSquare: currentTurn.checkSquare, gameID: currentTurn.gameID)
                if timerEnabled, let index = players.firstIndex(where: {$0 == currentPlayer}) {
                    players[index].increaseTimeLeft(with: turn.turnDuration)
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
        }
        return nil
    }
    
    //returns turn to animate, if forward rewind and makes turn
    func forward() -> Turn? {
        resetPickedSquares()
        if !lastTurn {
            if let currentTurn = currentTurn, let currentTurnIndex = turns.firstIndex(of: currentTurn) {
                if (currentTurn.shortCastle || currentTurn.longCastle) && currentTurn.squares.first?.figure?.name == .king {
                    switchPlayer()
                }
                forwardRewind.toggle()
                timer?.invalidate()
                var turn = currentTurn
                if currentTurnIndex != turns.count - 1 && !firstTurn {
                    turn = turns[currentTurnIndex + 1]
                }
                if timerEnabled, let index = players.firstIndex(where: {$0 == currentPlayer}) {
                    players[index].increaseTimeLeft(with: -turn.turnDuration)
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
                return turn
            }
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
            //when we dropping turns, our currentTurn is -1 from that turn, which we about to change, except, if its a firstTurn
            let specialFactor = currentTurnIndex == 0 && firstTurn ? 0 : 1
            turns = turns.dropLast(turns.count - specialFactor - currentTurnIndex)
        }
    }
    
    //returns how much turns to current turn and whether it is ahead or behind
    func turnsLeft(to turn: Turn) -> (forward: Bool, count: Int) {
        if turn != currentTurn, let currentTurn = currentTurn, let currentTurnIndex = turns.firstIndex(of: currentTurn), let indexOfTurn = turns.firstIndex(of: turn) {
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
    
    private func switchPlayer() {
        currentPlayer = currentPlayer == players.first! ? players.second! : players.first!
    }
    
    private func getKingSquare(color: GameColors) -> Square? {
        return gameBoard.squares.first(where: {$0.figure?.name == .king && $0.figure?.color != color})
    }
    
    private func resetCastle() {
        shortCastle = false
        longCastle = false
    }
    
    //when user made changes to loaded game and want to undo them
    func saveGameDataForRestore() {
        storedTurns = turns
        storedGameBoard = gameBoard
        storedPlayers = players
    }
    
    func resetPickedSquares() {
        pickedSquares = []
    }
    
    func getUpdatedSquares(from turn: Turn) -> (first: Square?, second: Square?){
        if turn.squares.count == 2 {
            let firstSquare = gameBoard[turn.squares.first!.column, turn.squares.first!.row]
            let secondSquare = gameBoard[turn.squares.second!.column, turn.squares.second!.row]
            return  (firstSquare, secondSquare)
        }
        return (nil, nil)
    }
    
    //useful for multiplayer games
    func addSecondPlayer(user: User) {
        if let firstPlayerColor = players.first?.figuresColor {
            players.append(Player(user: user, type: .player2, figuresColor: firstPlayerColor.opposite(), timeLeft: timeLeft, multiplayerType: .joiner))
            if let firstPlayer = players.first(where: {$0.figuresColor == .white}) {
                currentPlayer = firstPlayer
            }
        }
    }
    
    func switchPlayers() {
        if players.count == 2 {
            var firstPlayer = players.first!
            firstPlayer.updateType(newValue: .player2)
            var secondPlayer = players.second!
            secondPlayer.updateType(newValue: .player1)
            players[0] = secondPlayer
            players[1] = firstPlayer
            currentPlayer = currentPlayer.figuresColor == firstPlayer.figuresColor ? firstPlayer : secondPlayer
        }
    }
    
    //useful for multiplayer games
    //when we are processing oponnent`s turn, we want to be sure, that time is correct, cuz there could be
    //a case of desynchronisation
    func updateTimeLeft(with newValue: Int, countAdditionalTime: Bool = true) {
        timeLeft = newValue - (countAdditionalTime ? additionalTime : 0)
        if let timer = timer, !timer.isValid {
            timeLeftIsUpdated = true
        }
    }
    
}

// MARK: - Constants

private struct GameLogic_Constants {
    static let startRowsForPawn = [2,7]
    static let lastRowsForPawn = [firstRow,lastRow]
    static let kingColumnForLongCastle: BoardFiles = .C
    static let kingColumnForShortCastle: BoardFiles = .G
    static let firstRow = 1
    static let lastRow = 8
    static let columnsForRookShortCastle: [BoardFiles] = [.H, .F]
    static let columnsForRookLongCastle: [BoardFiles] = [.A, .D]
    //minimum distance between rows or columns
    static let minimumDistance = 1
    static let leftRookStartColumn: BoardFiles = .A
    static let leftKnightStartColumn: BoardFiles = .B
    static let leftBishopStartColumn: BoardFiles = .C
    static let queenStartColumn: BoardFiles = .D
    static let rightBishopStartColumn: BoardFiles = .F
    static let rightKnightStartColumn: BoardFiles = .G
    static let rightRookStartColumn: BoardFiles = .H
    static let rangeForCoins = 50...500
    static let minimumPointsForGame = 10
    static let maximumPointsForGame = 150
    static let timerDelay = 1.0
    static let timerStep = 1
    //it means, if player move figure from square 1 to square 2 and then vice versa,
    //it will count as one turn for compare turns on equality
    static let turnsForCountAsSameTurn = 2
    static let sameTurnsForDraw = 3 * turnsForCountAsSameTurn
    static let minimumTurnsToCalculatePoints = 1
}
