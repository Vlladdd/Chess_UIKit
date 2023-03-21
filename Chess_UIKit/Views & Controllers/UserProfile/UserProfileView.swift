//
//  UserProfileView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

// MARK: - UserProfileViewDelegate

protocol UserProfileViewDelegate: AnyObject {
    func userProfileViewDidToggleViews(_ userProfileView: UserProfileView) -> Void
}

// MARK: - UserProfileView

//class that represents user profile view
class UserProfileView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: UserProfileViewDelegate?
    
    private let rankInfoView: RankInfoView
    private let userAvatar = UIImageView()
    
    private(set) var loadingSpinner: LoadingSpinner?
    
    let userInfoView: UserInfoView
    let avatarsView: AvatarsView
    let toolbar = UPToolbar()
    
    private typealias constants = UserProfileView_Constants
    
    // MARK: - Inits
    
    init(widthForAvatar: CGFloat, rankInfoView: RankInfoView, userInfoView: UserInfoView, avatarsView: AvatarsView) {
        self.rankInfoView = rankInfoView
        self.userInfoView = userInfoView
        self.avatarsView = avatarsView
        super.init(frame: .zero)
        setup(with: widthForAvatar)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    //switch between userInfo/avatarsView
    @objc private func toggleAvatars(_ sender: UITapGestureRecognizer? = nil) {
        toolbar.updateButton.isEnabled.toggle()
        if avatarsView.alpha == 0 {
            userAvatar.layer.borderColor = constants.pickItemBorderColor
            switchCurrentViews(viewsToExit: [userInfoView], viewsToEnter: [avatarsView], xForAnimation: frame.width)
        }
        else {
            let textColor = traitCollection.userInterfaceStyle == .dark ? constants.lightModeTextColor : constants.darkModeTextColor
            userAvatar.layer.borderColor = textColor.cgColor
            switchCurrentViews(viewsToExit: [avatarsView], viewsToEnter: [userInfoView], xForAnimation: -frame.width)
        }
        delegate?.userProfileViewDidToggleViews(self)
    }
    
    // MARK: - Local Methods
    
    private func setup(with widthForAvatar: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        makeToolBar()
        makeAvatarView(with: widthForAvatar)
        setupRankInfoView()
        setupUserInfoView()
        setupAvatarsView()
    }
    
    private func makeToolBar() {
        addSubview(toolbar)
        let toolbarConstraints = [toolbar.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor), toolbar.leadingAnchor.constraint(equalTo: leadingAnchor), toolbar.trailingAnchor.constraint(equalTo: trailingAnchor)]
        NSLayoutConstraint.activate(toolbarConstraints)
    }
    
    //picked avatar
    private func makeAvatarView(with width: CGFloat) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleAvatars))
        userAvatar.rectangleView(width: width)
        userAvatar.contentMode = .scaleAspectFill
        userAvatar.layer.masksToBounds = true
        userAvatar.setImage(with: avatarsView.pickedAvatarView.item as! Avatars)
        userAvatar.addGestureRecognizer(tapGesture)
        addSubview(userAvatar)
        let avatarConstraints = [userAvatar.topAnchor.constraint(equalTo: toolbar.layoutMarginsGuide.bottomAnchor, constant: constants.optimalDistance), userAvatar.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor)]
        NSLayoutConstraint.activate(avatarConstraints)
    }
    
    private func setupRankInfoView() {
        addSubview(rankInfoView)
        let rankInfoConstraints = [rankInfoView.topAnchor.constraint(equalTo: toolbar.layoutMarginsGuide.bottomAnchor, constant: constants.optimalDistance), rankInfoView.leadingAnchor.constraint(equalTo: userAvatar.trailingAnchor, constant: constants.optimalDistance), rankInfoView.bottomAnchor.constraint(equalTo: userAvatar.bottomAnchor), rankInfoView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)]
        NSLayoutConstraint.activate(rankInfoConstraints)
    }
    
    private func setupUserInfoView() {
        addSubview(userInfoView)
        let userInfoConstraints = [userInfoView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor), userInfoView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor), userInfoView.topAnchor.constraint(equalTo: userAvatar.bottomAnchor, constant: constants.optimalDistance), userInfoView.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor)]
        NSLayoutConstraint.activate(userInfoConstraints)
    }
    
    private func setupAvatarsView() {
        addSubview(avatarsView)
        //hidden at the start
        avatarsView.alpha = 0
        let avatarsViewConstraints = [avatarsView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor), avatarsView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor), avatarsView.topAnchor.constraint(equalTo: userAvatar.bottomAnchor, constant: constants.optimalDistance), avatarsView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)]
        NSLayoutConstraint.activate(avatarsViewConstraints)
    }
    
    //when we add/remove loading spinner
    func toggleViews() {
        for subview in subviews {
            subview.isHidden.toggle()
        }
    }
    
    //makes spinner, while waiting for response
    func makeLoadingSpinner() {
        loadingSpinner = LoadingSpinner()
        if let loadingSpinner {
            addSubview(loadingSpinner)
            let spinnerConstraints = [loadingSpinner.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor), loadingSpinner.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor), loadingSpinner.leadingAnchor.constraint(equalTo: leadingAnchor), loadingSpinner.trailingAnchor.constraint(equalTo: trailingAnchor)]
            NSLayoutConstraint.activate(spinnerConstraints)
        }
    }
    
    func removeLoadingSpinner() {
        loadingSpinner?.removeFromSuperview()
        loadingSpinner = nil
    }
    
    //hides viewsToExit and shows viewsToEnter with animation
    private func switchCurrentViews(viewsToExit: [UIView], viewsToEnter: [UIView], xForAnimation: CGFloat) {
        for viewToEnter in viewsToEnter {
            viewToEnter.transform = CGAffineTransform(translationX: xForAnimation, y: 0)
        }
        UIView.animate(withDuration: constants.animationDuration, animations: {
            for viewToExit in viewsToExit {
                viewToExit.transform = CGAffineTransform(translationX: -xForAnimation, y: 0)
                viewToExit.alpha = 0
            }
            for viewToEnter in viewsToEnter {
                viewToEnter.transform = .identity
                viewToEnter.alpha = 1
            }
        }) { _ in
            for viewToExit in viewsToExit {
                viewToExit.transform = .identity
            }
        }
    }
    
    //when device changed orientation
    func onRotate() {
        rankInfoView.onRotate()
    }
    
    func updateAvatar(with newValue: Avatars) {
        UIView.transition(with: userAvatar, duration: constants.animationDuration, options: .transitionCrossDissolve, animations: { [weak self] in
            guard let self else { return }
            self.userAvatar.setImage(with: newValue)
        })
        avatarsView.avatarInfoView.avatarInfo.text = newValue.description
    }
    
}

// MARK: - Constants

private struct UserProfileView_Constants {
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let optimalDistance = 20.0
    static let animationDuration = 0.5
    static let darkModeTextColor = UIColor.black
    static let lightModeTextColor = UIColor.white
    static let pickItemBorderColor = UIColor.yellow.cgColor
}
