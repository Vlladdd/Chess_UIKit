//
//  Enums.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.06.2022.
//

import Foundation

// MARK: - Some usefull enums

// columns in chess called files
enum BoardFiles: String, CaseIterable, Equatable, Comparable {
    
    case A
    case B
    case C
    case D
    case E
    case F
    case G
    case H
    
    static func < (lhs: BoardFiles, rhs: BoardFiles) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
}

enum Figures: String, Equatable {
    case pawn
    case rook
    case knight
    case bishop
    case queen
    case king
}

enum GamePlayers: String {
    case player1
    case player2
}

enum GameColors: String {
    case white
    case black
}

enum Themes: String {
    case defaultTheme
}

enum Frames: String {
    case defaultFrame
}

enum Ranks: String {
    case bronze
    case silver
    case gold
    case diamond
    case master
}
