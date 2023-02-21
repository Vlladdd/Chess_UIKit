//
//  FrameView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 04.02.2023.
//

import UIKit

//class that represents view of frame theme
class FrameView: PlayerFrame {
    
    // MARK: - Properties
    
    private let storage = Storage.sharedInstance
    
    // MARK: - Inits
    
    init(frame: Frames, font: UIFont) {
        let frameLabel = UILabel()
        frameLabel.setup(text: frame.getHumanReadableName(), alignment: .center, font: font)
        super.init(background: storage.currentUser.playerBackground, playerFrame: frame, data: frameLabel)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
