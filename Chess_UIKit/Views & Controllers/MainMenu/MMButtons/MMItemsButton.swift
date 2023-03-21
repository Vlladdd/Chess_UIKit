//
//  MMItemsButton.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 07.02.2023.
//

import UIKit

// MARK: - MMItemsButtonDelegate

protocol MMItemsButtonDelegate: AnyObject {
    func itemsButtonDidTriggerMakeListOfItems(_ itemsButtons: MMItemsButton) -> Void
}

// MARK: - MMItemsButton

//class that represents inventory or shop button in main menu
class MMItemsButton: MMButtonView {
    
    // MARK: - Properties
    
    weak var delegate: MMItemsButtonDelegate?
    
    let items: [GameItem]
    let isShopItems: Bool
    
    // MARK: - Inits
    
    init(items: [GameItem], isShopItems: Bool, backgroundImageItem: ImageItem?, buttontext: String, font: UIFont) {
        self.items = items
        self.isShopItems = isShopItems
        super.init(backgroundImageItem: backgroundImageItem, buttonImageItem: nil, buttontext: buttontext, action: #selector(makeListOfItems), font: font, needHeightConstraint: false)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods

    //makes list of items of the same group
    @objc private func makeListOfItems(_ sender: UIButton? = nil) {
        delegate?.itemsButtonDidTriggerMakeListOfItems(self)
    }
    
}
