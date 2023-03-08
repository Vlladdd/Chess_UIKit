//
//  CGToolbar.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 06.03.2023.
//

import UIKit

//class that represents toolbar of CreateGameView
class CGToolbar: UIToolbar {
    
    // MARK: - Properties
    
    weak var createGameDelegate: CreateGameDelegate?
    
    private typealias constants = CGToolbar_Constants
    
    private(set) var createGameButton: UIBarButtonItem!
    
    // MARK: - Inits
    
    init() {
        //size is random, without it, it will make unsatisfied constraints errors
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 44.0)))
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func close(_ sender: UIBarButtonItem? = nil) {
        createGameDelegate?.dismiss(animated: true)
    }
    
    @objc private func createGame(_ sender: UIBarButtonItem? = nil) {
        createGameDelegate?.createGame()
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        let toolbarBackgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        let toolbarBackground = toolbarBackgroundColor.image()
        translatesAutoresizingMaskIntoConstraints = false
        setBackgroundImage(toolbarBackground, forToolbarPosition: .any, barMetrics: .default)
        setShadowImage(toolbarBackground, forToolbarPosition: .any)
        barStyle = .default
        isTranslucent = true
        sizeToFit()
        let closeButton = UIBarButtonItem(title: "Close", style: UIBarButtonItem.Style.plain, target: self, action: #selector(close))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        createGameButton = UIBarButtonItem(title: "Create", style: UIBarButtonItem.Style.done, target: self, action: #selector(createGame))
        setItems([closeButton, spaceButton, createGameButton], animated: false)
        isUserInteractionEnabled = true
    }
    
}

// MARK: - Constants

private struct CGToolbar_Constants {
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
}
