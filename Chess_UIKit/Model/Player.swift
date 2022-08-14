//
//  Player.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 16.06.2022.
//

import Foundation

//struct that represents player
struct Player: Equatable {
    
    // MARK: - Properties
    
    let name: String
    var squaresTheme = SquaresTheme(name: .defaultTheme, firstColor: .white, secondColor: .black, turnColor: .orange, availableSquaresColor: .green, pickColor: .red, checkColor: .blue)
    //background of player part of the screen
    var background: Backgrounds = .defaultBackground
    //background of player trash and name
    var playerBackground: Backgrounds = .defaultBackground
    var frame: Frames = .ukraineFlag
    var figuresTheme: FiguresThemes = .defaultTheme
    var boardTheme: BoardThemes = .defaultTheme
    var coins: Int = 0
    var points: Int = 0 {
        didSet {
            rank = getRank(from: points)
        }
    }
    var pointsForGame = 0
    var rank: Ranks = .bronze
    var title: Titles = .novice
    let type: GamePlayers
    let figuresColor: GameColors
    var timeLeft = 300
    
    // MARK: - Methods
    
    mutating func addPoints(_ points: Int) {
        pointsForGame = points
        self.points += pointsForGame
    }
    
    func getRank(from points: Int) -> Ranks {
        switch points {
        case _ where points >= Ranks.bronze.minimumPoints && points <= Ranks.bronze.maximumPoints:
            return .bronze
        case _ where points >= Ranks.silver.minimumPoints && points <= Ranks.silver.maximumPoints:
            return .silver
        case _ where points >= Ranks.gold.minimumPoints && points <= Ranks.gold.maximumPoints:
            return .gold
        case _ where points >= Ranks.diamond.minimumPoints && points <= Ranks.diamond.maximumPoints:
            return .diamond
        case _ where points >= Ranks.master.minimumPoints:
            return .master
        default:
            return .bronze
        }
    }
    
}
