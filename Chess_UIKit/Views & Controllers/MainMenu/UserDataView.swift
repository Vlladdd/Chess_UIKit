//
//  UserDataView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 02.02.2023.
//

import UIKit

// MARK: - UserDataViewDelegate

protocol UserDataViewDelegate: AnyObject {
    func userDataViewDidTriggerSignOut(_ userDataView: UserDataView) -> Void
    func userDataViewDidTriggerToggleUserProfileVC(_ userDataView: UserDataView) -> Void
}

// MARK: - UserDataView

//class that represents user data view in top of main menu view
class UserDataView: UIStackView {
    
    // MARK: - Properties
    
    weak var delegate: UserDataViewDelegate?
    
    private let userAvatar =  UIImageView()
    private let userName = UILabel()
    
    private typealias constants = UserDataView_Constants
    
    // MARK: - Inits
    
    init(widthForAvatar: CGFloat, font: UIFont, nickname: String, avatar: Avatars) {
        super.init(frame: .zero)
        setup(with: widthForAvatar, font: font, nickname: nickname, avatar: avatar)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    //exits from current user`s account
    @objc private func signOut(_ sender: UIButton? = nil) {
        delegate?.userDataViewDidTriggerSignOut(self)
    }
    
    //shows/hides view for redacting user profile
    @objc private func toggleUserProfileVC(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.userDataViewDidTriggerToggleUserProfileVC(self)
    }
    
    // MARK: - Local Methods
    
    private func setup(with widthForAvatar: CGFloat, font: UIFont, nickname: String, avatar: Avatars) {
        setup(axis: .horizontal, alignment: .fill, distribution: .fill, spacing: constants.optimalSpacing)
        defaultSettings()
        layer.masksToBounds = true
        backgroundColor = backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleUserProfileVC))
        userAvatar.rectangleView(width: widthForAvatar)
        userAvatar.contentMode = .scaleAspectFill
        userAvatar.layer.masksToBounds = true
        userAvatar.setImage(with: avatar)
        userAvatar.addGestureRecognizer(tapGesture)
        userName.setup(text: nickname, alignment: .center, font: font)
        let exitButton = UIButton()
        if #available(iOS 15.0, *) {
            exitButton.buttonWith(imageItem: SystemImages.exitImageiOS15, and: #selector(signOut))
        }
        else {
            exitButton.buttonWith(imageItem: SystemImages.exitImage, and: #selector(signOut))
        }
        addArrangedSubviews([userAvatar, userName, exitButton])
        exitButton.widthAnchor.constraint(equalTo: exitButton.heightAnchor).isActive = true
    }
    
    //when changes made in user profile view
    func updateUserData(with avatar: Avatars, and nickname: String) {
        UIView.transition(with: userAvatar, duration: constants.animationDuration, options: .transitionCrossDissolve, animations: { [weak self] in
            guard let self else { return }
            self.userAvatar.setImage(with: avatar)
        })
        UIView.transition(with: userName, duration: constants.animationDuration, options: .transitionCrossDissolve, animations: { [weak self] in
            guard let self else { return }
            self.userName.text = nickname
            self.layoutIfNeeded()
        })
    }
    
}

// MARK: - Constants

private struct UserDataView_Constants {
    static let optimalSpacing = 5.0
    static let optimalAlpha = 0.5
    static let animationDuration = 0.5
}
