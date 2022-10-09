//
//  Square.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.06.2022.
//

import Foundation

//struct that represents square of the game board
struct Square: Equatable, Codable {
    
    // MARK: - Properties
    
    let column: BoardFiles
    let row: Int
    let color: GameColors
    
    private(set) var figure: Figure?
    
    // MARK: - Methods
    
    static func == (lhs: Square, rhs: Square) -> Bool {
        lhs.column == rhs.column && lhs.row == rhs.row
    }
    
    mutating func updateFigure(newValue: Figure? = nil) {
        figure = newValue
    }
    
}
