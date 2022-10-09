//
//  Player.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 16.06.2022.
//

import Foundation

//struct that represents player
struct Player: Equatable, Codable {

    // MARK: - Properties
    
    private(set) var user: User
    private(set) var pointsForGame = 0
    private(set) var timeLeft: Int
    private(set) var destroyedFigures = [Figure]()
            
    let type: GamePlayers
    let figuresColor: GameColors
    
    enum CodingKeys: String, CodingKey {
        case user
        case pointsForGame
        case type
        case figuresColor
        case timeLeft
        case destroyedFigures
    }
    
    //TODO: - Add more user data to player
    
    enum UserKeys: String, CodingKey {
        case name, email, points
    }
    
    //
    
    // MARK: - Inits
    
    init(user: User, type: GamePlayers, figuresColor: GameColors, timeLeft: Int) {
        self.user = user
        self.type = type
        self.figuresColor = figuresColor
        self.timeLeft = timeLeft
    }
    
    //Firebase don`t store empty arrays, that`s why we need custom decoder
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pointsForGame = try values.decode(Int.self, forKey: .pointsForGame)
        type = try values.decode(GamePlayers.self, forKey: .type)
        figuresColor = try values.decode(GameColors.self, forKey: .figuresColor)
        timeLeft = try values.decode(Int.self, forKey: .timeLeft)
        user = try values.decode(User.self, forKey: .user)
        destroyedFigures = (try? values.decode([Figure].self, forKey: .destroyedFigures)) ?? []
    }
    
    // MARK: - Methods
    
    mutating func addPointsToUser(_ points: Int) {
        pointsForGame = points
        user.addPoints(pointsForGame)
    }
    
    mutating func addCoinsToUser(_ coins: Int) {
        user.addCoins(coins)
    }
    
    mutating func updateTimeLeft(newValue: Int) {
        timeLeft = newValue
    }
    
    mutating func increaseTimeLeft(with value: Int) {
        timeLeft += value
    }
    
    mutating func addDestroyedFigure(_ figure: Figure) {
        destroyedFigures.append(figure)
    }
    
    mutating func removeDestroyedFigure(_ figure: Figure) {
        if let figureIndex = destroyedFigures.firstIndex(of: figure) {
            destroyedFigures.remove(at: figureIndex)
        }
    }
    
    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.type == rhs.type
    }
    
    //we don`t need all info about user to store in player, that`s why we use custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pointsForGame, forKey: .pointsForGame)
        try container.encode(type, forKey: .type)
        try container.encode(figuresColor, forKey: .figuresColor)
        try container.encode(timeLeft, forKey: .timeLeft)
        try container.encode(destroyedFigures, forKey: .destroyedFigures)
        var additionalInfo = container.nestedContainer(keyedBy: UserKeys.self, forKey: .user)
        try additionalInfo.encode(user.name, forKey: .name)
        try additionalInfo.encode(user.email, forKey: .email)
        try additionalInfo.encode(user.points, forKey: .points)
    }
    
}
