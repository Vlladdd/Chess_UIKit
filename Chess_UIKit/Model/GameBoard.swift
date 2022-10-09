//
//  GameBoard.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.06.2022.
//

import Foundation

//struct that represents game board
struct GameBoard: Codable {
    
    // MARK: - Properties
    
    private(set) var squares: [Square]
    
    static let availableRows = constants.allRows
    static let availableColumns = BoardFiles.allCases
    
    private typealias constants = GameBoard_Constants
    
    // MARK: - Inits
    
    init() {
        squares = GameBoard.makeGameBoard()
    }
    
    // MARK: - Methods
    
    private static func makeGameBoard() -> [Square] {
        var gameSquares = [Square]()
        //switches black and white color for the square
        var switcher = true
        for column in availableColumns {
            for row in availableRows {
                var figure: Figure?
                var color = constants.squareSecondColor
                if !switcher {
                    color = constants.squareFirstColor
                }
                figure = constants.getFigure(column: column, row: row)
                gameSquares.append(Square(column: column, row: row, color: color, figure: figure))
                switcher.toggle()
            }
            switcher.toggle()
        }
        return gameSquares
    }
    
    subscript (column: BoardFiles, row: Int) -> Square?{
        get {
            squares.first(where: {$0.column == column && $0.row == row})
        }
    }
    
    //updates squares after player turn
    mutating func updateSquares(firstSquare: Square, secondSquare: Square) {
        if let firstSquareIndex = squares.firstIndex(of: firstSquare), let secondSquareIndex = squares.firstIndex(of: secondSquare) {
            squares[secondSquareIndex].updateFigure(newValue: squares[firstSquareIndex].figure)
            squares[firstSquareIndex].updateFigure()
        }
    }
    
    mutating func updateSquare(square: Square, figure: Figure? = nil) {
        if let squareIndex = squares.firstIndex(of: square) {
            squares[squareIndex].updateFigure(newValue: figure)
        }
    }
    
}

// MARK: - Constants

private struct GameBoard_Constants {
    
    // MARK: - Properties
    
    static let squareFirstColor = GameColors.white
    static let squareSecondColor = GameColors.black
    static let allRows = 1...8
    
    private static let startRowsForWhite = [1,2]
    private static let startRowsForBlack = [7,8]
    
    // MARK: - Methods
    
    //places figures on start squares
    static func getFigure(column: BoardFiles, row: Int) -> Figure? {
        let figureColor = startRowsForWhite.contains(row) ? GameColors.white : GameColors.black
        if row == startRowsForWhite.first! || row == startRowsForBlack.second! {
            switch column {
            case .A, .H:
                return Figure(name: .rook, color: figureColor, startColumn: column, startRow: row)
            case .B, .G:
                return Figure(name: .knight, color: figureColor, startColumn: column, startRow: row)
            case .C, .F:
                return Figure(name: .bishop, color: figureColor, startColumn: column, startRow: row)
            case .E:
                return Figure(name: .king, color: figureColor, startColumn: column, startRow: row)
            case .D:
                return Figure(name: .queen, color: figureColor, startColumn: column, startRow: row)
            }
        }
        else if row == startRowsForWhite.second! || row == startRowsForBlack.first! {
            return Figure(name: .pawn, color: figureColor, startColumn: column, startRow: row)
        }
        return nil
    }
}
