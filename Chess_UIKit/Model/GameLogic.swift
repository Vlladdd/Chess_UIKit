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
    
    var gameBoard = GameBoard()
    var pickedSquares = [Square]()
    var turns = [Turn]()
    let players: [Player]
    var currentPlayer = GamePlayers.player1
    var availableSquares = [Square]()
    var enPassant = false
    // where we can move to destroy en passant pawn
    var enPassantSquares = [Square]()
    
    // MARK: - Inits
    
    init() {
        players = [Player(name: "Player1"), Player(name: "Player2")]
    }
    
    // MARK: - Methods
    
    // completion block updates UI
    func makeTurn(square: Square, completion: @escaping () -> ()) {
        if pickedSquares.isEmpty {
            pickedSquares.append(square)
            calculateAvailableSquares()
        }
        else if pickedSquares.count == 1 && !pickedSquares.contains(square){
            if availableSquares.contains(square) {
                pickedSquares.append(square)
            }
            // player picks other own figure
            else {
                pickedSquares.removeAll()
                pickedSquares.append(square)
                calculateAvailableSquares()
            }
        }
        // player unpicks figure
        else {
            if let index = pickedSquares.firstIndex(of: square) {
                pickedSquares.remove(at: index)
            }
        }
        if pickedSquares.count == 2 {
            availableSquares = []
            currentPlayer = currentPlayer == .player1 ? .player2 : .player1
            turns.append(Turn(squares: pickedSquares))
            gameBoard.updateSquares(firstSquare: pickedSquares.first!, secondSquare: pickedSquares[1])
            // when en passant (only) the pawn we are about to destroy is on another square, not on that one where we will go,
            // so we need to calculate this and also add that square to pickedSquares for proper UI update
            if enPassant && enPassantSquares.contains(square) {
                // pawns can only move forward, but according to game board coordinates black pawn will move down
                // and white pawn will move up, so distance between new pawn square and old pawn square
                // will be calculated diferently
                var rowDistance = 0
                if let figure = pickedSquares.first!.figure {
                    if figure.color == .black {
                        rowDistance = -1
                    }
                    else {
                        rowDistance = 1
                    }
                    // pawn to be destroyed after en passant
                    let pawnSquare = gameBoard.squares.first(where: {$0.column == pickedSquares[1].column && $0.row == pickedSquares[1].row + rowDistance})
                    if let pawnSquare = pawnSquare {
                        gameBoard.updateSquare(square: pawnSquare)
                        pickedSquares.append(pawnSquare)
                    }
                }
            }
            completion()
            pickedSquares.removeAll()
            enPassant = false
            enPassantSquares.removeAll()
        }
        completion()
    }
    
    // calculates squares where player can move picked figure
    private func calculateAvailableSquares() {
        availableSquares = []
        // because columns represented as enum we need to calculate column index to represent column as number
        if let currentSquare = pickedSquares.first, let currentFigure = currentSquare.figure, let currentColumnIndex = GameBoard.availableColumns.firstIndex(of: currentSquare.column)  {
            if currentFigure.name == .pawn {
                calculateAvailableSquaresForPawn(currentSquare: currentSquare, currentFigure: currentFigure, currentColumnIndex: currentColumnIndex)
            }
        }
    }
    
    private func calculateAvailableSquaresForPawn(currentSquare: Square, currentFigure: Figure, currentColumnIndex: Int) {
        var rowDistance = 0
        if currentFigure.color == .white {
            rowDistance = -1
        }
        else {
            rowDistance = 1
        }
        if currentSquare.row == 2 || currentSquare.row == 7 {
            availableSquares += gameBoard.squares.filter({$0.row - currentSquare.row == rowDistance * 2 && $0.column == currentSquare.column && $0.figure == nil})
        }
        availableSquares += gameBoard.squares.filter({$0.row - currentSquare.row == rowDistance && $0.column == currentSquare.column && $0.figure == nil})
        for square in gameBoard.squares {
            let columnIndex = GameBoard.availableColumns.firstIndex(of: square.column)
            if let figure = square.figure, let columnIndex = columnIndex, figure.color != currentFigure.color {
                if square.row == currentSquare.row + rowDistance && abs(columnIndex - currentColumnIndex) == 1 {
                    availableSquares.append(square)
                }
                if abs(columnIndex - currentColumnIndex) == 1 && square.row == currentSquare.row {
                    if figure.name == .pawn && figure.color != currentFigure.color {
                        if let turn = turns.last, turn.squares.contains(square) && turn.squares[1].row - turn.squares[0].row == -rowDistance * 2  {
                            let enPassantSquare = gameBoard.squares.first(where: {$0.column == square.column && $0.row == square.row + rowDistance})
                            if let enPassantSquare = enPassantSquare {
                                availableSquares.append(enPassantSquare)
                                enPassantSquares.append(enPassantSquare)
                                enPassant = true
                            }
                        }
                    }
                }
            }
        }
    }

}

// MARK: - Constants

private struct GameLogic_Constants {
    
}
