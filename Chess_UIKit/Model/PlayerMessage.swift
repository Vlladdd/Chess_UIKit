//
//  PlayerMessage.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 21.11.2022.
//

import Foundation

//struct that represents game message of the player
struct PlayerMessage: Codable {
    
    let gameID: String
    let playerType: MultiplayerPlayerType
    
    private(set) var date = Date()
    private(set) var gameEnded = false
    private(set) var gameDraw = false
    private(set) var player1Ready = false
    private(set) var player2Ready = false
    private(set) var opponentWantsDraw = false
    private(set) var requestLastAction = false
    private(set) var playerToSurrender: GamePlayers = .player2
    
}
