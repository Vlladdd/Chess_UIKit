//
//  SThemeView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 04.02.2023.
//

import UIKit

//class that represents view of squares theme
class SThemeView: Showcase {
    
    // MARK: - Properties
    
    private typealias constants = SThemeView_Constants
    
    // MARK: - Inits
    
    init(squaresTheme: SquaresThemes, font: UIFont) {
        let dataStack = SThemeView.makeDataStack(with: squaresTheme, and: font)
        super.init(items: dataStack, item: squaresTheme, axis: .horizontal)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private static func makeDataStack(with item: SquaresThemes, and font: UIFont) -> UIStackView {
        let squareTheme = item.getTheme()
        let dataStack = UIStackView()
        dataStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        dataStack.addArrangedSubview(makeColorData(with: "First Color", color: squareTheme.firstColor, font: font))
        dataStack.addArrangedSubview(makeColorData(with: "Second Color", color: squareTheme.secondColor, font: font))
        dataStack.addArrangedSubview(makeColorData(with: "Turn Color", color: squareTheme.turnColor, font: font))
        dataStack.addArrangedSubview(makeColorData(with: "Available squares Color", color: squareTheme.availableSquaresColor, font: font))
        dataStack.addArrangedSubview(makeColorData(with: "Pick Color", color: squareTheme.pickColor, font: font))
        dataStack.addArrangedSubview(makeColorData(with: "Check Color", color: squareTheme.checkColor, font: font))
        return dataStack
    }
    
    private static func makeColorData(with text: String, color: Colors, font: UIFont) -> UIStackView {
        let colorData = UIStackView()
        colorData.setup(axis: .horizontal, alignment: .fill, distribution: .fill, spacing: constants.optimalSpacing)
        let colorLabel = UILabel()
        colorLabel.setup(text: text, alignment: .center, font: font)
        let colorView = UIImageView()
        colorView.defaultSettings()
        colorView.backgroundColor = UIView.convertLogicColor(color)
        let colorViewConstraints = [colorView.widthAnchor.constraint(equalTo: colorView.heightAnchor)]
        NSLayoutConstraint.activate(colorViewConstraints)
        colorData.addArrangedSubviews([colorLabel, colorView])
        return colorData
    }
    
}

// MARK: - Constants

private struct SThemeView_Constants {
    static let optimalSpacing = 5.0
}
