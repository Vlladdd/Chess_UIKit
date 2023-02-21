//
//  MMGameButtons.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 08.02.2023.
//

import UIKit

//class that represents game buttons in main menu
class MMGameButtons: UIStackView {
    
    // MARK: - Properties
    
    weak var delegate: MainMenuViewDelegate?
    
    private typealias constants = MMGameButtons_Constants
    
    private let storage = Storage.sharedInstance
    
    // MARK: - Inits
    
    init(delegate: MainMenuViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    //shows/hides view for game creation
    @objc private func showCreateGameVC(_ sender: UIButton? = nil) {
        delegate?.mainMenuDelegate?.toggleCreateGameVC()
    }
    
    //creates games for load, if they ended or in oneScreen mode
    @objc private func makeUserGamesList(_ sender: UIButton? = nil) {
        if let delegate {
            let gamesView = GamesView(games: storage.currentUser.games, delegate: delegate)
            delegate.makeMenu(with: gamesView, reversed: false)
        }
    }
    
    //creates list of multiplayer games available for join
    @objc private func makeMultiplayerGamesList(_ sender: UIButton? = nil) {
        if let delegate {
            let gamesView = GamesView(games: nil, delegate: delegate)
            delegate.makeMenu(with: gamesView, reversed: false)
        }
    }
    
    @objc private func goBack(_ sender: UIButton? = nil) {
        if let delegate {
            delegate.makeMenu(with: MMBasicButtons(delegate: delegate), reversed: true)
        }
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        if let delegate {
            setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
            let createButton = MMButtonView(backgroundImageItem: MiscImages.createButtonBG, buttonImageItem: nil, buttontext: "Create", action: #selector(showCreateGameVC), fontSize: delegate.font.pointSize, needHeightConstraint: true)
            let joinButton = MMButtonView(backgroundImageItem: MiscImages.joinButtonBG, buttonImageItem: nil, buttontext: "Join", action: #selector(makeMultiplayerGamesList), fontSize: delegate.font.pointSize, needHeightConstraint: true)
            let loadButton = MMButtonView(backgroundImageItem: MiscImages.loadButtonBG, buttonImageItem: nil, buttontext: "Load", action: #selector(makeUserGamesList), fontSize: delegate.font.pointSize, needHeightConstraint: true)
            if storage.currentUser.guestMode {
                joinButton.button?.isEnabled = false
            }
            let backButton = MMButtonView(backgroundImageItem: nil, buttonImageItem: nil, buttontext: "Back", action: #selector(goBack), fontSize: delegate.font.pointSize, needHeightConstraint: true)
            backButton.addBackButtonSFImage()
            addArrangedSubviews([createButton, joinButton, loadButton, backButton])
        }
    }
    
}

// MARK: - Constants

private struct MMGameButtons_Constants {
    static let optimalSpacing = 5.0
}

