//
//  MMGameButtons.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 08.02.2023.
//

import UIKit

// MARK: - MMGameButtonsDelegate

protocol MMGameButtonsDelegate: AnyObject {
    func gameButtonsDidTriggerToggleCreateGameVC(_ gameButtons: MMGameButtons) -> Void
    func gameButtonsDidTriggerUserGamesMenu(_ gameButtons: MMGameButtons) -> Void
    func gameButtonsDidTriggerMPGamesMenu(_ gameButtons: MMGameButtons) -> Void
    func gameButtonsDidTriggerBackAction(_ gameButtons: MMGameButtons) -> Void
}

// MARK: - MMGameButtons

//class that represents game buttons in main menu
class MMGameButtons: UIStackView {
    
    // MARK: - Properties
    
    weak var delegate: MMGameButtonsDelegate?
    
    private typealias constants = MMGameButtons_Constants
    
    // MARK: - Inits
    
    init(font: UIFont, isGuestMode: Bool) {
        super.init(frame: .zero)
        setup(with: font, isGuestMode: isGuestMode)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    //shows/hides view for game creation
    @objc private func showCreateGameVC(_ sender: UIButton? = nil) {
        delegate?.gameButtonsDidTriggerToggleCreateGameVC(self)
    }
    
    //creates games for load, if they ended or in oneScreen mode
    @objc private func makeUserGamesList(_ sender: UIButton? = nil) {
        delegate?.gameButtonsDidTriggerUserGamesMenu(self)
    }
    
    //creates list of multiplayer games available for join
    @objc private func makeMultiplayerGamesList(_ sender: UIButton? = nil) {
        delegate?.gameButtonsDidTriggerMPGamesMenu(self)
    }
    
    @objc private func goBack(_ sender: UIButton? = nil) {
        delegate?.gameButtonsDidTriggerBackAction(self)
    }
    
    // MARK: - Local Methods
    
    private func setup(with font: UIFont, isGuestMode: Bool) {
        setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let createButton = MMButtonView(backgroundImageItem: MiscImages.createButtonBG, buttonImageItem: nil, buttontext: "Create", action: #selector(showCreateGameVC), font: font, needHeightConstraint: true)
        let joinButton = MMButtonView(backgroundImageItem: MiscImages.joinButtonBG, buttonImageItem: nil, buttontext: "Join", action: #selector(makeMultiplayerGamesList), font: font, needHeightConstraint: true)
        let loadButton = MMButtonView(backgroundImageItem: MiscImages.loadButtonBG, buttonImageItem: nil, buttontext: "Load", action: #selector(makeUserGamesList), font: font, needHeightConstraint: true)
        if isGuestMode {
            joinButton.button?.isEnabled = false
        }
        let backButton = MMButtonView(backgroundImageItem: nil, buttonImageItem: nil, buttontext: "Back", action: #selector(goBack), font: font, needHeightConstraint: true)
        backButton.addBackButtonSFImage()
        addArrangedSubviews([createButton, joinButton, loadButton, backButton])
    }
    
}

// MARK: - Constants

private struct MMGameButtons_Constants {
    static let optimalSpacing = 5.0
}

