//
//  ShopItemView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.02.2023.
//

import UIKit

//class that represents view of shop item
class ShopItemView: MMButtonView, SpecialItemView {
    
    // MARK: - SpecialItemView
    
    let itemView: ItemView
    
    // MARK: - Properties
    
    weak var delegate: MainMenuViewDelegate?
    
    private typealias constants = ShopItemView_Constants
    
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    
    private(set) var buyButton: UIButton!
    
    // MARK: - Inits
    
    init(itemView: ItemView, delegate: MainMenuViewDelegate, needHeightConstraint: Bool) {
        self.itemView = itemView
        self.delegate = delegate
        super.init(backgroundImageItem: nil, buttonImageItem: nil, buttontext: "", action: nil, fontSize: delegate.font.pointSize, needHeightConstraint: needHeightConstraint)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func buyItem(_ sender: UIButton? = nil) {
        let textColor = traitCollection.userInterfaceStyle == .dark ? constants.lightModeTextColor : constants.darkModeTextColor
        delegate?.buyItem(itemView: itemView, additionalChanges: { [weak self] in
            guard let self else { return }
            sender?.isEnabled = false
            sender?.backgroundColor = constants.inInventoryColor
            sender?.setTitleColor(textColor, for: .normal)
            self.backgroundColor = constants.inInventoryColor
        })
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        if let delegate {
            let shopItem = itemView.item
            let buyButtonView = MMButtonView(backgroundImageItem: MiscImages.coinsBG, buttonImageItem: nil, buttontext: String(shopItem.cost), action: #selector(buyItem), fontSize: delegate.font.pointSize, needHeightConstraint: false)
            buyButton = buyButtonView.button
            addSubview(buyButtonView)
            addSubview(itemView)
            let itemViewConstraints = [itemView.leadingAnchor.constraint(equalTo: leadingAnchor), itemView.trailingAnchor.constraint(equalTo: buyButtonView.leadingAnchor), itemView.topAnchor.constraint(equalTo: topAnchor), itemView.bottomAnchor.constraint(equalTo: bottomAnchor)]
            let buyButtonViewConstraints = [buyButtonView.trailingAnchor.constraint(equalTo: trailingAnchor), buyButtonView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: constants.multiplierForAdditionalButtonsSize), buyButtonView.topAnchor.constraint(equalTo: topAnchor), buyButtonView.bottomAnchor.constraint(equalTo: bottomAnchor)]
            NSLayoutConstraint.activate(buyButtonViewConstraints + itemViewConstraints)
        }
    }
    
}

// MARK: - Constants

private struct ShopItemView_Constants {
    static let optimalAlpha = 0.5
    static let animationDuration = 0.5
    static let multiplierForAdditionalButtonsSize = 0.3
    static let inInventoryColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let darkModeTextColor = UIColor.black
    static let lightModeTextColor = UIColor.white
}
