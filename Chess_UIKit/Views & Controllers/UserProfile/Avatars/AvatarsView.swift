//
//  AvatarsView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

//class that represents view with all avatars
class AvatarsView: UIView {
    
    // MARK: - Properties
    
    private typealias constants = AvatarsView_Constants
    
    private(set) var avatarInfoView: AvatarInfoView!
    
    var pickedAvatarView: UPAvatarView!
    
    let avatarsViews = UIStackView()
    let avatarsViewsLastLine = UIStackView()
    
    // MARK: - Inits
    
    init(font: UIFont, pickedAvatar: Avatars, avatars: [Avatars]) {
        super.init(frame: .zero)
        setup(with: font, pickedAvatar: pickedAvatar, avatars: avatars)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup(with font: UIFont, pickedAvatar: Avatars, avatars: [Avatars]) {
        translatesAutoresizingMaskIntoConstraints = false
        avatarsViews.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        avatarsViewsLastLine.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        makeAvatarsViews(with: avatars, and: pickedAvatar)
        let avatarsViewsScrollView = UIScrollView()
        let avatarsScrollViewContent = UIView()
        avatarsViewsScrollView.translatesAutoresizingMaskIntoConstraints = false
        avatarsScrollViewContent.translatesAutoresizingMaskIntoConstraints = false
        avatarsViewsScrollView.delaysContentTouches = false
        avatarsViewsScrollView.addSubview(avatarsScrollViewContent)
        addSubview(avatarsViewsScrollView)
        let contentHeight = avatarsScrollViewContent.heightAnchor.constraint(equalTo: avatarsViewsScrollView.heightAnchor)
        contentHeight.priority = .defaultLow
        let contentConstraints = [avatarsScrollViewContent.topAnchor.constraint(equalTo: avatarsViewsScrollView.topAnchor), avatarsScrollViewContent.bottomAnchor.constraint(equalTo: avatarsViewsScrollView.bottomAnchor), avatarsScrollViewContent.leadingAnchor.constraint(equalTo: avatarsViewsScrollView.leadingAnchor), avatarsScrollViewContent.trailingAnchor.constraint(equalTo: avatarsViewsScrollView.trailingAnchor), avatarsScrollViewContent.widthAnchor.constraint(equalTo: avatarsViewsScrollView.widthAnchor), contentHeight]
        avatarsScrollViewContent.addSubview(avatarsViews)
        avatarsScrollViewContent.addSubview(avatarsViewsLastLine)
        avatarInfoView = AvatarInfoView(font: font, avatarDescription: pickedAvatar.description)
        addSubview(avatarInfoView)
        let avatarInfoViewConstraints = [avatarInfoView.leadingAnchor.constraint(equalTo: leadingAnchor), avatarInfoView.trailingAnchor.constraint(equalTo: trailingAnchor), avatarInfoView.bottomAnchor.constraint(equalTo: bottomAnchor), avatarInfoView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: constants.sizeMultiplayerForAvatarInfo)]
        let avatarsViewsSVConstraints = [avatarsViewsScrollView.leadingAnchor.constraint(equalTo: leadingAnchor), avatarsViewsScrollView.trailingAnchor.constraint(equalTo: trailingAnchor), avatarsViewsScrollView.topAnchor.constraint(equalTo: topAnchor), avatarsViewsScrollView.bottomAnchor.constraint(lessThanOrEqualTo: avatarInfoView.topAnchor)]
        let avatarsViewsConstraints = [avatarsViews.topAnchor.constraint(equalTo: avatarsScrollViewContent.topAnchor, constant: constants.optimalDistance), avatarsViews.leadingAnchor.constraint(equalTo: avatarsScrollViewContent.leadingAnchor, constant: constants.optimalDistance), avatarsViews.trailingAnchor.constraint(equalTo: avatarsScrollViewContent.trailingAnchor, constant: -constants.optimalDistance)]
        let avatarsLastLineConstraints = [avatarsViewsLastLine.topAnchor.constraint(equalTo: avatarsViews.bottomAnchor, constant: constants.optimalSpacing), avatarsViewsLastLine.bottomAnchor.constraint(equalTo: avatarsScrollViewContent.bottomAnchor, constant: -constants.optimalDistance), avatarsViewsLastLine.leadingAnchor.constraint(equalTo: avatarsScrollViewContent.leadingAnchor, constant: constants.optimalDistance)]
        if let widthAnchor = avatarsViews.arrangedSubviews.first?.widthAnchor {
            avatarsViewsLastLine.arrangedSubviews.first?.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        }
        else {
            avatarsViewsLastLine.trailingAnchor.constraint(lessThanOrEqualTo: avatarsScrollViewContent.trailingAnchor, constant: -constants.optimalDistance).isActive = true
        }
        NSLayoutConstraint.activate(contentConstraints + avatarInfoViewConstraints + avatarsViewsSVConstraints + avatarsViewsConstraints + avatarsLastLineConstraints)
    }
    
    private func makeAvatarsViews(with avatars: [Avatars], and pickedAvatar: Avatars) {
        var avatarsViews = [UIImageView]()
        for avatar in avatars {
            let avatarView = UPAvatarView(avatar: avatar)
            if pickedAvatar == avatar {
                pickedAvatarView = avatarView
            }
            let avatarViewWithNotif = ViewWithNotifIcon(mainView: avatarView, height: nil)
            avatarsViews.append(avatarViewWithNotif)
            if avatarsViews.count == constants.avatarsInLine {
                let avatarsLine = UIStackView()
                avatarsLine.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
                avatarsLine.addArrangedSubviews(avatarsViews)
                self.avatarsViews.addArrangedSubview(avatarsLine)
                avatarsViews = []
            }
        }
        avatarsViewsLastLine.addArrangedSubviews(avatarsViews)
    }
    
}

// MARK: - Constants

private struct AvatarsView_Constants {
    static let optimalSpacing = 5.0
    static let avatarsInLine = 3
    static let optimalDistance = 20.0
    static let sizeMultiplayerForAvatarInfo = 0.3
}
