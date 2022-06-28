//
//  SquaresTheme.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 28.06.2022.
//

import Foundation
 
//struct that represents theme of the squares of the game
struct SquaresTheme: Equatable {
    let name: SquaresThemes
    //e.g. black/white
    let firstColor: Colors
    let secondColor: Colors
    let turnColor: Colors
    let availableSquaresColor: Colors
    let pickColor: Colors
    let checkColor: Colors
}
