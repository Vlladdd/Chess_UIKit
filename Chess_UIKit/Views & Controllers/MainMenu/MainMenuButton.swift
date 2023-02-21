//
//  MainMenuButton.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 14.09.2022.
//

import UIKit

//class that represents custom button for main menu
class MainMenuButton: UIButton {
    
    // MARK: - Properties
    
    private typealias constants = MainMenuButton_Constants
    
    private lazy var defaultColor = traitCollection.userInterfaceStyle == .dark ?  constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
    
    // MARK: - Inits
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = defaultColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = true
        backgroundColor = constants.toggleColor
        super.touchesBegan(touches, with: event)
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = false
        backgroundColor = defaultColor
        super.touchesEnded(touches, with: event)
    }

    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = false
        backgroundColor = defaultColor
        super.touchesCancelled(touches, with: event)
    }

}

// MARK: - Constants

private struct MainMenuButton_Constants {
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let toggleColor = UIColor.green.withAlphaComponent(optimalAlpha)
}
