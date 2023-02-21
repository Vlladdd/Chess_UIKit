//
//  TitleView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 04.02.2023.
//

import UIKit

//class that represents view of title
class TitleView: UILabel, ItemView {
    
    // MARK: - ItemView
    
    let item: GameItem

    // MARK: - Inits
    
    init(title: Titles, font: UIFont) {
        item = title
        super.init(frame: .zero)
        setup(text: title.getHumanReadableName().capitalizingFirstLetter(), alignment: .center, font: font)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
