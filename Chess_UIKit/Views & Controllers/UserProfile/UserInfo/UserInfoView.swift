//
//  UserInfoView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

// MARK: - UserInfoViewDelegate

protocol UserInfoViewDelegate: AnyObject {
    func userInfoViewDidToggleMusic(_ userInfoView: UserInfoView) -> Void
    func userInfoViewDidToggleSounds(_ userInfoView: UserInfoView) -> Void
}

// MARK: - UserInfoView

//class that represents view with user info, which is basically just multiple DataLines
class UserInfoView: UIScrollView {
    
    // MARK: - Properties
    
    //just to simplify init
    struct Data {
        
        var isGuestMode = false
        var isGoogleSignIn = false
        var musicEnabled = false
        var soundsEnabled = false
        var nickname = ""
        var email = ""
        
        //to prevent big inits
        init() {}
        
    }
    
    weak var userInfoViewDelegate: UserInfoViewDelegate?
    
    private typealias constants = UserInfoView_Constants
    
    private let font: UIFont
    
    private(set) var nicknameView: ViewWithNotifIcon!
    //not everytime email and password will be available
    //for example, in guest mode
    private(set) var emailView: UITextField?
    private(set) var passwordView: UITextField?
    
    // MARK: - Inits
    
    init(font: UIFont, data: UserInfoView.Data) {
        self.font = font
        super.init(frame: .zero)
        setup(with: data)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func toggleMusic(_ sender: UISwitch? = nil) {
        userInfoViewDelegate?.userInfoViewDidToggleMusic(self)
    }
    
    @objc private func toggleSounds(_ sender: UISwitch? = nil) {
        userInfoViewDelegate?.userInfoViewDidToggleSounds(self)
    }
    
    // MARK: - Local Methods
    
    private func setup(with data: UserInfoView.Data) {
        translatesAutoresizingMaskIntoConstraints = false
        delaysContentTouches = false
        let userInfoStack = UIStackView()
        userInfoStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        if data.isGuestMode {
            userInfoStack.addArrangedSubview(makeNicknameLine(with: data.nickname))
        }
        else if data.isGoogleSignIn {
            userInfoStack.addArrangedSubviews([makeNicknameLine(with: data.nickname), makeEmailLineForGoogleSignIn(with: data.email)])
        }
        else {
            userInfoStack.addArrangedSubviews([makeNicknameLine(with: data.nickname), makeEmailLineForEmailSignIn(with: data.email), makePasswordLine()])
        }
        if data.nickname.isEmpty {
            nicknameView.addNotificationIcon()
        }
        userInfoStack.addArrangedSubviews([makeMusicLine(musicEnabled: data.musicEnabled), makeSoundsLine(soundsEnabled: data.soundsEnabled)])
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
    
    private func makeNicknameLine(with nickname: String) -> DataLine {
        let nicknameLine = UPDLBuilder()
            .addLabel(with: font, and: "Nickname")
            .addTextField(with: font, placeHolder: "Enter new nickname", and: nickname, isNotifView: true)
            .build()
        if let nicknameView = nicknameLine.data as? ViewWithNotifIcon {
            self.nicknameView = nicknameView
        }
        return nicknameLine
    }
    
    //currently user can`t change email, if signed in with Google account
    private func makeEmailLineForGoogleSignIn(with email: String) -> DataLine {
        return UPDLBuilder()
            .addLabel(with: font, and: "Email")
            .addTextData(with: font, and: email)
            .build()
    }
    
    private func makeEmailLineForEmailSignIn(with email: String) -> DataLine {
        let emailLine = UPDLBuilder()
            .addLabel(with: font, and: "Email")
            .addTextField(with: font, placeHolder: "Enter new email", and: email, isNotifView: false)
            .build()
        if let emailView = emailLine.data as? UITextField {
            self.emailView = emailView
        }
        return emailLine
    }
    
    private func makePasswordLine() -> DataLine {
        let passwordLine = UPDLBuilder()
            .addLabel(with: font, and: "Password")
            .addTextField(with: font, placeHolder: "Enter new password", and: nil, isNotifView: false)
            .build()
        if let passwordView = passwordLine.data as? UITextField {
            self.passwordView = passwordView
        }
        return passwordLine
    }
    
    private func makeMusicLine(musicEnabled: Bool) -> DataLine {
        return UPDLBuilder()
            .addLabel(with: font, and: "Music enabled")
            .addSwitch(with: musicEnabled, and: #selector(toggleMusic))
            .build()
    }
    
    private func makeSoundsLine(soundsEnabled: Bool) -> DataLine {
        return UPDLBuilder()
            .addLabel(with: font, and: "Sounds enabled")
            .addSwitch(with: soundsEnabled, and: #selector(toggleSounds))
            .build()
    }
    
}

// MARK: - Constants

private struct UserInfoView_Constants {
    static let optimalSpacing = 5.0
    static let optimalDistance = 20.0
}
