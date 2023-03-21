//
//  UPAvatarView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

// MARK: - UPAvatarViewDelegate

protocol UPAvatarViewDelegate: AnyObject {
    func avatarViewDidTriggerPickAction(_ avatarView: UPAvatarView)
}

// MARK: - UPAvatarView

//class that represents view of avatar in user profile
class UPAvatarView: UIImageView, ItemView {
    
    // MARK: - ItemView
    
    let item: GameItem

    // MARK: - Properties
    
    weak var delegate: UPAvatarViewDelegate?
    
    private typealias constants = UPAvatarView_Constants
    
    private let backgroundView = UIView()
    
    // MARK: - Inits
    
    init(avatar: Avatars) {
        item = avatar
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func pickAvatar(_ sender: UITapGestureRecognizer? = nil) {
        pickAvatar()
        delegate?.avatarViewDidTriggerPickAction(self)
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pickAvatar(_:)))
        defaultSettings()
        isUserInteractionEnabled = true
        setImage(with: item as! Avatars)
        addGestureRecognizer(tapGesture)
        addSubview(backgroundView)
        backgroundView.backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        let avatarViewConstraints = [heightAnchor.constraint(equalTo: widthAnchor), backgroundView.heightAnchor.constraint(equalTo: heightAnchor), backgroundView.widthAnchor.constraint(equalTo: widthAnchor), backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor), backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor)]
        NSLayoutConstraint.activate(avatarViewConstraints)
    }
    
    private func pickAvatar() {
        layer.borderColor = constants.pickItemBorderColor
    }
    
    private func unpickAvatar() {
        layer.borderColor = (traitCollection.userInterfaceStyle == .dark ? constants.lightModeTextColor : constants.darkModeTextColor).cgColor
    }
    
    func updateStatus(picked: Bool, chosen: Bool, inInventory: Bool) {
        var color = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        if chosen {
            color = constants.chosenItemColor
        }
        else if !inInventory {
            color = constants.notAvailableColor
        }
        backgroundView.backgroundColor = color
        picked ? pickAvatar() : unpickAvatar()
    }
    
}

// MARK: - Constants

private struct UPAvatarView_Constants {
    static let pickItemBorderColor = UIColor.yellow.cgColor
    static let darkModeTextColor = UIColor.black
    static let lightModeTextColor = UIColor.white
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let chosenItemColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let notAvailableColor = UIColor.red.withAlphaComponent(optimalAlpha)
}
