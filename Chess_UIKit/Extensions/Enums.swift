//
//  Enums.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.06.2022.
//

import Foundation

// MARK: - Some usefull enums

//columns in chess called files
enum BoardFiles: String, CaseIterable, Equatable, Comparable, Codable {
    
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

enum Figures: String, Equatable, Codable, CaseIterable {
    case pawn
    case rook
    case knight
    case bishop
    case queen
    case king
}

enum GamePlayers: String, Codable {
    case player1
    case player2
}

enum GameColors: String, CaseIterable, Codable {
    case white
    case black
    case random
    
    func opposite() -> Self {
        switch self {
        case .white:
            return .black
        case .black:
            return .white
        case .random:
            return random()
        }
    }
    
    func random() -> Self {
        let possibleCases: [Self] = [.black, .white]
        return possibleCases.randomElement() ?? .random
    }
    
}

enum Colors: String, Codable {
    case white
    case black
    case blue
    case orange
    case red
    case green
}

enum SquaresThemes: String, Codable, CaseIterable, Item {
    case defaultTheme
    
    var cost: Int {
        switch self {
        case .defaultTheme:
            return 0
        }
    }
    
    var type: ItemTypes {
        .squaresTheme
    }
    
    var description: String {
        switch self {
        case .defaultTheme:
            return "Just a default theme, nothing special"
        }
    }
    
    func getTheme() -> SquaresTheme {
        switch self {
        case .defaultTheme:
            return SquaresTheme(name: .defaultTheme, firstColor: .white, secondColor: .black, turnColor: .orange, availableSquaresColor: .green, pickColor: .red, checkColor: .blue)
        }
    }
    
}

enum FiguresThemes: String, Codable, CaseIterable, Item {
    case defaultTheme
    
    var cost: Int {
        switch self {
        case .defaultTheme:
            return 0
        }
    }
    
    var type: ItemTypes {
        .figuresTheme
    }
    
    var description: String {
        switch self {
        case .defaultTheme:
            return "Just a default theme, nothing special"
        }
    }
    
}

enum BoardThemes: String, CaseIterable, Codable, Item {
    case defaultTheme
    
    var cost: Int {
        switch self {
        case .defaultTheme:
            return 0
        }
    }
    
    var type: ItemTypes {
        .boardTheme
    }
    
    var description: String {
        switch self {
        case .defaultTheme:
            return "Just a default theme, nothing special"
        }
    }
    
}

enum Frames: String, Codable, CaseIterable, Item {
    case defaultFrame
    case ukraineFlag
    
    var cost: Int {
        switch self {
        case .defaultFrame:
            return 0
        case .ukraineFlag:
            return 100
        }
    }
    
    var type: ItemTypes {
        .frame
    }
    
    var description: String {
        switch self {
        case .defaultFrame:
            return "Just a default frame, nothing special"
        case .ukraineFlag:
            return "Show support to Ukraine with this frame"
        }
    }
    
}

enum Backgrounds: String, Codable, CaseIterable, Item {
    case defaultBackground
    
    var cost: Int {
        switch self {
        case .defaultBackground:
            return 0
        }
    }
    
    var type: ItemTypes {
        .background
    }
    
    var description: String {
        switch self {
        case .defaultBackground:
            return "Just a default background, nothing special"
        }
    }
    
}

enum Avatars: String, Codable, CaseIterable, Item {
    case defaultAvatar
    
    var cost: Int {
        switch self {
        case .defaultAvatar:
            return 0
        }
    }
    
    var type: ItemTypes {
        .avatar
    }
    
    var description: String {
        switch self {
        case .defaultAvatar:
            return "Just a default avatar, nothing special"
        }
    }
    
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

enum Titles: String, Codable, CaseIterable, Item {
    case novice
    case admin
    case the_Chosen_One
    case waster
    
    static let purchachableTitles: [Self] = [.waster]
    
    var cost: Int {
        switch self {
        case .novice, .admin, .the_Chosen_One:
            return 0
        case .waster:
            return 10000
        }
    }
    
    var type: ItemTypes {
        .title
    }
    
    var description: String {
        switch self {
        case .novice:
            return "First step to become master"
        case .waster:
            return "You really spend 10000 coins for this?"
        case .admin:
            return "I am an admin, ye boy"
        case .the_Chosen_One:
            return "Gods believe in you"
        }
    }
    
    
}

enum GameModes: String, CaseIterable, Codable {
    case oneScreen
    case multiplayer
}

enum Answers: String, CaseIterable {
    case yes
    case no
}

enum ItemTypes: String, CaseIterable {
    case squaresTheme
    case figuresTheme
    case boardTheme
    case frame
    case background
    case title
    case avatar
}

protocol Item {
    var type: ItemTypes { get }
    var name: String { get }
    var cost: Int { get }
    var description: String { get }
}

extension Item where Self: RawRepresentable, Self.RawValue == String {
    var name: String { rawValue }
}
