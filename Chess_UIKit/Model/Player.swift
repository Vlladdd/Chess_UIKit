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
    var frame: Frames = .defaultFrame
    var figuresTheme: FiguresThemes = .defaultTheme
    var boardTheme: BoardThemes = .defaultTheme
    var coins: Int = 0
    var points: Int = 0
    var rank: Ranks = .bronze
    var shortCastleAvailable = true
    var longCastleAvailable = true
    let type: GamePlayers
    let figuresColor: GameColors
    
    // MARK: - Methods
    
    mutating func updateCastleInfo(short: Bool = true, long: Bool = true) {
        shortCastleAvailable = short
        longCastleAvailable = long
    }
}
