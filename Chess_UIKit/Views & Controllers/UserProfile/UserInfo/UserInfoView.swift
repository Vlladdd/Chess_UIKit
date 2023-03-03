//
//  UserInfoView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

//class that represents view with user info, which is basically just multiple UPDataLines
class UserInfoView: UIScrollView {
    
    // MARK: - Properties
    
    private typealias constants = UserInfoView_Constants
    
    private let font: UIFont
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    
    private(set) var nicknameView: ViewWithNotifIcon!
    //not everytime email and password will be available
    //for example, in guest mode
    private(set) var emailView: UITextField?
    private(set) var passwordView: UITextField?
    
    // MARK: - Inits
    
    init(font: UIFont) {
        self.font = font
        super.init(frame: .zero)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func toggleMusic(_ sender: UISwitch? = nil) {
        audioPlayer.musicEnabled.toggle()
        audioPlayer.musicEnabled ? audioPlayer.playSound(Music.menuBackgroundMusic) : audioPlayer.pauseSound(Music.menuBackgroundMusic)
        storage.currentUser.updateMusicEnabled(newValue: audioPlayer.musicEnabled)
    }
    
    @objc private func toggleSounds(_ sender: UISwitch? = nil) {
        audioPlayer.soundsEnabled.toggle()
        storage.currentUser.updateSoundsEnabled(newValue: audioPlayer.soundsEnabled)
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        delaysContentTouches = false
        let userInfoStack = UIStackView()
        userInfoStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        if storage.currentUser.guestMode {
            userInfoStack.addArrangedSubview(makeNicknameLine())
        }
        else if storage.checkIfGoogleSignIn() {
            userInfoStack.addArrangedSubviews([makeNicknameLine(), makeEmailLineForGoogleSignIn()])
        }
        else {
            userInfoStack.addArrangedSubviews([makeNicknameLine(), makeEmailLineForEmailSignIn(), makePasswordLine()])
        }
        if storage.currentUser.nickname.isEmpty {
            nicknameView.addNotificationIcon()
        }
        userInfoStack.addArrangedSubviews([makeMusicLine(), makeSoundsLine()])
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let contentHeight = contentView.heightAnchor.constraint(equalTo: heightAnchor)
        contentHeight.priority = .defaultLow
        contentView.addSubview(userInfoStack)
        addSubview(contentView)
        let contentConstraints = [contentView.topAnchor.constraint(equalTo: topAnchor), contentView.leadingAnchor.constraint(equalTo: leadingAnchor), contentView.trailingAnchor.constraint(equalTo: trailingAnchor), contentView.bottomAnchor.constraint(equalTo: bottomAnchor), contentView.widthAnchor.constraint(equalTo: widthAnchor), contentHeight]
        let dataConstraints = [userInfoStack.topAnchor.constraint(equalTo: contentView.topAnchor), userInfoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), userInfoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -constants.optimalDistance), userInfoStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)]
        NSLayoutConstraint.activate(contentConstraints + dataConstraints)
    }
    
    private func makeNicknameLine() -> UPDataLine {
        let nicknameLine = UPDLBuilder()
            .addLabel(with: font, and: "Nickname")
            .addTextField(with: font, placeHolder: "Enter new nickname", and: storage.currentUser.nickname, isNotifView: true)
            .build()
        if let nicknameView = nicknameLine.data as? ViewWithNotifIcon {
            self.nicknameView = nicknameView
        }
        return nicknameLine
    }
    
    //currently user can`t change email, if signed in with Google account
    private func makeEmailLineForGoogleSignIn() -> UPDataLine {
        return UPDLBuilder()
            .addLabel(with: font, and: "Email")
            .addTextData(with: font, and: storage.currentUser.email)
            .build()
    }
    
    private func makeEmailLineForEmailSignIn() -> UPDataLine {
        let emailLine = UPDLBuilder()
            .addLabel(with: font, and: "Email")
            .addTextField(with: font, placeHolder: "Enter new email", and: storage.currentUser.email, isNotifView: false)
            .build()
        if let emailView = emailLine.data as? UITextField {
            self.emailView = emailView
        }
        return emailLine
    }
    
    private func makePasswordLine() -> UPDataLine {
        let passwordLine = UPDLBuilder()
            .addLabel(with: font, and: "Password")
            .addTextField(with: font, placeHolder: "Enter new password", and: nil, isNotifView: false)
            .build()
        if let passwordView = passwordLine.data as? UITextField {
            self.passwordView = passwordView
        }
        return passwordLine
    }
    
    private func makeMusicLine() -> UPDataLine {
        return UPDLBuilder()
            .addLabel(with: font, and: "Music enabled")
            .addSwitch(with: audioPlayer.musicEnabled, and: #selector(toggleMusic))
            .build()
    }
    
    private func makeSoundsLine() -> UPDataLine {
        return UPDLBuilder()
            .addLabel(with: font, and: "Sounds enabled")
            .addSwitch(with: audioPlayer.soundsEnabled, and: #selector(toggleSounds))
            .build()
    }
    
}

// MARK: - Constants

private struct UserInfoView_Constants {
    static let optimalSpacing = 5.0
    static let optimalDistance = 20.0
}
