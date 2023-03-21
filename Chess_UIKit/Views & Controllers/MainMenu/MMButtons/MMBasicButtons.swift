//
//  MMBasicButtons.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.02.2023.
//

import UIKit

// MARK: - MMBasicButtonsDelegate

protocol MMBasicButtonsDelegate: AnyObject {
    func basicButtonsDidTriggerInventoryMenu(_ basicButtons: MMBasicButtons) -> Void
    func basicButtonsDidTriggerShopMenu(_ basicButtons: MMBasicButtons) -> Void
    func basicButtonsDidTriggerGameMenu(_ basicButtons: MMBasicButtons) -> Void
}

// MARK: - MMBasicButtons

//class that represents first buttons in main menu
class MMBasicButtons: UIStackView {
    
    // MARK: - Properties
    
    weak var delegate: MMBasicButtonsDelegate?
    
    private typealias constants = MMBasicButtons_Constants
    
    private(set) var shopButtonView: ViewWithNotifIcon!
    private(set) var inventoryButtonView: ViewWithNotifIcon!
    
    // MARK: - Inits
    
    init(font: UIFont) {
        super.init(frame: .zero)
        setup(with: font)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func makeInventoryMenu(_ sender: UIButton? = nil) {
        delegate?.basicButtonsDidTriggerInventoryMenu(self)
    }
    
    @objc private func makeShopMenu(_ sender: UIButton? = nil) {
        delegate?.basicButtonsDidTriggerShopMenu(self)
    }
    
    @objc private func makeGameMenu(_ sender: UIButton? = nil) {
        delegate?.basicButtonsDidTriggerGameMenu(self)
    }
    
    // MARK: - Local Methods
    
    private func setup(with font: UIFont) {
        setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let gameButton = MMButtonView(backgroundImageItem: MiscImages.gameButtonBG, buttonImageItem: nil, buttontext: "Game", action: #selector(makeGameMenu), font: font, needHeightConstraint: true)
        let inventoryButton = MMButtonView(backgroundImageItem: MiscImages.inventoryButtonBG, buttonImageItem: nil, buttontext: "Inventory", action: #selector(makeInventoryMenu), font: font, needHeightConstraint: false)
        inventoryButtonView = ViewWithNotifIcon(mainView: inventoryButton, height: MMButtonView.getOptimalHeight(with: font.pointSize))
        let shopButton = MMButtonView(backgroundImageItem: MiscImages.shopButtonBG, buttonImageItem: nil, buttontext: "Shop", action: #selector(makeShopMenu), font: font, needHeightConstraint: false)
        shopButtonView = ViewWithNotifIcon(mainView: shopButton, height: MMButtonView.getOptimalHeight(with: font.pointSize))
        addArrangedSubviews([gameButton, inventoryButtonView, shopButtonView])
    }
    
}

// MARK: - Constants

private struct MMBasicButtons_Constants {
    static let optimalSpacing = 5.0
}
