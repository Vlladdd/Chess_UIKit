//
//  MainMenuView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 02.02.2023.
//

import UIKit

//class that represents main menu view
class MainMenuView: UIView, MainMenuViewDelegate {

    // MARK: - MainMenuViewDelegate
    
    weak var mainMenuDelegate: MainMenuDelegate? {
        didSet {
            (userDataView.mainView as? UserDataView)?.delegate = mainMenuDelegate
        }
    }
    
    //font for all views, that are part of main menu view
    let font: UIFont
    
    //one buttonsStack goes up, another from down or vice versa(reversed)
    //if backButton is not part of a stack it goes from left to right or vice versa
    func makeMenu(with elements: UIStackView, reversed: Bool) {
        let extraYForBSAnimation = buttonsView?.contentSize.height ?? 0
        buttonsView?.removeWithAnimation(reversed: reversed)
        additionalButtons?.removeWithAnimation()
        if let elements = elements as? AdditionalButtonsDelegate {
            makeAdditionalButtons(for: elements)
        }
        else {
            additionalButtons = nil
        }
        makeButtonsView(with: elements)
        layoutIfNeeded()
        buttonsView?.animateAppearance(reversed: reversed, extraY: extraYForBSAnimation)
        additionalButtons?.animateAppearance()
        updateNotificationIcons()
        audioPlayer.playSound(Sounds.moveSound1)
    }
    
    func updateNotificationIcons() {
        if storage.currentUser.haveNewAvatarsInInventory() || storage.currentUser.nickname.isEmpty {
            userDataView.addNotificationIcon()
        }
        else {
            userDataView.removeNotificationIcon()
        }
        if let buttonsStack = buttonsView?.buttonsStack as? NotificationIconsDelegate {
            buttonsStack.updateNotificationIcons()
        }
        if let userProfileVC = mainMenuDelegate?.presentedViewController as? UserProfileVC {
            userProfileVC.userProfileView.updateNotificationIcons()
        }
    }
    
    func buyItem(itemView: ItemView, additionalChanges: @escaping () -> Void) {
        if let coinsText = additionalButtons?.coinsText {
            let itemName = itemView.item.getHumanReadableName()
            let alert = UIAlertController(title: "Buy \(itemName)", message: "Are you sure?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
                guard let self else { return }
                self.audioPlayer.playSound(Sounds.buyItemSound)
                self.storage.currentUser.addAvailableItem(itemView.item)
                var startCoins = self.storage.currentUser.coins
                self.storage.currentUser.addCoins(-itemView.item.cost)
                let endCoins = self.storage.currentUser.coins
                let snapshotOfItemView = itemView.snapshotView(afterScreenUpdates: true)!
                self.addSubview(snapshotOfItemView)
                let snapshotConstraints = [snapshotOfItemView.leadingAnchor.constraint(equalTo: self.leadingAnchor), snapshotOfItemView.topAnchor.constraint(equalTo: self.topAnchor)]
                NSLayoutConstraint.activate(snapshotConstraints)
                let actualPosOfSnapshot = snapshotOfItemView.convert(itemView.bounds, from: itemView)
                snapshotOfItemView.transform = CGAffineTransform(translationX: actualPosOfSnapshot.minX, y: actualPosOfSnapshot.minY)
                let coinsBoundsForAnimation = snapshotOfItemView.convert(coinsText.bounds, from: coinsText)
                UIView.animate(withDuration: constants.animationDuration, animations: {
                    additionalChanges()
                    snapshotOfItemView.transform = constants.transformForItemWhenBought.concatenating(snapshotOfItemView.transform.translatedBy(x: coinsBoundsForAnimation.midX - snapshotOfItemView.bounds.midX, y: coinsBoundsForAnimation.midY - snapshotOfItemView.bounds.midY))
                }) { _ in
                    snapshotOfItemView.removeFromSuperview()
                }
                let interval = constants.animationDuration / Double(startCoins - endCoins)
                let coinsTimer = Timer(timeInterval: interval, repeats: true, block: { timer in
                    if startCoins == endCoins {
                        timer.invalidate()
                        return
                    }
                    startCoins -= 1
                    coinsText.text = String(startCoins)
                })
                coinsTimer.fire()
                RunLoop.main.add(coinsTimer, forMode: .common)
            }))
            mainMenuDelegate?.present(alert, animated: true)
            audioPlayer.playSound(Sounds.openPopUpSound)
        }
    }
    
    // MARK: - Properties
    
    private typealias constants = MainMenuView_Constants
    
    private var additionalButtons: AdditionalButtons?
    private var buttonsView: MMButtonsView?
    private var userDataView: ViewWithNotifIcon!
    
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    
    // MARK: - Inits
    
    init(widthForAvatar: CGFloat, fontSize: CGFloat) {
        font = UIFont.systemFont(ofSize: fontSize)
        super.init(frame: .zero)
        setup(widthForAvatar: widthForAvatar)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup(widthForAvatar: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        makeBackground()
        makeUserData(widthForAvatar: widthForAvatar, font: font)
        makeMenu(with: MMBasicButtons(delegate: self), reversed: false)
    }
    
    //makes background of the view
    private func makeBackground() {
        let background = UIImageView()
        background.translatesAutoresizingMaskIntoConstraints = false
        background.setImage(with: MiscImages.defaultBG)
        background.contentMode = .scaleAspectFill
        background.layer.masksToBounds = true
        addSubview(background)
        let backgroundConstraints = [background.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor), background.leadingAnchor.constraint(equalTo: leadingAnchor), background.trailingAnchor.constraint(equalTo: trailingAnchor), background.bottomAnchor.constraint(equalTo: bottomAnchor)]
        NSLayoutConstraint.activate(backgroundConstraints)
    }
    
    private func makeUserData(widthForAvatar: CGFloat, font: UIFont) {
        let userData = UserDataView(widthForAvatar: widthForAvatar, font: font)
        userDataView = ViewWithNotifIcon(mainView: userData, height: nil)
        addSubview(userDataView)
        let userDataConstraints = [userDataView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: constants.optimalDistance), userDataView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor, constant: -constants.optimalDistance), userDataView.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor, constant: constants.optimalDistance), userDataView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor)]
        NSLayoutConstraint.activate(userDataConstraints)
    }
    
    private func makeButtonsView(with buttonsStack: UIStackView) {
        buttonsView = MMButtonsView(buttonsStack: buttonsStack)
        if let buttonsView {
            addSubview(buttonsView)
            var buttonsViewBottomConstraint = buttonsView.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor)
            if let additionalButtons {
                buttonsViewBottomConstraint = buttonsView.bottomAnchor.constraint(lessThanOrEqualTo: additionalButtons.topAnchor, constant: -constants.optimalDistance)
            }
            let centerXForButtonsView = buttonsView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor)
            centerXForButtonsView.priority = .defaultLow
            let centerYForButtonsView = buttonsView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor)
            centerYForButtonsView.priority = .defaultLow
            let buttonsViewConstraints = [buttonsView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor), buttonsView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor), buttonsView.topAnchor.constraint(greaterThanOrEqualTo: userDataView.bottomAnchor, constant: constants.optimalDistance), centerXForButtonsView, centerYForButtonsView, buttonsViewBottomConstraint]
            NSLayoutConstraint.activate(buttonsViewConstraints)
        }
    }
    
    private func makeAdditionalButtons(for elements: AdditionalButtonsDelegate) {
        additionalButtons = elements.makeAdditionalButtons()
        if let additionalButtons {
            addSubview(additionalButtons)
            let additionalButtonsConstraints = [additionalButtons.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor), additionalButtons.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor), additionalButtons.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)]
            NSLayoutConstraint.activate(additionalButtonsConstraints)
        }
    }
    
    //when view appears
    func animateTransition() {
        if let buttonsView {
            for subview in buttonsView.buttonsStack.arrangedSubviews {
                subview.randomAAnimation(with: constants.animationDuration)
            }
        }
        if let additionalButtons {
            additionalButtons.randomAAnimation(with: constants.animationDuration)
        }
        userDataView.randomAAnimation(with: constants.animationDuration)
        audioPlayer.playSound(Sounds.moveSound2)
    }
    
    //when changes made in user profile view
    func updateUserData() {
        if let userDataView = userDataView.mainView as? UserDataView {
            userDataView.updateUserData()
        }
    }
    
    //when device changed orientation
    func onRotate() {
        if let buttonsStack = buttonsView?.buttonsStack as? ItemsView {
            buttonsStack.onRotate()
        }
    }
    
}

// MARK: - Constants

private struct MainMenuView_Constants {
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let optimalDistance = 10.0
    static let animationDuration = 0.5
    static let transformForItemWhenBought = CGAffineTransform(scaleX: 0.01, y: 0.01)
}
