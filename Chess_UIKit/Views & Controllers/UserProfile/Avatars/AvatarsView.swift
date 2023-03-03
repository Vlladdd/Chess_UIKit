//
//  AvatarsView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

//class that represents view with all avatars
class AvatarsView: UIView, AvatarDelegate {
    
    // MARK: - AvatarDelegate
    
    func pickAvatar(_ avatar: Avatars) {
        for avatarLine in avatarsData.arrangedSubviews {
            if let avatarLine = avatarLine as? UIStackView {
                resetPickedAvatar(in: avatarLine)
            }
        }
        resetPickedAvatar(in: avatarsLastLine)
        delegate?.updateAvatar(with: avatar)
    }
    
    func updateNotificationIcons() {
        updateNotificationIcons(in: avatarsData)
        updateNotificationIcons(in: avatarsLastLine)
    }
    
    private func updateNotificationIcons(in line: UIStackView) {
        for avatarView in line.arrangedSubviews {
            if let viewWithNotif = avatarView as? ViewWithNotifIcon {
                if let avatar = (viewWithNotif.mainView as? UPAvatarView)?.item as? Avatars {
                    if storage.currentUser.containsNewItemIn(items: [avatar]) {
                        viewWithNotif.addNotificationIcon()
                    }
                    else {
                        viewWithNotif.removeNotificationIcon()
                    }
                }
            }
        }
    }
    
    // MARK: - Properties
    
    weak var delegate: UserProfileViewDelegate?
    
    private typealias constants = AvatarsView_Constants
    
    private(set) var avatarInfoView: AvatarInfoView!
    
    private let avatarsData = UIStackView()
    private let avatarsLastLine = UIStackView()
    private let storage = Storage.sharedInstance
    
    // MARK: - Inits
    
    init(font: UIFont) {
        super.init(frame: .zero)
        setup(font: font)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup(font: UIFont) {
        translatesAutoresizingMaskIntoConstraints = false
        avatarsData.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        avatarsLastLine.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        makeAvatarsViews()
        let avatarsDataScrollView = UIScrollView()
        let avatarsScrollViewContent = UIView()
        avatarsDataScrollView.translatesAutoresizingMaskIntoConstraints = false
        avatarsScrollViewContent.translatesAutoresizingMaskIntoConstraints = false
        avatarsDataScrollView.delaysContentTouches = false
        avatarsDataScrollView.addSubview(avatarsScrollViewContent)
        addSubview(avatarsDataScrollView)
        let contentHeight = avatarsScrollViewContent.heightAnchor.constraint(equalTo: avatarsDataScrollView.heightAnchor)
        contentHeight.priority = .defaultLow
        let contentConstraints = [avatarsScrollViewContent.topAnchor.constraint(equalTo: avatarsDataScrollView.topAnchor), avatarsScrollViewContent.bottomAnchor.constraint(equalTo: avatarsDataScrollView.bottomAnchor), avatarsScrollViewContent.leadingAnchor.constraint(equalTo: avatarsDataScrollView.leadingAnchor), avatarsScrollViewContent.trailingAnchor.constraint(equalTo: avatarsDataScrollView.trailingAnchor), avatarsScrollViewContent.widthAnchor.constraint(equalTo: avatarsDataScrollView.widthAnchor), contentHeight]
        avatarsScrollViewContent.addSubview(avatarsData)
        avatarsScrollViewContent.addSubview(avatarsLastLine)
        avatarInfoView = AvatarInfoView(font: font)
        addSubview(avatarInfoView)
        let avatarInfoViewConstraints = [avatarInfoView.leadingAnchor.constraint(equalTo: leadingAnchor), avatarInfoView.trailingAnchor.constraint(equalTo: trailingAnchor), avatarInfoView.bottomAnchor.constraint(equalTo: bottomAnchor), avatarInfoView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: constants.sizeMultiplayerForAvatarInfo)]
        let avatarsDataSVConstraints = [avatarsDataScrollView.leadingAnchor.constraint(equalTo: leadingAnchor), avatarsDataScrollView.trailingAnchor.constraint(equalTo: trailingAnchor), avatarsDataScrollView.topAnchor.constraint(equalTo: topAnchor), avatarsDataScrollView.bottomAnchor.constraint(lessThanOrEqualTo: avatarInfoView.topAnchor)]
        let avatarsDataConstraints = [avatarsData.topAnchor.constraint(equalTo: avatarsScrollViewContent.topAnchor, constant: constants.optimalDistance), avatarsData.leadingAnchor.constraint(equalTo: avatarsScrollViewContent.leadingAnchor, constant: constants.optimalDistance), avatarsData.trailingAnchor.constraint(equalTo: avatarsScrollViewContent.trailingAnchor, constant: -constants.optimalDistance)]
        let avatarsLastLineConstraints = [avatarsLastLine.topAnchor.constraint(equalTo: avatarsData.bottomAnchor, constant: constants.optimalSpacing), avatarsLastLine.bottomAnchor.constraint(equalTo: avatarsScrollViewContent.bottomAnchor, constant: -constants.optimalDistance), avatarsLastLine.leadingAnchor.constraint(equalTo: avatarsScrollViewContent.leadingAnchor, constant: constants.optimalDistance)]
        if let widthAnchor = avatarsData.arrangedSubviews.first?.widthAnchor {
            avatarsLastLine.arrangedSubviews.first?.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        }
        else {
            avatarsLastLine.trailingAnchor.constraint(lessThanOrEqualTo: avatarsScrollViewContent.trailingAnchor, constant: -constants.optimalDistance).isActive = true
        }
        NSLayoutConstraint.activate(contentConstraints + avatarInfoViewConstraints + avatarsDataSVConstraints + avatarsDataConstraints + avatarsLastLineConstraints)
    }
    
    private func makeAvatarsViews() {
        var avatarsViews = [UIImageView]()
        for avatar in Avatars.allCases {
            let avatarView = UPAvatarView(avatar: avatar, startColor: getColorForAvatar(avatar))
            avatarView.delegate = self
            let avatarViewWithNotif = ViewWithNotifIcon(mainView: avatarView, height: nil)
            avatarsViews.append(avatarViewWithNotif)
            if storage.currentUser.containsNewItemIn(items: [avatar]) {
                avatarViewWithNotif.addNotificationIcon()
            }
            if avatarsViews.count == constants.avatarsInLine {
                let avatarsLine = UIStackView()
                avatarsLine.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
                avatarsLine.addArrangedSubviews(avatarsViews)
                avatarsData.addArrangedSubview(avatarsLine)
                avatarsViews = []
            }
        }
        avatarsLastLine.addArrangedSubviews(avatarsViews)
    }
    
    private func resetPickedAvatar(in avatarsLine: UIStackView) {
        for avatarView in avatarsLine.arrangedSubviews {
            if let viewWithNotif = avatarView as? ViewWithNotifIcon {
                let defaultTextColor = traitCollection.userInterfaceStyle == .dark ? constants.lightModeTextColor : constants.darkModeTextColor
                viewWithNotif.mainView.layer.borderColor = defaultTextColor.cgColor
                if let avatarView = viewWithNotif.mainView as? UPAvatarView {
                    avatarView.backgroundView.backgroundColor = getColorForAvatar(avatarView.item as! Avatars)
                }
            }
        }
    }
    
    private func getColorForAvatar(_ avatar: Avatars) -> UIColor {
        var color = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        if avatar == storage.currentUser.playerAvatar {
            color = constants.chosenItemColor
        }
        else if !storage.currentUser.haveInInventory(item: avatar).inInventory {
            color = constants.notAvailableColor
        }
        return color
    }
    
}

// MARK: - Constants

private struct AvatarsView_Constants {
    static let optimalSpacing = 5.0
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let chosenItemColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let notAvailableColor = UIColor.red.withAlphaComponent(optimalAlpha)
    static let avatarsInLine = 3
    static let optimalDistance = 20.0
    static let darkModeTextColor = UIColor.black
    static let lightModeTextColor = UIColor.white
    static let sizeMultiplayerForAvatarInfo = 0.3
}
