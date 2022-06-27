//
//  ThemeView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 27.06.2022.
//

import UIKit

//interpretation of theme for UI
class ThemeView: UIImageView {

    let name: Themes
    let squareFirstColor: UIColor
    let squareSecondColor: UIColor
    let pickColor: UIColor
    let availableFieldsColor: UIColor
    let turnColor: UIColor
    let checkColor: UIColor
    
    init(name: Themes, squareFirstColor: UIColor, squareSecondColor: UIColor, pickColor: UIColor, availableFIeldsColor: UIColor, turnColor: UIColor, checkColor: UIColor, image: UIImage?) {
        self.name = name
        self.squareFirstColor = squareFirstColor
        self.squareSecondColor = squareSecondColor
        self.pickColor = pickColor
        self.availableFieldsColor = availableFIeldsColor
        self.turnColor = turnColor
        self.checkColor = checkColor
        super.init(frame: .zero)
        self.image = image
        backgroundColor = .none
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
