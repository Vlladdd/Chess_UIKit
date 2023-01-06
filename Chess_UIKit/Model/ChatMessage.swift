//
//  ChatMessage.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.12.2022.
//

import Foundation

//struct that represents chat message of the user
struct ChatMessage: Codable, Equatable {
    
    let date: Date
    let gameID: String
    //chess timer
    let timeLeft: Int
    let userNickname: String
    //nicknames can be the same or user can play against himself on different devices,
    //which is possible
    let playerType: MultiplayerPlayerType
    let userAvatar: Avatars
    let userFrame: Frames
    let message: String
    
}
