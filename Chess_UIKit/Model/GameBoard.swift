//
//  GameBoard.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.06.2022.
//

import Foundation

//struct that represents game board
struct GameBoard {
    
    // MARK: - Properties
    
    var squares: [Square]
    var theme = Theme(name: .defaultTheme, darkMode: true)
    static let availableRows = GameBoard_Constants.allRows
    static let availableColumns = BoardFiles.allCases
    
    // MARK: - Inits
    
    init() {
        squares = GameBoard.makeGameBoard()
    }
    
    // MARK: - Methods
    
    private static func makeGameBoard() -> [Square] {
        var gameSquares = [Square]()
        // switches black and white color for the square
        var switcher = true
        for column in availableColumns {
            for row in availableRows {
                var figure: Figure?
                var color = GameColors.white
                if !switcher {
                    color = .black
                }
                if row == 1 {
                    figure = getFigure(squareName: column, color: .black)
                }
                if row == 8 {
                    figure = getFigure(squareName: column, color: .white)
                }
                if row == 2 {
                    figure = Figure(name: .pawn, color: .black)
                }
                if row == 7 {
                    figure = Figure(name: .pawn, color: .white)
                }
                gameSquares.append(Square(column: column, row: row, color: color, figure: figure))
                switcher.toggle()
            }
            switcher.toggle()
        }
        return gameSquares
    }
    
    // places figures on start squares
    private static func getFigure(squareName: BoardFiles, color: GameColors) -> Figure{
        switch squareName {
        case .A, .H:
            return Figure(name: .rook, color: color)
        case .B, .G:
            return Figure(name: .knight, color: color)
        case .C, .F:
            return Figure(name: .bishop, color: color)
        case .D:
            return Figure(name: .king, color: color)
        case .E:
            return Figure(name: .queen, color: color)
        }
    }
    
    subscript (column: BoardFiles, row: Int) -> Square?{
        get {
            squares.first(where: {$0.column == column && $0.row == row})
        }
    }
    
    // updates squares after player turn
    mutating func updateSquares(firstSquare: Square, secondSquare: Square) {
        if let firstIndex = squares.firstIndex(of: firstSquare), let secondIndex = squares.firstIndex(of: secondSquare) {
            squares[secondIndex].figure = squares[firstIndex].figure
            squares[firstIndex].figure = nil
        }
    }
    
    mutating func updateSquare(square: Square, figure: Figure? = nil) {
        if let index = squares.firstIndex(of: square) {
            squares[index].figure = figure
        }
    }
    
}

// MARK: - Constants

private struct GameBoard_Constants {
    static let allRows = 1...8
}
