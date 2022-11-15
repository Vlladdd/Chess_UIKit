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
    
    // MARK: - Properties
    
    private typealias constants = UserProfileVC_Constants
    
    var currentUser: User!
    
    private let storage = Storage()
    
    // MARK: - Buttons Methods
    
    @objc private func close(_ sender: UIBarButtonItem? = nil) {
        dismiss(animated: true)
    }
    
    @objc private func updateUser(_ sender: UIBarButtonItem? = nil) {
        toggleViews()
        makeLoadingSpinner()
        let nicknameView = nicknameLine.arrangedSubviews.second?.subviews.first as? UITextField ?? nicknameLine.arrangedSubviews.second as? UITextField
        if !storage.checkIfGoogleSignIn() {
            let email = (emailLine.arrangedSubviews.second as? UITextField)?.text
            let password = (passwordLine.arrangedSubviews.second as? UITextField)?.text
            if let nickname = nicknameView?.text, let email = email, let password = password, nickname.count >= constants.minimumSymbolsInData && nickname.count <= constants.maximumSymbolsInData  {
                storage.updateUserAccount(with: email, and: password, callback: { [weak self] error in
                    if let self = self {
                        guard error == nil else {
                            self.updateUserResultAlert(with: "Error", and: error!.localizedDescription)
                            return
                        }
                        self.currentUser.updateEmail(newValue: email)
                        self.updateNickname(newValue: nickname, nicknameView: nicknameView!)
                    }
                })
            }
            else {
                updateUserResultAlert(with: "Error", and: "Nickname must be longer than \(constants.minimumSymbolsInData - 1) and less than \(constants.maximumSymbolsInData + 1)")
            }
        }
        else if let nickname = nicknameView?.text {
            updateNickname(newValue: nickname, nicknameView: nicknameView!)
        }
    }
    
    @objc private func toggleAvatars(_ sender: UITapGestureRecognizer? = nil) {
        updateButton.isEnabled.toggle()
        if avatarsScrollView.alpha == 0 {
            userAvatar.layer.borderColor = constants.pickItemBorderColor
            switchCurrentViews(viewsToExit: [dataScrollView], viewsToEnter: [avatarsScrollView, avatarInfoScrollView], xForAnimation: view.frame.width)
        }
        else {
            userAvatar.layer.borderColor = defaultTextColor.cgColor
            switchCurrentViews(viewsToExit: [avatarsScrollView, avatarInfoScrollView], viewsToEnter: [dataScrollView], xForAnimation: -view.frame.width)
        }
    }
    
    @objc private func pickAvatar(_ sender: UITapGestureRecognizer? = nil) {
        if let sender = sender {
            if let avatar = sender.view?.layer.value(forKey: constants.keyForAvatar) as? Avatars {
                currentUser.addSeenItem(avatar)
                for avatarLine in avatarsView.arrangedSubviews {
                    if let avatarLine = avatarLine as? UIStackView {
                        resetPickedAvatar(in: avatarLine)
                    }
                }
                resetPickedAvatar(in: avatarsLastLine)
                if currentUser.availableItems.contains(where: {$0 as? Avatars == avatar}) {
                    currentUser.setValue(with: avatar)
                    storage.saveUser(currentUser)
                    sender.view?.subviews.first?.backgroundColor = constants.chosenItemColor
                }
                UIView.transition(with: userAvatar, duration: constants.animationDuration, options: .transitionCrossDissolve, animations: {[weak self] in
                    if let self = self {
                        self.userAvatar.image = UIImage(named: "avatars/\(avatar.rawValue)")
                    }
                })
                avatarInfo.text = avatar.description
                sender.view?.layer.borderColor = constants.pickItemBorderColor
                if let mainMenuVC = presentingViewController as? MainMenuVC {
                    mainMenuVC.currentUser = currentUser
                    mainMenuVC.updateUserData()
                    mainMenuVC.removeNotificationIconsIfNeeded()
                }
                if let viewWithNotif = sender.view?.superview as? ViewWithNotifIcon {
                    viewWithNotif.removeNotificationIcon()
                }
            }
        }
    }
    
    // MARK: - Local Methods
    
    private func updateNickname(newValue: String, nicknameView: UIView) {
        currentUser.updateNickname(newValue: newValue)
        storage.saveUser(currentUser)
        if let mainMenuVC = presentingViewController as? MainMenuVC {
            mainMenuVC.currentUser = currentUser
            mainMenuVC.updateUserData()
            mainMenuVC.removeNotificationIconsIfNeeded()
        }
        if let viewWithNotif = nicknameView.superview as? ViewWithNotifIcon {
            viewWithNotif.removeNotificationIcon()
        }
        updateUserResultAlert(with: "Action completed", and: "Data updated!")
    }
    
    private func updateUserResultAlert(with title: String, and message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        UIApplication.getTopMostViewController()?.present(alert, animated: true)
        loadingSpinner.removeFromSuperview()
        toggleViews()
    }
    
    //when we add/remove loading spinner
    private func toggleViews() {
        toolbar.isHidden.toggle()
        dataScrollView.isHidden.toggle()
        userAvatar.isHidden.toggle()
    }
    
    private func resetPickedAvatar(in avatarsLine: UIStackView) {
        for avatarView in avatarsLine.arrangedSubviews {
            if let viewWithNotif = avatarView as? ViewWithNotifIcon {
                viewWithNotif.mainView.layer.borderColor = defaultTextColor.cgColor
                viewWithNotif.mainView.subviews.first?.backgroundColor = getColorForAvatar(from: viewWithNotif.mainView)
            }
            else {
                avatarView.layer.borderColor = defaultTextColor.cgColor
                avatarView.subviews.first?.backgroundColor = getColorForAvatar(from: avatarView)
            }
        }
    }
    
    private func getColorForAvatar(from avatarView: UIView) -> UIColor {
        var color = defaultBackgroundColor
        if let avatar = avatarView.layer.value(forKey: constants.keyForAvatar) as? Avatars {
            if avatar == currentUser.playerAvatar {
                color = constants.chosenItemColor
            }
            else if !currentUser.availableItems.contains(where: {$0 as? Avatars == avatar}) {
                color = constants.notAvailableColor
            }
        }
        return color
    }
    
    //toggles avatarsView/dataFieldsStack
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
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private lazy var fontSize = min(view.frame.width, view.frame.height) / constants.dividerForFont
    private lazy var defaultFont = UIFont.systemFont(ofSize: fontSize)
    private lazy var defaultBackgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
    private lazy var defaultTextColor = traitCollection.userInterfaceStyle == .dark ? constants.lightModeTextColor : constants.darkModeTextColor
    
    private let dataScrollView = UIScrollView()
    private let dataScrollViewContent = UIView()
    private let avatarsScrollView = UIScrollView()
    private let avatarsScrollViewContent = UIView()
    private let avatarInfoScrollView = UIScrollView()
    //size is random, without it, it will make unsatisfied constraints errors
    private let toolbar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 44.0)))
    private let dataFieldsStack = UIStackView()
    private let avatarInfo = UILabel()
    private let userAvatar = UIImageView()
    private let avatarsView = UIStackView()
    private let avatarsLastLine = UIStackView()
    
    private var loadingSpinner = LoadingSpinner()
    private var nicknameLine = UIStackView()
    private var emailLine = UIStackView()
    private var passwordLine = UIStackView()
    private var updateButton = UIBarButtonItem()
    
    // MARK: - UI Methods
    
    private func makeUI() {
        view.backgroundColor = defaultBackgroundColor
        makeToolBar()
        makeAvatar()
        makeAvatarInfoView()
        setupScrollView(dataScrollView, content: dataScrollViewContent, forAvatars: false)
        setupScrollView(avatarsScrollView, content: avatarsScrollViewContent, forAvatars: true)
        avatarsScrollView.alpha = 0
        makeAvatarsView()
        makeDataFields()
    }
    
    private func makeAvatar() {
        let widthForAvatar = min(view.frame.height, view.frame.width) / constants.sizeMultiplayerForAvatar
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleAvatars))
        userAvatar.rectangleView(width: widthForAvatar)
        userAvatar.contentMode = .scaleAspectFill
        userAvatar.layer.masksToBounds = true
        userAvatar.image = UIImage(named: "avatars/\(currentUser.playerAvatar.rawValue)")
        userAvatar.addGestureRecognizer(tapGesture)
        view.addSubview(userAvatar)
        let avatarConstraints = [userAvatar.topAnchor.constraint(equalTo: toolbar.layoutMarginsGuide.bottomAnchor, constant: constants.optimalDistance), userAvatar.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor)]
        NSLayoutConstraint.activate(avatarConstraints)
    }
    
    private func makeDataFields() {
        dataFieldsStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        nicknameLine = makeLine(with: "Nickname", textFieldPlaceholder: "Enter new nickname", textFieldText: currentUser.nickname)
        if storage.checkIfGoogleSignIn() {
            emailLine = makeLine(with: "Email", labelData: currentUser.email)
            dataFieldsStack.addArrangedSubviews([nicknameLine, emailLine])
        }
        else {
            emailLine = makeLine(with: "Email", textFieldPlaceholder: "Enter new email", textFieldText: currentUser.email)
            passwordLine = makeLine(with: "Password", textFieldPlaceholder: "Enter new password", textFieldText: nil)
            dataFieldsStack.addArrangedSubviews([nicknameLine, emailLine, passwordLine])
        }
        if currentUser.nickname.isEmpty {
            let field = nicknameLine.arrangedSubviews.second!
            let nicknameView = ViewWithNotifIcon(mainView: field, cornerRadius: fontSize / constants.minimumDividerForCornerRadius)
            nicknameLine.addArrangedSubview(nicknameView)
        }
        dataScrollViewContent.addSubview(dataFieldsStack)
        let dataConstraints = [dataFieldsStack.topAnchor.constraint(equalTo: dataScrollViewContent.topAnchor, constant: constants.optimalDistance), dataFieldsStack.leadingAnchor.constraint(equalTo: dataScrollViewContent.layoutMarginsGuide.leadingAnchor), dataFieldsStack.trailingAnchor.constraint(equalTo: dataScrollViewContent.layoutMarginsGuide.trailingAnchor, constant: -constants.optimalDistance), dataFieldsStack.bottomAnchor.constraint(lessThanOrEqualTo: dataScrollViewContent.bottomAnchor)]
        NSLayoutConstraint.activate(dataConstraints)
    }
    
    private func makeAvatarInfoView() {
        avatarInfoScrollView.translatesAutoresizingMaskIntoConstraints = false
        avatarInfoScrollView.alpha = 0
        avatarInfoScrollView.backgroundColor = defaultBackgroundColor
        avatarInfo.setup(text: currentUser.playerAvatar.description, alignment: .center, font: defaultFont)
        avatarInfo.numberOfLines = 0
        view.addSubview(avatarInfoScrollView)
        avatarInfoScrollView.addSubview(avatarInfo)
        let heightConstraintForAvatarInfo = avatarInfo.heightAnchor.constraint(equalTo: avatarInfoScrollView.heightAnchor)
        heightConstraintForAvatarInfo.priority = .defaultLow
        let centerYConstraintForAvatarInfo = avatarInfo.centerYAnchor.constraint(equalTo: avatarInfoScrollView.centerYAnchor)
        centerYConstraintForAvatarInfo.priority = .defaultLow
        let avatarInfoConstraints = [avatarInfo.topAnchor.constraint(equalTo: avatarInfoScrollView.topAnchor), avatarInfo.leadingAnchor.constraint(equalTo: avatarInfoScrollView.leadingAnchor), avatarInfo.trailingAnchor.constraint(equalTo: avatarInfoScrollView.trailingAnchor), avatarInfo.bottomAnchor.constraint(equalTo: avatarInfoScrollView.bottomAnchor), avatarInfo.widthAnchor.constraint(equalTo: avatarInfoScrollView.widthAnchor), heightConstraintForAvatarInfo, centerYConstraintForAvatarInfo]
        let avatarInfoScrollViewConstraints = [avatarInfoScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor), avatarInfoScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor), avatarInfoScrollView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor), avatarInfoScrollView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: constants.sizeMultiplayerForAvatarInfo)]
        NSLayoutConstraint.activate(avatarInfoConstraints + avatarInfoScrollViewConstraints)
    }
    
    private func makeAvatarsView() {
        avatarsView.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        var avatarsViews = [UIImageView]()
        avatarsLastLine.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        for avatar in Avatars.allCases {
            let avatarView = UIImageView()
            let backgroundView = UIView()
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pickAvatar))
            avatarView.defaultSettings()
            avatarView.isUserInteractionEnabled = true
            avatarView.image = UIImage(named: "avatars/\(avatar.rawValue)")
            avatarView.layer.setValue(avatar, forKey: constants.keyForAvatar)
            avatarView.addGestureRecognizer(tapGesture)
            avatarView.addSubview(backgroundView)
            backgroundView.backgroundColor = getColorForAvatar(from: avatarView)
            if currentUser.playerAvatar == avatar {
                avatarView.layer.borderColor = constants.pickItemBorderColor
            }
            let avatarViewConstraints = [avatarView.heightAnchor.constraint(equalTo: avatarView.widthAnchor), backgroundView.heightAnchor.constraint(equalTo: avatarView.heightAnchor), backgroundView.widthAnchor.constraint(equalTo: avatarView.widthAnchor), backgroundView.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor), backgroundView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)]
            if currentUser.containsNewItemIn(items: [avatar]) {
                let avatarViewWithNotif = ViewWithNotifIcon(mainView: avatarView, cornerRadius: fontSize / constants.minimumDividerForCornerRadius)
                avatarsViews.append(avatarViewWithNotif)
            }
            else {
                avatarsViews.append(avatarView)
            }
            NSLayoutConstraint.activate(avatarViewConstraints)
            if avatarsViews.count == constants.avatarsInLine {
                let avatarsLine = UIStackView()
                avatarsLine.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
                avatarsLine.addArrangedSubviews(avatarsViews)
                avatarsView.addArrangedSubview(avatarsLine)
                avatarsViews = []
            }
        }
        var avatarsViewConstraints = [NSLayoutConstraint]()
        var avatarsLastLineConstraints = [NSLayoutConstraint]()
        if !avatarsViews.isEmpty {
            avatarsLastLine.addArrangedSubviews(avatarsViews)
            avatarsScrollViewContent.addSubview(avatarsLastLine)
        }
        if !avatarsView.arrangedSubviews.isEmpty {
            avatarsScrollViewContent.addSubview(avatarsView)
            avatarsViewConstraints = [avatarsView.topAnchor.constraint(equalTo: avatarsScrollViewContent.topAnchor, constant: constants.optimalDistance), avatarsView.leadingAnchor.constraint(equalTo: avatarsScrollViewContent.leadingAnchor, constant: constants.optimalDistance), avatarsView.trailingAnchor.constraint(equalTo: avatarsScrollViewContent.trailingAnchor, constant: -constants.optimalDistance)]
        }
        if !avatarsView.arrangedSubviews.isEmpty && !avatarsLastLine.arrangedSubviews.isEmpty {
            avatarsLastLineConstraints = [avatarsLastLine.topAnchor.constraint(equalTo: avatarsView.bottomAnchor, constant: constants.optimalSpacing), avatarsLastLine.bottomAnchor.constraint(equalTo: avatarsScrollViewContent.bottomAnchor, constant: -constants.optimalDistance), avatarsLastLine.leadingAnchor.constraint(equalTo: avatarsScrollViewContent.leadingAnchor, constant: constants.optimalDistance), avatarsLastLine.arrangedSubviews.first!.widthAnchor.constraint(equalTo: avatarsView.arrangedSubviews.first!.subviews.first!.widthAnchor)]
        }
        else if !avatarsLastLine.arrangedSubviews.isEmpty {
            avatarsLastLineConstraints = [avatarsLastLine.topAnchor.constraint(equalTo: avatarsScrollViewContent.topAnchor, constant: constants.optimalDistance), avatarsLastLine.bottomAnchor.constraint(equalTo: avatarsScrollViewContent.bottomAnchor, constant: -constants.optimalDistance), avatarsLastLine.leadingAnchor.constraint(equalTo: avatarsScrollViewContent.leadingAnchor, constant: constants.optimalDistance), avatarsLastLine.trailingAnchor.constraint(lessThanOrEqualTo: avatarsScrollViewContent.trailingAnchor, constant: -constants.optimalDistance)]
        }
        else if !avatarsView.arrangedSubviews.isEmpty {
            avatarsViewConstraints.append(avatarsView.bottomAnchor.constraint(equalTo: avatarsScrollViewContent.bottomAnchor, constant: -constants.optimalDistance))
        }
        NSLayoutConstraint.activate(avatarsViewConstraints + avatarsLastLineConstraints)
    }
    
    private func makeLine(with labelText: String, textFieldPlaceholder: String, textFieldText: String?) -> UIStackView {
        let line = UIStackView()
        line.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let lineName = UILabel()
        lineName.setup(text: labelText, alignment: .center, font: defaultFont)
        let lineField = UITextField()
        lineField.setup(placeholder: textFieldPlaceholder, font: defaultFont)
        lineField.text = textFieldText
        line.addArrangedSubviews([lineName, lineField])
        return line
    }
    
    private func makeLine(with labelName: String, labelData: String) -> UIStackView {
        let line = UIStackView()
        line.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let lineName = UILabel()
        lineName.setup(text: labelName, alignment: .center, font: defaultFont)
        let lineDataScrollView = UIScrollView()
        lineDataScrollView.translatesAutoresizingMaskIntoConstraints = false
        lineDataScrollView.delaysContentTouches = false
        let lineData = UILabel()
        lineData.setup(text: labelData, alignment: .center, font: defaultFont)
        lineDataScrollView.addSubview(lineData)
        let widthConstraintForLineData = lineData.widthAnchor.constraint(equalTo: lineDataScrollView.widthAnchor)
        widthConstraintForLineData.priority = .defaultLow
        let centerXConstraintForLineData = lineData.centerXAnchor.constraint(equalTo: lineDataScrollView.centerXAnchor)
        centerXConstraintForLineData.priority = .defaultLow
        let centerYConstraintForLineData = lineData.centerYAnchor.constraint(equalTo: lineDataScrollView.centerYAnchor)
        centerYConstraintForLineData.priority = .defaultLow
        let lineDataConstraints = [lineData.leadingAnchor.constraint(equalTo: lineDataScrollView.leadingAnchor), lineData.trailingAnchor.constraint(equalTo: lineDataScrollView.trailingAnchor), lineData.topAnchor.constraint(equalTo: lineDataScrollView.topAnchor), lineData.bottomAnchor.constraint(equalTo: lineDataScrollView.bottomAnchor), lineData.heightAnchor.constraint(equalTo: lineDataScrollView.heightAnchor), widthConstraintForLineData, centerXConstraintForLineData, centerYConstraintForLineData]
        NSLayoutConstraint.activate(lineDataConstraints)
        line.addArrangedSubviews([lineName, lineDataScrollView])
        return line
    }
    
    private func makeToolBar() {
        let toolbarBackgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        let toolbarBackground = toolbarBackgroundColor.image()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.setBackgroundImage(toolbarBackground, forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(toolbarBackground, forToolbarPosition: .any)
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        let closeButton = UIBarButtonItem(title: "Close", style: UIBarButtonItem.Style.plain, target: self, action: #selector(close))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        updateButton = UIBarButtonItem(title: "Update", style: UIBarButtonItem.Style.done, target: self, action: #selector(updateUser))
        toolbar.setItems([closeButton, spaceButton, updateButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        view.addSubview(toolbar)
        let toolbarConstraints = [toolbar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor), toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor), toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
        NSLayoutConstraint.activate(toolbarConstraints)
    }
    
    private func setupScrollView(_ scrollView: UIScrollView, content: UIView, forAvatars: Bool) {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delaysContentTouches = false
        view.addSubview(scrollView)
        scrollView.addSubview(content)
        let contentHeight = content.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        contentHeight.priority = .defaultLow
        var scrollViewConstraints = [scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor), scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor), scrollView.topAnchor.constraint(equalTo: userAvatar.bottomAnchor, constant: constants.optimalDistance)]
        if forAvatars {
            scrollViewConstraints.append(scrollView.bottomAnchor.constraint(equalTo: avatarInfoScrollView.topAnchor))
        }
        else {
            scrollViewConstraints.append(scrollView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor))
        }
        let contentConstraints = [content.topAnchor.constraint(equalTo: scrollView.topAnchor), content.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor), content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor), content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor), content.widthAnchor.constraint(equalTo: scrollView.widthAnchor), contentHeight]
        NSLayoutConstraint.activate(scrollViewConstraints + contentConstraints)
    }
    
    //makes spinner, while waiting for response
    private func makeLoadingSpinner() {
        loadingSpinner = LoadingSpinner()
        view.addSubview(loadingSpinner)
        let spinnerConstraints = [loadingSpinner.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor), loadingSpinner.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor), loadingSpinner.leadingAnchor.constraint(equalTo: view.leadingAnchor), loadingSpinner.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
        NSLayoutConstraint.activate(spinnerConstraints)
    }
    
    private func removeNotificationIconsIfNeeded(in line: UIStackView) {
        for avatarView in line.arrangedSubviews {
            if let viewWithNotif = avatarView as? ViewWithNotifIcon {
                if let item = viewWithNotif.mainView.layer.value(forKey: constants.keyForAvatar) as? Avatars {
                    if !currentUser.containsNewItemIn(items: [item]) {
                        viewWithNotif.removeNotificationIcon()
                    }
                }
            }
        }
    }
    
    func removeNotificationIconsIfNeeded() {
        removeNotificationIconsIfNeeded(in: avatarsView)
        removeNotificationIconsIfNeeded(in: avatarsLastLine)
    }
    
}

// MARK: - Constants

private struct UserProfileVC_Constants {
    static let minimumSymbolsInData = 5
    static let maximumSymbolsInData = 13
    static let dividerForFont: CGFloat = 13
    static let animationDuration = 0.5
    static let optimalSpacing = 5.0
    static let optimalDistance = 20.0
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let chosenItemColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let notAvailableColor = UIColor.red.withAlphaComponent(optimalAlpha)
    static let darkModeTextColor = UIColor.black
    static let lightModeTextColor = UIColor.white
    static let pickItemBorderColor = UIColor.yellow.cgColor
    static let minimumDividerForCornerRadius = 2.0
    static let sizeMultiplayerForAvatar = 4.0
    static let sizeMultiplayerForAvatarInfo = 0.2
    static let keyForAvatar = "Avatar"
    static let avatarsInLine = 3
}
