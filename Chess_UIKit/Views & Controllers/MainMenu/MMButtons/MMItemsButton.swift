//
//  MMItemsButton.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 07.02.2023.
//

import UIKit

//class that represents inventory or shop button in main menu
class MMItemsButton: MMButtonView {
    
    // MARK: - Properties
    
    let items: [GameItem]
    
    // MARK: - Inits
    
    init(items: [GameItem], backgroundImageItem: ImageItem?, buttontext: String, action: Selector?, fontSize: CGFloat) {
        self.items = items
        super.init(backgroundImageItem: backgroundImageItem, buttonImageItem: nil, buttontext: buttontext, action: action, fontSize: fontSize, needHeightConstraint: false)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
