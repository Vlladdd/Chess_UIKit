//
//  UPAvatarView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

//class that represents view of avatar in user profile
class UPAvatarView: UIImageView, ItemView {
    
    // MARK: - ItemView
    
    let item: GameItem

    // MARK: - Properties
    
    weak var delegate: AvatarDelegate?
    
    private typealias constants = UPAvatarView_Constants
    
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    
    let backgroundView = UIView()
    
    // MARK: - Inits
    
    init(avatar: Avatars, startColor: UIColor) {
        item = avatar
        super.init(frame: .zero)
        setup(startColor: startColor)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func pickAvatar(_ sender: UITapGestureRecognizer? = nil) {
        if let sender {
            let avatar = item as! Avatars
            audioPlayer.playSound(Sounds.pickItemSound)
            storage.currentUser.addSeenItem(avatar)
            if storage.currentUser.haveInInventory(item: avatar).inInventory {
                storage.currentUser.setValue(with: avatar)
            }
            delegate?.pickAvatar(avatar)
            sender.view?.layer.borderColor = constants.pickItemBorderColor
            if let viewWithNotif = sender.view?.superview as? ViewWithNotifIcon {
                viewWithNotif.removeNotificationIcon()
            }
        }
    }
    
    // MARK: - Local Methods
    
    private func setup(startColor: UIColor) {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pickAvatar))
        defaultSettings()
        isUserInteractionEnabled = true
        setImage(with: item as! Avatars)
        addGestureRecognizer(tapGesture)
        addSubview(backgroundView)
        backgroundView.backgroundColor = startColor
        if storage.currentUser.playerAvatar == item as! Avatars {
            layer.borderColor = constants.pickItemBorderColor
        }
        let avatarViewConstraints = [heightAnchor.constraint(equalTo: widthAnchor), backgroundView.heightAnchor.constraint(equalTo: heightAnchor), backgroundView.widthAnchor.constraint(equalTo: widthAnchor), backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor), backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor)]
        NSLayoutConstraint.activate(avatarViewConstraints)
    }
    
}

// MARK: - Constants

private struct UPAvatarView_Constants {
    static let pickItemBorderColor = UIColor.yellow.cgColor
}
