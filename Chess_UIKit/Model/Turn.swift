//
//  Turn.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 16.06.2022.
//

import Foundation

//struct that represents game turn
struct Turn: Equatable {
    //turns could be same, this makes them unique
    let time = Date()
    var squares: [Square]
    //when pawn reaches last row
    var pawnTransform: Figure? = nil
    //pawn to be destroyed after en passant
    var pawnSquare: Square? = nil
    var turnDuration: Int
}
