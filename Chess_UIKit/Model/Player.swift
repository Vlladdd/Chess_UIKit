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
            if points > rank.maximumPoints {
                rank = rank.nextRank
            }
            else if points < rank.minimumPoints {
                rank = rank.previousRank
            }
        }
    }
    var pointsForGame = 0
    var rank: Ranks = .bronze
    var title: Titles = .novice
    var shortCastleAvailable = true
    var longCastleAvailable = true
    let type: GamePlayers
    let figuresColor: GameColors
    
    // MARK: - Methods
    
    mutating func updateCastleInfo(short: Bool = true, long: Bool = true) {
        shortCastleAvailable = short
        longCastleAvailable = long
    }
    
    mutating func addPoints(_ points: Int) {
        pointsForGame = points
        self.points += pointsForGame
    }
    
}
