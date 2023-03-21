//
//  FrameView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 04.02.2023.
//

import UIKit

//class that represents view of frame theme
class FrameView: PlayerFrame {
    
    // MARK: - Inits
    
    init(frame: Frames, font: UIFont, background: Backgrounds) {
        let frameLabel = UILabel()
        frameLabel.setup(text: frame.getHumanReadableName(), alignment: .center, font: font)
        super.init(background: background, playerFrame: frame, data: frameLabel)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
