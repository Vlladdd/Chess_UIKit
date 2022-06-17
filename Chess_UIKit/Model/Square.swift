//
//  Square.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.06.2022.
//

import Foundation

//struct that represents square of the game board
struct Square: Equatable {
    
    let column: BoardFiles
    let row: Int
    let color: GameColors
    var figure: Figure?
    
    static func == (lhs: Square, rhs: Square) -> Bool {
        lhs.column == rhs.column && lhs.row == rhs.row
    }
    
}
