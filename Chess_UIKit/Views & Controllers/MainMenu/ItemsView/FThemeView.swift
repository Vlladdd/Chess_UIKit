//
//  FThemeView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 04.02.2023.
//

import UIKit

//class that represents view of figures theme
class FThemeView: Showcase {
    
    // MARK: - Properties
    
    private typealias constants = FThemeView_Constants
    
    // MARK: - Inits
    
    init(figuresTheme: FiguresThemes) {
        let dataStack = FThemeView.makeDataStack(with: figuresTheme)
        super.init(items: dataStack, item: figuresTheme, axis: .vertical)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private static func makeDataStack(with figuresTheme: FiguresThemes) -> UIStackView {
        let figuresStack = UIStackView()
        figuresStack.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        for figureType in Figures.allCases {
            for color in [GameColors.white, GameColors.black] {
                let figureView = UIImageView()
                figureView.makeSquareView(with: figuresTheme.getSkinedFigure(from: Figure(type: figureType, color: color)))
                figuresStack.addArrangedSubview(figureView)
            }
        }
        return figuresStack
    }
    
}

// MARK: - Constants

private struct FThemeView_Constants {
    static let optimalSpacing = 5.0
}
