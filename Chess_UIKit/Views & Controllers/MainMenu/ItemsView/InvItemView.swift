//
//  InvItemView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.02.2023.
//

import UIKit

//class that represents view of inventory item
class InvItemView: MMButtonView, SpecialItemView {
    
    // MARK: - SpecialItemView
    
    let itemView: ItemView
    
    // MARK: - Properties
    
    weak var delegate: InvItemDelegate?
    
    private typealias constants = InvItemView_Constants
    
    private let descriptionScrollView = UIScrollView()
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    
    private(set) var chooseButton: UIButton!
    
    // MARK: - Inits
    
    init(itemView: ItemView, delegate: InvItemDelegate, needHeightConstraint: Bool) {
        self.delegate = delegate
        self.itemView = itemView
        super.init(backgroundImageItem: nil, buttonImageItem: nil, buttontext: "", action: nil, fontSize: delegate.font.pointSize, needHeightConstraint: needHeightConstraint)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    //changes current value of item of user
    @objc private func chooseItemInInventory(_ sender: UIButton? = nil) {
        audioPlayer.playSound(Sounds.chooseItemSound)
        storage.currentUser.setValue(with: item)
        delegate?.updateItemsColor(inShop: false)
    }
    
    //shows/hides description of item
    @objc private func toggleDescriptionOfItemInInventory(_ sender: UIButton? = nil) {
        audioPlayer.playSound(Sounds.toggleSound)
        let newAlpha: CGFloat = descriptionScrollView.alpha == 0 ? 1 : 0
        UIView.animate(withDuration: constants.animationDuration, animations: { [weak self] in
            guard let self else { return }
            self.descriptionScrollView.alpha = newAlpha
        })
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        if let delegate {
            let backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
            descriptionScrollView.translatesAutoresizingMaskIntoConstraints = false
            descriptionScrollView.delaysContentTouches = false
            descriptionScrollView.alpha = 0
            let itemDescription = UILabel()
            itemDescription.setup(text: item.description, alignment: .center, font: delegate.font)
            itemDescription.numberOfLines = 0
            descriptionScrollView.backgroundColor = backgroundColor.withAlphaComponent(constants.alphaForItemDescription)
            descriptionScrollView.addSubview(itemDescription)
            let descriptionHeightConstraint = itemDescription.heightAnchor.constraint(equalTo: descriptionScrollView.heightAnchor)
            descriptionHeightConstraint.priority = .defaultLow
            let itemDescriptionCenterX = itemDescription.centerXAnchor.constraint(equalTo: descriptionScrollView.centerXAnchor)
            itemDescriptionCenterX.priority = .defaultLow
            let itemDescriptionCenterY = itemDescription.centerYAnchor.constraint(equalTo: descriptionScrollView.centerYAnchor)
            itemDescriptionCenterY.priority = .defaultLow
            let chooseButtonView = MMButtonView(backgroundImageItem: nil, buttonImageItem: SystemImages.chooseImage, buttontext: "", action: #selector(chooseItemInInventory), fontSize: delegate.font.pointSize, needHeightConstraint: false)
            let descriptionButton = MMButtonView(backgroundImageItem: nil, buttonImageItem: SystemImages.descriptionImage, buttontext: "", action: #selector(toggleDescriptionOfItemInInventory), fontSize: delegate.font.pointSize, needHeightConstraint: false)
            chooseButton = chooseButtonView.button
            addSubview(itemView)
            addSubview(chooseButtonView)
            addSubview(descriptionButton)
            addSubview(descriptionScrollView)
            let additionalButtons = [chooseButtonView, descriptionButton]
            let multiplierForAdditionalButtonsSize = constants.multiplierForAdditionalButtonsSize / Double(additionalButtons.count)
            let itemViewConstraints = [itemView.leadingAnchor.constraint(equalTo: leadingAnchor), itemView.trailingAnchor.constraint(equalTo: chooseButtonView.leadingAnchor, constant: -constants.distanceForButtons), itemView.topAnchor.constraint(equalTo: topAnchor), itemView.bottomAnchor.constraint(equalTo: bottomAnchor)]
            let chooseButtonConstraints = [chooseButtonView.trailingAnchor.constraint(equalTo: descriptionButton.leadingAnchor, constant: -constants.distanceForButtons), chooseButtonView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: multiplierForAdditionalButtonsSize), chooseButtonView.topAnchor.constraint(equalTo: topAnchor, constant: constants.optimalDistance), chooseButtonView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -constants.optimalDistance)]
            let descriptionButtonConstraints = [descriptionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -constants.distanceForButtons), descriptionButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: multiplierForAdditionalButtonsSize), descriptionButton.topAnchor.constraint(equalTo: topAnchor, constant: constants.optimalDistance), descriptionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -constants.optimalDistance)]
            let itemDescriptionConstraints = [itemDescription.leadingAnchor.constraint(equalTo: descriptionScrollView.leadingAnchor), itemDescription.trailingAnchor.constraint(equalTo: descriptionScrollView.trailingAnchor), itemDescription.topAnchor.constraint(equalTo: descriptionScrollView.topAnchor), itemDescription.bottomAnchor.constraint(equalTo: descriptionScrollView.bottomAnchor), itemDescription.widthAnchor.constraint(equalTo: descriptionScrollView.widthAnchor), itemDescriptionCenterX, itemDescriptionCenterY, descriptionHeightConstraint]
            let descriptionScrollViewConstraints = [descriptionScrollView.leadingAnchor.constraint(equalTo: leadingAnchor), descriptionScrollView.trailingAnchor.constraint(equalTo: chooseButtonView.leadingAnchor, constant: -constants.distanceForButtons), descriptionScrollView.topAnchor.constraint(equalTo: topAnchor), descriptionScrollView.bottomAnchor.constraint(equalTo: bottomAnchor)]
            NSLayoutConstraint.activate(chooseButtonConstraints + itemViewConstraints + descriptionButtonConstraints + itemDescriptionConstraints + descriptionScrollViewConstraints)
        }
    }
    
}

// MARK: - Constants

private struct InvItemView_Constants {
    static let optimalAlpha = 0.5
    static let alphaForItemDescription = 0.75
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let animationDuration = 0.5
    static let multiplierForAdditionalButtonsSize = 0.3
    static let optimalDistance = 10.0
    static let distanceForButtons = 5.0
}
