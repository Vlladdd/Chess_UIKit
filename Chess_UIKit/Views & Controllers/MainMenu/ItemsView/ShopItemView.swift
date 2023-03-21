//
//  ShopItemView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.02.2023.
//

import UIKit

// MARK: - ShopItemViewDelegate

protocol ShopItemViewDelegate: AnyObject {
    func shopItemViewDidTriggerBuyAction(_ shopItemView: ShopItemView) -> Void
    func shopItemViewDidTriggerPickAction(_ shopItemView: ShopItemView) -> Void
}

// MARK: - ShopItemView

//class that represents view of shop item
class ShopItemView: MMButtonView, SpecialItemView {
    
    // MARK: - SpecialItemView
    
    let itemView: ItemView
    
    // MARK: - Properties
    
    weak var delegate: ShopItemViewDelegate?
    
    private typealias constants = ShopItemView_Constants
    
    private var buyButton: UIButton!
    
    // MARK: - Inits
    
    init(itemView: ItemView, font: UIFont, needHeightConstraint: Bool) {
        self.itemView = itemView
        super.init(backgroundImageItem: nil, buttonImageItem: nil, buttontext: "", action: nil, font: font, needHeightConstraint: needHeightConstraint)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func buyItem(_ sender: UIButton? = nil) {
        delegate?.shopItemViewDidTriggerBuyAction(self)
    }
    
    //highlights picked item and removes notification icon from him
    @objc private func pickItem(_ sender: UITapGestureRecognizer? = nil) {
        layer.borderColor = constants.pickItemBorderColor
        delegate?.shopItemViewDidTriggerPickAction(self)
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pickItem))
        addGestureRecognizer(tapGesture)
        let shopItem = itemView.item
        let buyButtonView = MMButtonView(backgroundImageItem: MiscImages.coinsBG, buttonImageItem: nil, buttontext: String(shopItem.cost), action: #selector(buyItem), font: font, needHeightConstraint: false)
        buyButton = buyButtonView.button
        addSubview(buyButtonView)
        addSubview(itemView)
        let itemViewConstraints = [itemView.leadingAnchor.constraint(equalTo: leadingAnchor), itemView.trailingAnchor.constraint(equalTo: buyButtonView.leadingAnchor), itemView.topAnchor.constraint(equalTo: topAnchor), itemView.bottomAnchor.constraint(equalTo: bottomAnchor)]
        let buyButtonViewConstraints = [buyButtonView.trailingAnchor.constraint(equalTo: trailingAnchor), buyButtonView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: constants.multiplierForAdditionalButtonsSize), buyButtonView.topAnchor.constraint(equalTo: topAnchor), buyButtonView.bottomAnchor.constraint(equalTo: bottomAnchor)]
        NSLayoutConstraint.activate(buyButtonViewConstraints + itemViewConstraints)
    }
    
    func updateStatus(inInventory: Bool, available: Bool) {
        var color = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        let textColor = traitCollection.userInterfaceStyle == .dark ? constants.lightModeTextColor : constants.darkModeTextColor
        let buyEnabled = !inInventory && available
        if inInventory {
            color = constants.inInventoryColor
        }
        else if !available {
            color = constants.notAvailableColor
        }
        UIView.animate(withDuration: constants.animationDuration, animations: { [weak self] in
            guard let self else { return }
            self.backgroundColor = color
            self.buyButton.backgroundColor = color
            self.buyButton.isEnabled = buyEnabled
            if !buyEnabled {
                self.buyButton.setTitleColor(textColor, for: .normal)
            }
        })
    }
    
}

// MARK: - Constants

private struct ShopItemView_Constants {
    static let optimalAlpha = 0.5
    static let animationDuration = 0.5
    static let multiplierForAdditionalButtonsSize = 0.3
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let inInventoryColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let notAvailableColor = UIColor.red.withAlphaComponent(optimalAlpha)
    static let darkModeTextColor = UIColor.black
    static let lightModeTextColor = UIColor.white
    static let pickItemBorderColor = UIColor.yellow.cgColor
}
