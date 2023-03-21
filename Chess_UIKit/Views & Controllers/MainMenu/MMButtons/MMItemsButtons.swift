//
//  MMItemsButtons.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.02.2023.
//

import UIKit

// MARK: - MMItemsButtonsDelegate

protocol MMItemsButtonsDelegate: AnyObject {
    func itemsButtonsDidTriggerBackAction(_ itemsButtons: MMItemsButtons) -> Void
}

// MARK: - MMItemsButtons

//class that represents inventory or shop buttons in main menu
class MMItemsButtons: UIStackView {
    
    // MARK: - Properties
    
    weak var delegate: MMItemsButtonsDelegate?
    
    private typealias constants = MMInvButtons_Constants
    
    private let isShopItems: Bool
    private let font: UIFont
    
    // MARK: - Inits
    
    init(font: UIFont, isShopItems: Bool, playerBackground: Backgrounds, playerAvatar: Avatars) {
        self.font = font
        self.isShopItems = isShopItems
        super.init(frame: .zero)
        setup(with: playerBackground, and: playerAvatar)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func goBack(_ sender: UIButton? = nil) {
        delegate?.itemsButtonsDidTriggerBackAction(self)
    }
    
    // MARK: - Local Methods
    
    private func setup(with playerBackground: Backgrounds, and playerAvatar: Avatars) {
        setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let figuresButton = makeButton(with: isShopItems ? FiguresThemes.purchasable : FiguresThemes.allCases, backgroundImageItem: MiscImages.figuresButtonBG, buttonText: "Figures")
        let backgroundButton = makeButton(with: isShopItems ? Backgrounds.purchasable : Backgrounds.allCases, backgroundImageItem: playerBackground, buttonText: "Background")
        let titleButton = makeButton(with: isShopItems ? Titles.purchasable : Titles.allCases, backgroundImageItem: nil, buttonText: "Title")
        let boardButton = makeButton(with: isShopItems ? BoardThemes.purchasable : BoardThemes.allCases, backgroundImageItem: MiscImages.boardsButtonBG, buttonText: "Board")
        let frameButton = makeButton(with: isShopItems ? Frames.purchasable : Frames.allCases, backgroundImageItem: MiscImages.framesButtonBG, buttonText: "Frame")
        let squaresButton = makeButton(with: isShopItems ? SquaresThemes.purchasable : SquaresThemes.allCases, backgroundImageItem: MiscImages.squaresButtonBG, buttonText: "Squares")
        let buttons = [figuresButton, backgroundButton, titleButton, boardButton, frameButton, squaresButton]
        addArrangedSubviews(buttons)
        if isShopItems {
            let avatarsButton = makeButton(with: Avatars.purchasable, backgroundImageItem: playerAvatar, buttonText: "Avatars")
            addArrangedSubview(avatarsButton)
        }
        let backButton = MMButtonView(backgroundImageItem: nil, buttonImageItem: nil, buttontext: "Back", action: #selector(goBack), font: font, needHeightConstraint: true)
        backButton.addBackButtonSFImage()
        addArrangedSubview(backButton)
    }
    
    private func makeButton(with items: [GameItem], backgroundImageItem: ImageItem?, buttonText: String) -> ViewWithNotifIcon {
        let button = MMItemsButton(items: items, isShopItems: isShopItems, backgroundImageItem: backgroundImageItem, buttontext: buttonText, font: font)
        let buttonView = ViewWithNotifIcon(mainView: button, height: MMButtonView.getOptimalHeight(with: font.pointSize))
        return buttonView
    }
    
}

// MARK: - Constants

private struct MMInvButtons_Constants {
    static let optimalSpacing = 5.0
}
