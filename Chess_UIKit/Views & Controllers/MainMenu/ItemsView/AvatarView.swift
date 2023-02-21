//
//  AvatarView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 04.02.2023.
//

import UIKit

//class that represents view of avatar
class AvatarView: UIStackView, ItemView {
    
    // MARK: - ItemView
    
    let item: GameItem
    
    // MARK: - Properties
    
    private typealias constants = AvatarView_Constants
    
    // MARK: - Inits
    
    init(avatar: Avatars, font: UIFont) {
        item = avatar
        super.init(frame: .zero)
        setup(font: font)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup(font: UIFont) {
        let avatar = item as! Avatars
        setup(axis: .horizontal, alignment: .fill, distribution: .fill, spacing: constants.optimalSpacing)
        let avatarImage = UIImageView()
        avatarImage.makeSquareView(with: avatar)
        let avatarName = UILabel()
        avatarName.setup(text: avatar.getHumanReadableName(), alignment: .center, font: font)
        addArrangedSubviews([avatarImage, avatarName])
    }
    
}

// MARK: - Constants

private struct AvatarView_Constants {
    static let optimalSpacing = 5.0
}
