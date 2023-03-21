//
//  AvatarInfoView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

//class that represents view with info about avatar
class AvatarInfoView: UIScrollView {
    
    // MARK: - Properties
    
    private typealias constants = AvatarInfoView_Constants
    
    let avatarInfo = UILabel()
    
    // MARK: - Inits
    
    init(font: UIFont, avatarDescription: String) {
        super.init(frame: .zero)
        setup(with: font, and: avatarDescription)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup(with font: UIFont, and avatarDescription: String) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        avatarInfo.setup(text: avatarDescription, alignment: .center, font: font)
        avatarInfo.numberOfLines = 0
        addSubview(avatarInfo)
        let heightConstraintForAvatarInfo = avatarInfo.heightAnchor.constraint(equalTo: heightAnchor)
        heightConstraintForAvatarInfo.priority = .defaultLow
        let centerYConstraintForAvatarInfo = avatarInfo.centerYAnchor.constraint(equalTo: centerYAnchor)
        centerYConstraintForAvatarInfo.priority = .defaultLow
        let avatarInfoConstraints = [avatarInfo.topAnchor.constraint(equalTo: topAnchor), avatarInfo.leadingAnchor.constraint(equalTo: leadingAnchor), avatarInfo.trailingAnchor.constraint(equalTo: trailingAnchor), avatarInfo.bottomAnchor.constraint(equalTo: bottomAnchor), avatarInfo.widthAnchor.constraint(equalTo: widthAnchor), heightConstraintForAvatarInfo, centerYConstraintForAvatarInfo]
        NSLayoutConstraint.activate(avatarInfoConstraints)
    }
    
}

// MARK: - Constants

private struct AvatarInfoView_Constants {
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
}
