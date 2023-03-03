//
//  UserProfileView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

//class that represents user profile view
class UserProfileView: UIView, UserProfileViewDelegate {
    
    // MARK: - UserProfileViewDelegate
    
    func updateNotificationIcons() {
        avatarsView.updateNotificationIcons()
    }
    
    weak var userProfileDelegate: UIViewController?
    
    func updateUserInfo() {
        toggleViews()
        makeLoadingSpinner()
        let nicknameView = userInfo.nicknameView.mainView as? UITextField
        if let nickname = nicknameView?.text, nickname.count >= constants.minimumSymbolsInData && nickname.count <= constants.maximumSymbolsInData {
            if !storage.checkIfGoogleSignIn() && !storage.currentUser.guestMode {
                let email = userInfo.emailView?.text
                let password = userInfo.passwordView?.text
                if let email, let password {
                    Task {
                        do {
                            try await storage.updateUserAccount(with: email, and: password)
                            updateNickname(with: nickname)
                        }
                        catch {
                            updateUserResultAlert(with: "Error", and: error.localizedDescription)
                            audioPlayer.playSound(Sounds.errorSound)
                        }
                    }
                }
            }
            else {
                updateNickname(with: nickname)
            }
        }
        else {
            updateUserResultAlert(with: "Error", and: "Nickname must be longer than \(constants.minimumSymbolsInData - 1) and less than \(constants.maximumSymbolsInData + 1)")
            audioPlayer.playSound(Sounds.errorSound)
        }
    }
    
    func updateAvatar(with newValue: Avatars) {
        UIView.transition(with: userAvatar, duration: constants.animationDuration, options: .transitionCrossDissolve, animations: { [weak self] in
            guard let self else { return }
            self.userAvatar.setImage(with: newValue)
        })
        avatarsView.avatarInfoView.avatarInfo.text = newValue.description
        if let mainMenuVC = userProfileDelegate?.presentingViewController as? MainMenuVC {
            mainMenuVC.mainMenuView.updateUserData()
            mainMenuVC.mainMenuView.updateNotificationIcons()
        }
    }
    
    // MARK: - Properties
    
    private let font: UIFont
    private let toolbar = UPToolbar()
    private let userAvatar = UIImageView()
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    
    private var loadingSpinner = LoadingSpinner()
    private var userInfo: UserInfoView!
    private var rankInfo: RankInfoView!
    private var avatarsView: AvatarsView!
    
    private typealias constants = UserProfileView_Constants
    
    // MARK: - Inits
    
    init(widthForAvatar: CGFloat, fontSize: CGFloat) {
        font = UIFont.systemFont(ofSize: fontSize)
        super.init(frame: .zero)
        setup(widthForAvatar: widthForAvatar)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    //switch between userInfo/avatarsView
    @objc private func toggleAvatars(_ sender: UITapGestureRecognizer? = nil) {
        audioPlayer.playSound(Sounds.pickItemSound)
        toolbar.updateButton.isEnabled.toggle()
        if avatarsView.alpha == 0 {
            userAvatar.layer.borderColor = constants.pickItemBorderColor
            switchCurrentViews(viewsToExit: [userInfo], viewsToEnter: [avatarsView], xForAnimation: frame.width)
        }
        else {
            let defaultTextColor = traitCollection.userInterfaceStyle == .dark ? constants.lightModeTextColor : constants.darkModeTextColor
            updateAvatar(with: storage.currentUser.playerAvatar)
            userAvatar.layer.borderColor = defaultTextColor.cgColor
            switchCurrentViews(viewsToExit: [avatarsView], viewsToEnter: [userInfo], xForAnimation: -frame.width)
        }
    }
    
    // MARK: - Local Methods
    
    private func setup(widthForAvatar: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        makeToolBar()
        makeAvatar(with: widthForAvatar)
        makeRankInfo()
        makeUserInfo()
        makeAvatarsView()
    }
    
    private func makeToolBar() {
        addSubview(toolbar)
        toolbar.userProfileViewDelegate = self
        let toolbarConstraints = [toolbar.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor), toolbar.leadingAnchor.constraint(equalTo: leadingAnchor), toolbar.trailingAnchor.constraint(equalTo: trailingAnchor)]
        NSLayoutConstraint.activate(toolbarConstraints)
    }
    
    private func makeAvatar(with width: CGFloat) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleAvatars))
        userAvatar.rectangleView(width: width)
        userAvatar.contentMode = .scaleAspectFill
        userAvatar.layer.masksToBounds = true
        userAvatar.setImage(with: storage.currentUser.playerAvatar)
        userAvatar.addGestureRecognizer(tapGesture)
        addSubview(userAvatar)
        let avatarConstraints = [userAvatar.topAnchor.constraint(equalTo: toolbar.layoutMarginsGuide.bottomAnchor, constant: constants.optimalDistance), userAvatar.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor)]
        NSLayoutConstraint.activate(avatarConstraints)
    }
    
    private func makeRankInfo() {
        rankInfo = RankInfoView(font: font)
        addSubview(rankInfo)
        let rankInfoConstraints = [rankInfo.topAnchor.constraint(equalTo: toolbar.layoutMarginsGuide.bottomAnchor, constant: constants.optimalDistance), rankInfo.leadingAnchor.constraint(equalTo: userAvatar.trailingAnchor, constant: constants.optimalDistance), rankInfo.bottomAnchor.constraint(equalTo: userAvatar.bottomAnchor), rankInfo.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)]
        NSLayoutConstraint.activate(rankInfoConstraints)
    }
    
    private func makeUserInfo() {
        userInfo = UserInfoView(font: font)
        addSubview(userInfo)
        let userInfoConstraints = [userInfo.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor), userInfo.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor), userInfo.topAnchor.constraint(equalTo: userAvatar.bottomAnchor, constant: constants.optimalDistance), userInfo.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor)]
        NSLayoutConstraint.activate(userInfoConstraints)
    }
    
    private func makeAvatarsView() {
        avatarsView = AvatarsView(font: font)
        avatarsView.delegate = self
        addSubview(avatarsView)
        //hidden at the start
        avatarsView.alpha = 0
        let avatarsViewConstraints = [avatarsView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor), avatarsView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor), avatarsView.topAnchor.constraint(equalTo: userAvatar.bottomAnchor, constant: constants.optimalDistance), avatarsView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)]
        NSLayoutConstraint.activate(avatarsViewConstraints)
    }
    
    //when we add/remove loading spinner
    private func toggleViews() {
        toolbar.isHidden.toggle()
        userInfo.isHidden.toggle()
        rankInfo.isHidden.toggle()
        userAvatar.isHidden.toggle()
    }
    
    //makes spinner, while waiting for response
    private func makeLoadingSpinner() {
        loadingSpinner = LoadingSpinner()
        loadingSpinner.waiting()
        addSubview(loadingSpinner)
        let spinnerConstraints = [loadingSpinner.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor), loadingSpinner.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor), loadingSpinner.leadingAnchor.constraint(equalTo: leadingAnchor), loadingSpinner.trailingAnchor.constraint(equalTo: trailingAnchor)]
        NSLayoutConstraint.activate(spinnerConstraints)
    }
    
    private func updateNickname(with newValue: String) {
        storage.currentUser.updateNickname(newValue: newValue)
        if let mainMenuVC = userProfileDelegate?.presentingViewController as? MainMenuVC {
            mainMenuVC.mainMenuView.updateUserData()
            mainMenuVC.mainMenuView.updateNotificationIcons()
        }
        userInfo.nicknameView.removeNotificationIcon()
        updateUserResultAlert(with: "Action completed", and: "Data updated!")
        audioPlayer.playSound(Sounds.successSound)
    }
    
    private func updateUserResultAlert(with title: String, and message: String) {
        print(message)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        UIApplication.getTopMostViewController()?.present(alert, animated: true)
        loadingSpinner.removeFromSuperview()
        toggleViews()
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
        audioPlayer.playSound(Sounds.moveSound1)
    }
    
    //when device changed orientation
    func onRotate() {
        rankInfo.userProgress.setNeedsDisplay()
    }
    
}

// MARK: - Constants

private struct UserProfileView_Constants {
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let minimumSymbolsInData = 5
    static let maximumSymbolsInData = 13
    static let optimalDistance = 20.0
    static let animationDuration = 0.5
    static let darkModeTextColor = UIColor.black
    static let lightModeTextColor = UIColor.white
    static let pickItemBorderColor = UIColor.yellow.cgColor
}
