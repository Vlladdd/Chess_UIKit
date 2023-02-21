//
//  MMItemsButtons.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.02.2023.
//

import UIKit

//class that represents inventory or shop buttons in main menu
class MMItemsButtons: UIStackView, NotificationIconsDelegate {
    
    // MARK: - NotificationIconsDelegate
    
    func updateNotificationIcons() {
        for button in arrangedSubviews {
            if let viewWithNotifIcon = button as? ViewWithNotifIcon, let itemsButton = viewWithNotifIcon.mainView as? MMItemsButton {
                if storage.currentUser.containsNewItemIn(items: itemsButton.items) {
                    viewWithNotifIcon.addNotificationIcon()
                }
                else {
                    viewWithNotifIcon.removeNotificationIcon()
                }
            }
        }
    }
    
    // MARK: - Properties
    
    weak var delegate: MainMenuViewDelegate?
    
    private typealias constants = MMInvButtons_Constants
    
    private let isShopItems: Bool
    private let storage = Storage.sharedInstance
    
    // MARK: - Inits
    
    init(delegate: MainMenuViewDelegate, isShopItems: Bool) {
        self.delegate = delegate
        self.isShopItems = isShopItems
        super.init(frame: .zero)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods

    //makes list of items of the same group
    @objc private func makeListOfItems(_ sender: UIButton? = nil) {
        if let sender, let delegate {
            if let items = (sender.superview as? MMItemsButton)?.items, items.count > 0 {
                let itemsView = ItemsView(items: items, isShopItems: isShopItems, delegate: delegate)
                delegate.makeMenu(with: itemsView, reversed: false)
            }
        }
    }
    
    @objc private func goBack(_ sender: UIButton? = nil) {
        if let delegate {
            delegate.makeMenu(with: MMBasicButtons(delegate: delegate), reversed: true)
        }
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let figuresButton = makeButton(with: isShopItems ? FiguresThemes.purchasable : FiguresThemes.allCases, backgroundImageItem: MiscImages.figuresButtonBG, buttonText: "Figures")
        let backgroundButton = makeButton(with: isShopItems ? Backgrounds.purchasable : Backgrounds.allCases, backgroundImageItem: storage.currentUser.playerBackground, buttonText: "Background")
        let titleButton = makeButton(with: isShopItems ? Titles.purchasable : Titles.allCases, backgroundImageItem: nil, buttonText: "Title")
        let boardButton = makeButton(with: isShopItems ? BoardThemes.purchasable : BoardThemes.allCases, backgroundImageItem: MiscImages.boardsButtonBG, buttonText: "Board")
        let frameButton = makeButton(with: isShopItems ? Frames.purchasable : Frames.allCases, backgroundImageItem: MiscImages.framesButtonBG, buttonText: "Frame")
        let squaresButton = makeButton(with: isShopItems ? SquaresThemes.purchasable : SquaresThemes.allCases, backgroundImageItem: MiscImages.squaresButtonBG, buttonText: "Squares")
        let buttons = [figuresButton, backgroundButton, titleButton, boardButton, frameButton, squaresButton]
        addArrangedSubviews(buttons)
        if isShopItems {
            let avatarsButton = makeButton(with: Avatars.purchasable, backgroundImageItem: storage.currentUser.playerAvatar, buttonText: "Avatars")
            addArrangedSubview(avatarsButton)
        }
        if let delegate {
            let backButton = MMButtonView(backgroundImageItem: nil, buttonImageItem: nil, buttontext: "Back", action: #selector(goBack), fontSize: delegate.font.pointSize, needHeightConstraint: true)
            backButton.addBackButtonSFImage()
            addArrangedSubview(backButton)
        }
    }
    
    private func makeButton(with items: [GameItem], backgroundImageItem: ImageItem?, buttonText: String) -> ViewWithNotifIcon {
        if let delegate {
            let button = MMItemsButton(items: items, backgroundImageItem: backgroundImageItem, buttontext: buttonText, action: #selector(makeListOfItems), fontSize: delegate.font.pointSize)
            let buttonView = ViewWithNotifIcon(mainView: button, height: MMButtonView.getOptimalHeight(with: delegate.font.pointSize))
            return buttonView
        }
        else {
            fatalError()
        }
    }
    
}

// MARK: - Constants

private struct MMInvButtons_Constants {
    static let optimalSpacing = 5.0
}
