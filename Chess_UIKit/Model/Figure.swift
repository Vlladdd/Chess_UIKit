//
//  Figure.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 14.06.2022.
//

import Foundation

//struct that represents game figure
struct Figure: Equatable {
    let name: Figures
    let color: GameColors
    //can be used in puzzles too
    let startColumn: BoardFiles
    let startRow: Int
}
