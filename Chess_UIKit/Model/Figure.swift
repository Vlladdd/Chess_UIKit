//
//  Figure.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 14.06.2022.
//

import Foundation

//struct that represents game figure
struct Figure: Equatable, Codable, ImageItem {
    
    // MARK: - Properties
    
    var name: String {
        color.asString + type.asString.capitalizingFirstLetter()
    }
    
    let type: Figures
    let color: GameColors
    //can be used in puzzles too
    let startColumn: BoardFiles
    let startRow: Int
    
    // MARK: - Inits
    
    //sometimes we don`t need column and row, so they are random,
    //other variant is to make those variables optionals
    init(type: Figures, color: GameColors, startColumn: BoardFiles = .A, startRow: Int = 1) {
        self.type = type
        self.color = color
        self.startColumn = startColumn
        self.startRow = startRow
    }
    
}
