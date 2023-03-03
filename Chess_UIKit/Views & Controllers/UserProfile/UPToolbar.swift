//
//  UPToolbar.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

//class that represents toolbar of user profile
class UPToolbar: UIToolbar {
    
    // MARK: - Properties
    
    weak var userProfileViewDelegate: UserProfileViewDelegate?
    
    private typealias constants = UPToolbar_Constants
    
    private(set) var updateButton = UIBarButtonItem()
    
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
        userProfileViewDelegate?.userProfileDelegate?.dismiss(animated: true)
    }
    
    @objc private func updateUserInfo(_ sender: UIBarButtonItem? = nil) {
        userProfileViewDelegate?.updateUserInfo()
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        let backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        let background = backgroundColor.image()
        translatesAutoresizingMaskIntoConstraints = false
        setBackgroundImage(background, forToolbarPosition: .any, barMetrics: .default)
        setShadowImage(background, forToolbarPosition: .any)
        barStyle = .default
        isTranslucent = true
        sizeToFit()
        let closeButton = UIBarButtonItem(title: "Close", style: UIBarButtonItem.Style.plain, target: self, action: #selector(close))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        updateButton = UIBarButtonItem(title: "Update", style: UIBarButtonItem.Style.done, target: self, action: #selector(updateUserInfo))
        setItems([closeButton, spaceButton, updateButton], animated: false)
        isUserInteractionEnabled = true
    }
    
}

// MARK: - Constants

private struct UPToolbar_Constants {
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
}
