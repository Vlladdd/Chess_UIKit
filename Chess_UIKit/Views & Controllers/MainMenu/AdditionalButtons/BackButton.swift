//
//  BackButton.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 08.02.2023.
//

import UIKit

// MARK: - BackButtonDelegate

protocol BackButtonDelegate: AnyObject {
    func backButtonDidTriggerBackAction(_ backButton: BackButton) -> Void
}

// MARK: - BackButton

//class that represents back button
class BackButton: MMButtonView {
    
    // MARK: - Properties
    
    weak var delegate: BackButtonDelegate?
    
    // MARK: - Inits
    
    init(font: UIFont) {
        super.init(backgroundImageItem: nil, buttonImageItem: nil, buttontext: "Back", action: #selector(back), font: font, needHeightConstraint: true)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Button Methods
    
    @objc private func back(_ sender: UIButton? = nil) {
        delegate?.backButtonDidTriggerBackAction(self)
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        addBackButtonSFImage()
    }
    
}
