//
//  UserDataView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 02.02.2023.
//

import UIKit

//class that represents user data view in top of main menu view
class UserDataView: UIStackView {
    
    // MARK: - Properties
    
    weak var delegate: MainMenuDelegate?
    
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    
    let userAvatar =  UIImageView()
    let userName = UILabel()
    
    private typealias constants = UserDataView_Constants
    
    // MARK: - Inits
    
    init(widthForAvatar: CGFloat, font: UIFont) {
        super.init(frame: .zero)
        setup(widthForAvatar: widthForAvatar, font: font)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    //exits from current user`s account
    @objc private func signOut(_ sender: UIButton? = nil) {
        let exitAlert = UIAlertController(title: "Exit", message: "Are you sure?", preferredStyle: .alert)
        exitAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.storage.signOut()
            self.delegate?.signOut()
            self.audioPlayer.playSound(Sounds.closePopUpSound)
        }))
        exitAlert.addAction(UIAlertAction(title: "No", style: .cancel))
        delegate?.present(exitAlert, animated: true)
        audioPlayer.playSound(Sounds.openPopUpSound)
    }
    
    //shows/hides view for redacting user profile
    @objc private func toggleUserProfileVC(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.toggleUserProfileVC()
    }
    
    // MARK: - Local Methods
    
    private func setup(widthForAvatar: CGFloat, font: UIFont) {
        setup(axis: .horizontal, alignment: .fill, distribution: .fill, spacing: constants.optimalSpacing)
        defaultSettings()
        layer.masksToBounds = true
        backgroundColor = backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleUserProfileVC))
        userAvatar.rectangleView(width: widthForAvatar)
        userAvatar.contentMode = .scaleAspectFill
        userAvatar.layer.masksToBounds = true
        userAvatar.setImage(with: storage.currentUser.playerAvatar)
        userAvatar.addGestureRecognizer(tapGesture)
        userName.setup(text: storage.currentUser.nickname, alignment: .center, font: font)
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
    func updateUserData() {
        UIView.transition(with: userAvatar, duration: constants.animationDuration, options: .transitionCrossDissolve, animations: { [weak self] in
            guard let self else { return }
            self.userAvatar.setImage(with: self.storage.currentUser.playerAvatar)
        })
        UIView.transition(with: userName, duration: constants.animationDuration, options: .transitionCrossDissolve, animations: { [weak self] in
            guard let self else { return }
            self.userName.text = self.storage.currentUser.nickname
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
