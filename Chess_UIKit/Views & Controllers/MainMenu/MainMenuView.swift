//
//  MainMenuView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 02.02.2023.
//

import UIKit

//class that represents main menu view
class MainMenuView: UIView {
    
    // MARK: - Properties
    
    private typealias constants = MainMenuView_Constants
    
    private var additionalButtons: AdditionalButtons?
    
    //font for all views, that are part of main menu view
    private let font: UIFont
    
    private(set) var buttonsView: MMButtonsView?
    private(set) var userDataView: ViewWithNotifIcon!
    
    // MARK: - Inits
    
    init(widthForAvatar: CGFloat, font: UIFont, userNickname: String, userAvatar: Avatars) {
        self.font = font
        super.init(frame: .zero)
        setup(with: widthForAvatar, userNickname: userNickname, userAvatar: userAvatar)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup(with widthForAvatar: CGFloat, userNickname: String, userAvatar: Avatars) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        makeBackground()
        makeUserData(with: widthForAvatar, userNickname: userNickname, userAvatar: userAvatar)
    }
    
    //one buttonsStack goes up, another from down or vice versa(reversed)
    //if backButton is not part of a stack it goes from left to right or vice versa
    func makeMenu(with elements: UIStackView, reversed: Bool, additionalButtons: AdditionalButtons?) {
        let extraYForBSAnimation = buttonsView?.contentSize.height ?? 0
        buttonsView?.removeWithAnimation(reversed: reversed)
        self.additionalButtons?.removeWithAnimation()
        self.additionalButtons = additionalButtons
        setupAdditionalButtons()
        makeButtonsView(with: elements)
        layoutIfNeeded()
        buttonsView?.animateAppearance(reversed: reversed, extraY: extraYForBSAnimation)
        additionalButtons?.animateAppearance()
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
    
    private func makeUserData(with widthForAvatar: CGFloat, userNickname: String, userAvatar: Avatars) {
        let userData = UserDataView(widthForAvatar: widthForAvatar, font: font, nickname: userNickname, avatar: userAvatar)
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
            if let buttonsStack = buttonsStack as? GamesView, buttonsStack.isMultiplayerGames {
                buttonsView.topAnchor.constraint(equalTo: userDataView.bottomAnchor, constant: constants.optimalDistance).isActive = true
            }
            else {
                let centerXForButtonsView = buttonsView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor)
                centerXForButtonsView.priority = .defaultLow
                let centerYForButtonsView = buttonsView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor)
                centerYForButtonsView.priority = .defaultLow
                centerXForButtonsView.isActive = true
                centerYForButtonsView.isActive = true
                buttonsView.topAnchor.constraint(greaterThanOrEqualTo: userDataView.bottomAnchor, constant: constants.optimalDistance).isActive = true
            }
            let buttonsViewConstraints = [buttonsView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor), buttonsView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor), buttonsViewBottomConstraint]
            NSLayoutConstraint.activate(buttonsViewConstraints)
        }
    }
    
    private func setupAdditionalButtons() {
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
    }
    
    //when device changed orientation
    func onRotate() {
        if let buttonsStack = buttonsView?.buttonsStack as? ItemsView {
            buttonsStack.onRotate()
        }
    }
    
    func buyItem(itemView: ItemView, startCoins: Int, endCoins: Int) {
        if let coinsText = additionalButtons?.coinsText {
            var startCoins = startCoins
            let snapshotOfItemView = itemView.snapshotView(afterScreenUpdates: true)!
            addSubview(snapshotOfItemView)
            let snapshotConstraints = [snapshotOfItemView.leadingAnchor.constraint(equalTo: leadingAnchor), snapshotOfItemView.topAnchor.constraint(equalTo: topAnchor)]
            NSLayoutConstraint.activate(snapshotConstraints)
            let actualPosOfSnapshot = snapshotOfItemView.convert(itemView.bounds, from: itemView)
            snapshotOfItemView.transform = CGAffineTransform(translationX: actualPosOfSnapshot.minX, y: actualPosOfSnapshot.minY)
            let coinsBoundsForAnimation = snapshotOfItemView.convert(coinsText.bounds, from: coinsText)
            UIView.animate(withDuration: constants.animationDuration, animations: {
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
