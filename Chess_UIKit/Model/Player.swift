//
//  Player.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 16.06.2022.
//

import Foundation

//struct that represents player
struct Player {
    let name: String
    var frame: Frames = .defaultFrame
    var coins: Int = 0
    var points: Int = 0
    var rank: Ranks = .bronze
}
