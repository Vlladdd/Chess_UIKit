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
    var frame: Frames = .defaultFrame
    var coins: Int = 0
    var points: Int = 0
    var rank: Ranks = .bronze
    var shortCastleAvailable = true
    var longCastleAvailable = true
    let type: GamePlayers
    
    // MARK: - Methods
    
    mutating func updateCastleInfo(short: Bool = true, long: Bool = true) {
        shortCastleAvailable = short
        longCastleAvailable = long
    }
}
