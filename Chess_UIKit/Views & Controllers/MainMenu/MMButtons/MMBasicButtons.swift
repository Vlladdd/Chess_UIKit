//
//  MMBasicButtons.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.02.2023.
//

import UIKit

//class that represents first buttons in main menu
class MMBasicButtons: UIStackView, NotificationIconsDelegate {
    
    // MARK: - NotificationIconsDelegate
    
    func updateNotificationIcons() {
        if storage.currentUser.haveNewItemsInShop() {
            shopButtonView.addNotificationIcon()
        }
        else {
            shopButtonView.removeNotificationIcon()
        }
        if storage.currentUser.haveNewItemsInInventory() {
            inventoryButtonView.addNotificationIcon()
        }
        else {
            inventoryButtonView.removeNotificationIcon()
        }
    }
    
    // MARK: - Properties
    
    weak var delegate: MainMenuViewDelegate?
    
    private typealias constants = MMBasicButtons_Constants
    
    private let storage = Storage.sharedInstance
    
    private var shopButtonView: ViewWithNotifIcon!
    private var inventoryButtonView: ViewWithNotifIcon!
    
    // MARK: - Inits
    
    init(delegate: MainMenuViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func makeInventoryMenu(_ sender: UIButton? = nil) {
        if let delegate {
            delegate.makeMenu(with: MMItemsButtons(delegate: delegate, isShopItems: false), reversed: false)
        }
    }
    
    @objc private func makeShopMenu(_ sender: UIButton? = nil) {
        if let delegate {
            delegate.makeMenu(with: MMItemsButtons(delegate: delegate, isShopItems: true), reversed: false)
        }
    }
    
    @objc private func makeGameMenu(_ sender: UIButton? = nil) {
        if let delegate {
            delegate.makeMenu(with: MMGameButtons(delegate: delegate), reversed: false)
        }
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        if let delegate {
            setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
            let gameButton = MMButtonView(backgroundImageItem: MiscImages.gameButtonBG, buttonImageItem: nil, buttontext: "Game", action: #selector(makeGameMenu), fontSize: delegate.font.pointSize, needHeightConstraint: true)
            let inventoryButton = MMButtonView(backgroundImageItem: MiscImages.inventoryButtonBG, buttonImageItem: nil, buttontext: "Inventory", action: #selector(makeInventoryMenu), fontSize: delegate.font.pointSize, needHeightConstraint: false)
            inventoryButtonView = ViewWithNotifIcon(mainView: inventoryButton, height: MMButtonView.getOptimalHeight(with: delegate.font.pointSize))
            let shopButton = MMButtonView(backgroundImageItem: MiscImages.shopButtonBG, buttonImageItem: nil, buttontext: "Shop", action: #selector(makeShopMenu), fontSize: delegate.font.pointSize, needHeightConstraint: false)
            shopButtonView = ViewWithNotifIcon(mainView: shopButton, height: MMButtonView.getOptimalHeight(with: delegate.font.pointSize))
            addArrangedSubviews([gameButton, inventoryButtonView, shopButtonView])
        }
    }
    
}

// MARK: - Constants

private struct MMBasicButtons_Constants {
    static let optimalSpacing = 5.0
}
