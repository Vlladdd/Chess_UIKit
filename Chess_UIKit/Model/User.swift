//
//  User.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 10.09.2022.
//

import Foundation

//struct that represents user
struct User: Codable {
    
    // MARK: - Properties
    
    private(set) var name: String
    private(set) var email: String
    private(set) var squaresTheme = SquaresTheme(name: .defaultTheme, firstColor: .white, secondColor: .black, turnColor: .orange, availableSquaresColor: .green, pickColor: .red, checkColor: .blue)
    //background of player part of the screen
    private(set) var background: Backgrounds = .defaultBackground
    //background of player trash and name
    private(set) var playerBackground: Backgrounds = .defaultBackground
    private(set) var frame: Frames = .ukraineFlag
    private(set) var figuresTheme: FiguresThemes = .defaultTheme
    private(set) var boardTheme: BoardThemes = .defaultTheme
    private(set) var coins: Int = 0
    private(set) var points: Int = 0 {
        didSet {
            rank = getRank(from: points)
        }
    }
    private(set) var rank: Ranks = .bronze
    private(set) var title: Titles = .novice
    private(set) var games = [GameLogic]()
    
    //storing encryptionKey along with the password is probably a bad idea, but that`s how it`s for now
    enum CodingKeys: String, CodingKey {
        case name, email, games, points
    }
    
    // MARK: - Inits
    
    //we are making name same as email, but user can change it later on
    init(email: String) {
        self.name = email
        self.email = email
    }
    
    //Firebase don`t store empty arrays, that`s why we need custom decoder
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        email = try values.decode(String.self, forKey: .email)
        points = try values.decode(Int.self, forKey: .points)
        games = (try? values.decode([GameLogic].self, forKey: .games)) ?? []
    }
    
    // MARK: - Methods
    
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
    
    mutating func addGame(_ game: GameLogic) {
        if games.firstIndex(where: {$0.startDate == game.startDate}) == nil {
            games.append(game)
        }
    }
    
    mutating func removeGame(_ game: GameLogic) {
        if let gameIndex = games.firstIndex(where: {$0.startDate == game.startDate}) {
            games.remove(at: gameIndex)
        }
    }
    
    mutating func addPoints(_ points: Int) {
        self.points += points
    }
    
    mutating func addCoins(_ coins: Int) {
        self.coins += coins
    }
    
}
