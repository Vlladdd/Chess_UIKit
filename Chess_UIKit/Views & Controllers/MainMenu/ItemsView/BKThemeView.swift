//
//  BKThemeView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 04.02.2023.
//

import UIKit

//class that represents view of background theme
class BKThemeView: UIImageView, ItemView {
    
    // MARK: - ItemView
    
    let item: GameItem
    
    // MARK: - Properties
    
    private typealias constants = BKThemeView_Constants
    
    // MARK: - Inits
    
    init(backgroundTheme: Backgrounds, font: UIFont) {
        item = backgroundTheme
        super.init(frame: .zero)
        setup(font: font)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup(font: UIFont) {
        let backgroundTheme = item as! Backgrounds
        defaultSettings()
        setImage(with: backgroundTheme)
        let backgroundLabel = UILabel()
        backgroundLabel.setup(text: backgroundTheme.getHumanReadableName(), alignment: .center, font: font)
        addSubview(backgroundLabel)
        backgroundLabel.backgroundColor = backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        let backgroundLabelConstraints = [backgroundLabel.leadingAnchor.constraint(equalTo: leadingAnchor), backgroundLabel.trailingAnchor.constraint(equalTo: trailingAnchor), backgroundLabel.topAnchor.constraint(equalTo: topAnchor), backgroundLabel.bottomAnchor.constraint(equalTo: bottomAnchor)]
        NSLayoutConstraint.activate(backgroundLabelConstraints)
    }
    
}

// MARK: - Constants

private struct BKThemeView_Constants {
    static let optimalAlpha = 0.5
}
