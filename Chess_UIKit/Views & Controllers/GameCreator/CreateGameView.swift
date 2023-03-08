//
//  CreateGameView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 06.03.2023.
//

import UIKit

//class that represents view for game creation
class CreateGameView: UIView {
    
    // MARK: - Properties
    
    private typealias constants = CreateGameView_Constants
    
    private var loadingSpinner: LoadingSpinner?
    
    let toolbar = CGToolbar()
    let gameInfoView: GameInfoView
    
    // MARK: - Inits
    
    init(fontSize: CGFloat) {
        let font = UIFont.systemFont(ofSize: fontSize)
        gameInfoView = GameInfoView(font: font)
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        addSubviews([toolbar, gameInfoView])
        let toolbarConstraints = [toolbar.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor), toolbar.leadingAnchor.constraint(equalTo: leadingAnchor), toolbar.trailingAnchor.constraint(equalTo: trailingAnchor)]
        let gameInfoViewConstraints = [gameInfoView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor), gameInfoView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor), gameInfoView.topAnchor.constraint(equalTo: toolbar.layoutMarginsGuide.bottomAnchor, constant: constants.optimalDistance), gameInfoView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)]
        NSLayoutConstraint.activate(gameInfoViewConstraints + toolbarConstraints)
    }
    
    //makes spinner, while waiting for second player to join multiplayer game
    func makeLoadingSpinner() {
        loadingSpinner = LoadingSpinner()
        if let loadingSpinner {
            loadingSpinner.waiting()
            addSubview(loadingSpinner)
            let spinnerConstraints = [loadingSpinner.centerXAnchor.constraint(equalTo: centerXAnchor), loadingSpinner.widthAnchor.constraint(equalTo: widthAnchor), loadingSpinner.topAnchor.constraint(equalTo: toolbar.layoutMarginsGuide.bottomAnchor, constant: constants.optimalDistance), loadingSpinner.bottomAnchor.constraint(equalTo: bottomAnchor)]
            NSLayoutConstraint.activate(spinnerConstraints)
        }
    }
    
    func removeLoadingSpinner() {
        loadingSpinner?.removeFromSuperview()
        loadingSpinner = nil
    }
    
}

// MARK: - Constants

private struct CreateGameView_Constants {
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let optimalDistance = 20.0
}
