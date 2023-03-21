//
//  SquaresTheme.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 28.06.2022.
//

import Foundation
 
//struct that represents theme of the squares of the game
struct SquaresTheme: Equatable, Codable {
    
    var name: SquaresThemes = .defaultTheme
    //e.g. black/white
    var firstColor: Colors = .black
    var secondColor: Colors = .black
    var turnColor: Colors = .black
    var availableSquaresColor: Colors = .black
    var pickColor: Colors = .black
    var checkColor: Colors = .black
    
    //to prevent big inits
    init() {}
    
}
