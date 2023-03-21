//
//  ABBuilder.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 08.02.2023.
//

import UIKit

//class that represents builder for additional buttons
class ABBuilder: AdditionalButtonsBuilder {
    
    // MARK: - Properties

    private var product = AdditionalButtons()
    
    private typealias constants = ABBuilder_Constants
    
    // MARK: - Methods

    func reset() {
        product = AdditionalButtons()
    }

    //adds back button to product
    func addBackButton(with font: UIFont) -> Self {
        let backButton = BackButton(font: font)
        product.addArrangedSubview(backButton)
        product.updateBackButton(with: backButton)
        return self
    }
    
    //adds view with coins info to product
    func addCoinsView(with font: UIFont, and coins: Int) -> Self {
        let coinsText = UILabel()
        let coinsView = MMButtonView(backgroundImageItem: MiscImages.coinsBG, buttonImageItem: nil, buttontext: "", action: nil, font: font, needHeightConstraint: true)
        coinsText.setup(text: String(coins), alignment: .center, font: font)
        coinsText.backgroundColor = product.traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        coinsView.addSubview(coinsText)
        let coinsTextConstraints = [coinsText.topAnchor.constraint(equalTo: coinsView.topAnchor), coinsText.bottomAnchor.constraint(equalTo: coinsView.bottomAnchor), coinsText.leadingAnchor.constraint(equalTo: coinsView.leadingAnchor), coinsText.trailingAnchor.constraint(equalTo: coinsView.trailingAnchor)]
        NSLayoutConstraint.activate(coinsTextConstraints)
        product.addArrangedSubview(coinsView)
        product.updateCoinsText(with: coinsText)
        return self
    }
    
    //returns product at current state and resets it
    func build() -> AdditionalButtons {
        let result = self.product
        reset()
        return result
    }
    
}

// MARK: - Constants

private struct ABBuilder_Constants {
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
}

