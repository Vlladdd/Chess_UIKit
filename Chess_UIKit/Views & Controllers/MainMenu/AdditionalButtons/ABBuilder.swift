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
    
    weak var delegate: MainMenuViewDelegate?

    private var product = AdditionalButtons()
    
    private let storage = Storage.sharedInstance
    
    private typealias constants = ABBuilder_Constants
    
    // MARK: - Inits
    
    init(delegate: MainMenuViewDelegate) {
        self.delegate = delegate
    }
    
    // MARK: - Methods

    func reset() {
        product = AdditionalButtons()
    }

    //adds back button to product
    func addBackButton(type: BackButtonType) -> Self {
        if let delegate {
            var backView = UIStackView()
            switch type {
            case .toMainMenu:
                backView = MMBasicButtons(delegate: delegate)
            case .toInventoryMenu:
                backView = MMItemsButtons(delegate: delegate, isShopItems: false)
            case .toShopMenu:
                backView = MMItemsButtons(delegate: delegate, isShopItems: true)
            case .toGameMenu:
                backView = MMGameButtons(delegate: delegate)
            }
            let backButton = BackButton(backView: backView, delegate: delegate)
            product.addArrangedSubview(backButton)
        }
        return self
    }
    
    //adds view with coins info to product
    func addCoinsView() -> Self {
        if let delegate {
            let coinsText = UILabel()
            let coinsView = MMButtonView(backgroundImageItem: MiscImages.coinsBG, buttonImageItem: nil, buttontext: "", action: nil, fontSize: delegate.font.pointSize, needHeightConstraint: true)
            coinsText.setup(text: String(storage.currentUser.coins), alignment: .center, font: delegate.font)
            coinsText.backgroundColor = product.traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
            coinsView.addSubview(coinsText)
            let coinsTextConstraints = [coinsText.topAnchor.constraint(equalTo: coinsView.topAnchor), coinsText.bottomAnchor.constraint(equalTo: coinsView.bottomAnchor), coinsText.leadingAnchor.constraint(equalTo: coinsView.leadingAnchor), coinsText.trailingAnchor.constraint(equalTo: coinsView.trailingAnchor)]
            NSLayoutConstraint.activate(coinsTextConstraints)
            product.addArrangedSubview(coinsView)
            product.updateCoinsText(with: coinsText)
        }
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

