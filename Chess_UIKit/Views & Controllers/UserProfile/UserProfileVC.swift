//
//  UserProfileVC.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 05.11.2022.
//

import UIKit

//VC that represents user profile view
class UserProfileVC: UIViewController {
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        configureKeyboardToHideWhenTappedAround()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        userProfileView.onRotate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayer.playSound(Sounds.closePopUpSound)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioPlayer.pauseSound(Music.waitingMusic)
    }
    
    // MARK: - Properties
    
    private typealias constants = UserProfileVC_Constants
    
    private let audioPlayer = AudioPlayer.sharedInstance
    private let storage = Storage.sharedInstance
    
    // MARK: - Methods
    
    func updateNotificationIcons(shouldUpdateInMainMenu: Bool = true) {
        updateNotificationIcons(in: userProfileView.avatarsView.avatarsViews)
        updateNotificationIcons(in: userProfileView.avatarsView.avatarsViewsLastLine)
        if shouldUpdateInMainMenu {
            if let mainMenuVC = presentingViewController as? MainMenuVC {
                mainMenuVC.updateNotificationIcons(shouldUpdateInUserProfile: false)
            }
        }
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
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private var userProfileView: UserProfileView!
    
    // MARK: - UI Methods
    
    private func makeUI() {
        let fontSize = min(view.frame.width, view.frame.height) / constants.dividerForFont
        let font = UIFont.systemFont(ofSize: fontSize)
        //picked avatar
        let widthForAvatar = min(view.frame.height, view.frame.width) / constants.sizeMultiplayerForAvatar
        let rankInfoView = RankInfoView(font: font, rank: storage.currentUser.rank, currentPoints: storage.currentUser.points)
        var userInfoViewData = UserInfoView.Data()
        userInfoViewData.isGuestMode = storage.currentUser.guestMode
        userInfoViewData.isGoogleSignIn = storage.checkIfGoogleSignIn()
        userInfoViewData.soundsEnabled = storage.currentUser.soundsEnabled
        userInfoViewData.musicEnabled = storage.currentUser.musicEnabled
        userInfoViewData.email = storage.currentUser.email
        userInfoViewData.nickname = storage.currentUser.nickname
        let userInfoView = UserInfoView(font: font, data: userInfoViewData)
        userInfoView.userInfoViewDelegate = self
        let avatarsView = AvatarsView(font: font, pickedAvatar: storage.currentUser.playerAvatar, avatars: Avatars.allCases)
        setupAvatarsViews(avatarsView.avatarsViews)
        setupAvatarsViews(avatarsView.avatarsViewsLastLine)
        userProfileView = UserProfileView(widthForAvatar: widthForAvatar, rankInfoView: rankInfoView, userInfoView: userInfoView, avatarsView: avatarsView)
        userProfileView.delegate = self
        userProfileView.toolbar.upToolbarDelegate = self
        view.addSubview(userProfileView)
        let userProfileViewConstraints = [userProfileView.leadingAnchor.constraint(equalTo: view.leadingAnchor), userProfileView.trailingAnchor.constraint(equalTo: view.trailingAnchor), userProfileView.topAnchor.constraint(equalTo: view.topAnchor), userProfileView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        NSLayoutConstraint.activate(userProfileViewConstraints)
        updateNotificationIcons()
    }
    
    private func setupAvatarsViews(_ avatarsViews: UIStackView) {
        for avatarView in avatarsViews.arrangedSubviews {
            if let avatarView = (avatarView as? ViewWithNotifIcon)?.mainView as? UPAvatarView {
                let avatarInfo = storage.currentUser.haveInInventory(item: avatarView.item)
                avatarView.delegate = self
                avatarView.updateStatus(picked: avatarInfo.chosen, chosen: avatarInfo.chosen, inInventory: avatarInfo.inInventory)
            }
        }
    }
    
}

// MARK: - Constants

private struct UserProfileVC_Constants {
    static let volumeForWaitingMusic: Float = 0.3
    static let dividerForFont: CGFloat = 13
    static let sizeMultiplayerForAvatar = 4.0
    static let minimumSymbolsInData = 5
    static let maximumSymbolsInData = 13
}

// MARK: - UPAvatarViewDelegate

extension UserProfileVC: UPAvatarViewDelegate {
    
    func avatarViewDidTriggerPickAction(_ avatarView: UPAvatarView) {
        audioPlayer.playSound(Sounds.pickItemSound)
        if avatarView != userProfileView.avatarsView.pickedAvatarView {
            let avatarInfo = storage.currentUser.haveInInventory(item: avatarView.item)
            var isChosenAvatar = false
            storage.currentUser.addSeenItem(avatarView.item)
            if avatarInfo.inInventory {
                storage.currentUser.setValue(with: avatarView.item)
                isChosenAvatar = true
                if let mainMenuVC = presentingViewController as? MainMenuVC {
                    mainMenuVC.updateUserData()
                    mainMenuVC.updateNotificationIcons()
                }
            }
            if let pickedAvatarView = userProfileView.avatarsView.pickedAvatarView {
                let oldAvatarInfo = storage.currentUser.haveInInventory(item: pickedAvatarView.item)
                pickedAvatarView.updateStatus(picked: false, chosen: oldAvatarInfo.chosen, inInventory: oldAvatarInfo.inInventory)
            }
            userProfileView.avatarsView.pickedAvatarView = avatarView
            avatarView.updateStatus(picked: true, chosen: isChosenAvatar, inInventory: avatarInfo.inInventory)
            userProfileView.updateAvatar(with: avatarView.item as! Avatars)
        }
        else {
            storage.currentUser.addSeenItem(avatarView.item)
        }
        updateNotificationIcons()
    }
    
}

// MARK: - UPToolbarDelegate

extension UserProfileVC: UPToolbarDelegate {
    
    func toolbarDidTriggerCloseAction(_ toolbar: UPToolbar) {
        dismiss(animated: true)
    }
    
    func toolbarDidTriggerUpdateAction(_ toolbar: UPToolbar) {
        userProfileView.toggleViews()
        userProfileView.makeLoadingSpinner()
        userProfileView.loadingSpinner?.delegate = self
        audioPlayer.playSound(Music.waitingMusic, volume: constants.volumeForWaitingMusic)
        let nicknameView = userProfileView.userInfoView.nicknameView.mainView as? UITextField
        if let nickname = nicknameView?.text, nickname.count >= constants.minimumSymbolsInData && nickname.count <= constants.maximumSymbolsInData {
            if !storage.checkIfGoogleSignIn() && !storage.currentUser.guestMode {
                let email = userProfileView.userInfoView.emailView?.text
                let password = userProfileView.userInfoView.passwordView?.text
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
    
    private func updateNickname(with newValue: String) {
        storage.currentUser.updateNickname(newValue: newValue)
        if let mainMenuVC = presentingViewController as? MainMenuVC {
            mainMenuVC.updateUserData()
            mainMenuVC.updateNotificationIcons()
        }
        userProfileView.userInfoView.nicknameView.removeNotificationIcon()
        updateUserResultAlert(with: "Action completed", and: "Data updated!")
        audioPlayer.playSound(Sounds.successSound)
    }
    
    private func updateUserResultAlert(with title: String, and message: String) {
        print(message)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        UIApplication.getTopMostViewController()?.present(alert, animated: true)
        userProfileView.userInfoView.emailView?.text = storage.currentUser.email
        (userProfileView.userInfoView.nicknameView.mainView as? UITextField)?.text = storage.currentUser.nickname
        userProfileView.userInfoView.passwordView?.text?.removeAll()
        userProfileView.removeLoadingSpinner()
        userProfileView.toggleViews()
    }
    
}

// MARK: - UserInfoViewDelegate

extension UserProfileVC: UserInfoViewDelegate {
    
    func userInfoViewDidToggleMusic(_ userInfoView: UserInfoView) {
        audioPlayer.playSound(Sounds.toggleSound)
        audioPlayer.musicEnabled.toggle()
        audioPlayer.musicEnabled ? audioPlayer.playSound(Music.menuBackgroundMusic) : audioPlayer.pauseSound(Music.menuBackgroundMusic)
        storage.currentUser.updateMusicEnabled(newValue: audioPlayer.musicEnabled)
    }
    
    func userInfoViewDidToggleSounds(_ userInfoView: UserInfoView) {
        audioPlayer.soundsEnabled.toggle()
        audioPlayer.playSound(Sounds.toggleSound)
        storage.currentUser.updateSoundsEnabled(newValue: audioPlayer.soundsEnabled)
    }
    
}

// MARK: - UserProfileViewDelegate

extension UserProfileVC: UserProfileViewDelegate {
    
    func userProfileViewDidToggleViews(_ userProfileView: UserProfileView) {
        audioPlayer.playSound(Sounds.pickItemSound)
        userProfileView.updateAvatar(with: storage.currentUser.playerAvatar)
    }
    
}

// MARK: - LoadingSpinnerDelegate

extension UserProfileVC: LoadingSpinnerDelegate {
    
    func loadingSpinnerDidRemoveFromSuperview(_ loadingSpinner: LoadingSpinner) {
        audioPlayer.pauseSound(Music.waitingMusic)
    }
    
}
