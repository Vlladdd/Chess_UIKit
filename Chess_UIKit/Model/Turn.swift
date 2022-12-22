//
//  Turn.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 16.06.2022.
//

import Foundation

//struct that represents game turn
struct Turn: Equatable, Codable {
    
    // MARK: - Properties
    
    //useful for multiplayer games
    let gameID: String?
    let squares: [Square]
    //useful for multiplayer games, to be sure, that timers are synchronized
    //otherwise, if player1 made turn and player2 received that turn with some delay,
    //player2 will have a wrong timer and timers will be desynchronized
    let timeLeft: Int
    
    //turns could be same, this makes them unique
    private(set) var time: Date
    //when pawn reaches last row
    private(set) var pawnTransform: Figure?
    //pawn to be destroyed after en passant
    private(set) var pawnSquare: Square?
    private(set) var turnDuration: Int
    private(set) var shortCastle: Bool
    private(set) var longCastle: Bool
    private(set) var check: Bool
    private(set) var checkMate: Bool
    //square with enemy king, when check or checkmate
    private(set) var checkSquare: Square?
    
    // MARK: - Inits
    
    init(squares: [Square], turnDuration: Int, shortCastle: Bool, longCastle: Bool, check: Bool, checkMate: Bool, timeLeft: Int, time: Date = Date(), pawnTransform: Figure? = nil, pawnSquare: Square? = nil, checkSquare: Square? = nil, gameID: String? = nil) {
        self.timeLeft = timeLeft
        self.gameID = gameID
        self.time = time
        self.squares = squares
        self.pawnTransform = pawnTransform
        self.pawnSquare = pawnSquare
        self.turnDuration = turnDuration
        self.shortCastle = shortCastle
        self.longCastle = longCastle
        self.check = check
        self.checkMate = checkMate
        self.checkSquare = checkSquare
    }
    
    // MARK: - Methods
    
    mutating func updateCastle(short: Bool = false, long: Bool = false) {
        shortCastle = short
        longCastle = long
    }
    
    mutating func updatePawnTransform(newValue: Figure? = nil) {
        pawnTransform = newValue
    }
    
    mutating func updateTurnDuration(newValue: Int) {
        turnDuration = newValue
    }
    
    mutating func updateCheck(_ check: Bool = false, checkMate: Bool = false, checkSquare: Square? = nil) {
        self.check = check
        self.checkMate = checkMate
        self.checkSquare = checkSquare
    }
    
    mutating func updatePawnSquare(newValue: Square? = nil) {
        pawnSquare = newValue
    }
    
    //useful when pawn reached last row and we are waiting for player
    //to pick new figure and after that the actual time of turn will be changed
    mutating func updateTime(newValue: Date) {
        time = newValue
    }
    
}
