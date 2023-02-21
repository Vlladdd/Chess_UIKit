//
//  BThemeView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 04.02.2023.
//

import UIKit

//class that represents view of board theme
class BThemeView: Showcase {
    
    // MARK: - Properties
    
    private typealias constants = BThemeView_Constants
    
    // MARK: - Inits
    
    init(boardTheme: BoardThemes) {
        let dataStack = BThemeView.makeDataStack(with: boardTheme)
        super.init(items: dataStack, item: boardTheme, axis: .vertical)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private static func makeDataStack(with boardTheme: BoardThemes) -> UIStackView {
        let boardItems = UIStackView()
        boardItems.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let emptySquare = UIImageView()
        emptySquare.makeSquareView(with: boardTheme.emptySquareItem)
        boardItems.addArrangedSubview(emptySquare)
        for file in BoardFiles.allCases {
            let fileView = UIImageView()
            fileView.makeSquareView(with: boardTheme.getSkinedLetter(from: file))
            boardItems.addArrangedSubview(fileView)
        }
        for number in BoardNumberItems.allCases {
            let numberSquare = UIImageView()
            numberSquare.makeSpecialSquareView(with: boardTheme.emptySquareItem, and: boardTheme.getSkinedNumber(from: number), multiplier: constants.multiplierForSpecialSquareViewSize)
            boardItems.addArrangedSubview(numberSquare)
        }
        return boardItems
    }
    
}

// MARK: - Constants

private struct BThemeView_Constants {
    static let optimalSpacing = 5.0
    static let multiplierForSpecialSquareViewSize = 0.6
}
