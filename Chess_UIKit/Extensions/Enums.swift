//
//  Enums.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.06.2022.
//

import Foundation

// MARK: - Some usefull enums

//columns in chess called files
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
    
    var index: Int {
        switch self {
        case .A:
            return 1
        case .B:
            return 2
        case .C:
            return 3
        case .D:
            return 4
        case .E:
            return 5
        case .F:
            return 6
        case .G:
            return 7
        case .H:
            return 8
        }
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
    
    func opposite() -> Self {
        switch self {
        case .white:
            return .black
        case .black:
            return .white
        }
    }
}

enum Colors: String {
    case white
    case black
    case blue
    case orange
    case red
    case green
}

enum SquaresThemes: String {
    case defaultTheme
}

enum FiguresThemes: String {
    case defaultTheme
}

enum BoardThemes: String {
    case defaultTheme
}

enum Frames: String {
    case defaultFrame
    case ukraineFlag
}

enum Backgrounds: String {
    case defaultBackground
}

enum Ranks: String {
    case bronze
    case silver
    case gold
    case diamond
    case master
    
    var minimumPoints: Int {
        switch self {
        case .bronze:
            return 0
        case .silver:
            return 501
        case .gold:
            return 1501
        case .diamond:
            return 3001
        case .master:
            return 10001
        }
    }
    
    var maximumPoints: Int {
        switch self {
        case .bronze:
            return 500
        case .silver:
            return 1500
        case .gold:
            return 3000
        case .diamond:
            return 10000
        case .master:
            return Int.max
        }
    }
    
    var nextRank: Self {
        switch self {
        case .bronze:
            return .silver
        case .silver:
            return .gold
        case .gold:
            return .diamond
        case .diamond:
            return .master
        case .master:
            return .master
        }
    }
    
    var previousRank: Self {
        switch self {
        case .bronze:
            return .bronze
        case .silver:
            return .bronze
        case .gold:
            return .silver
        case .diamond:
            return .gold
        case .master:
            return .diamond
        }
    }
    
    //used in points calculation
    var factor: Int {
        switch self {
        case .bronze:
            return 2
        case .silver:
            return 4
        case .gold:
            return 8
        case .diamond:
            return 16
        case .master:
            return 32
        }
    }
    
}

enum Titles: String {
    case novice
    case admin
    case the_Chosen_One
}

enum GameModes: String {
    case oneScreen
    case multiplayer
}
