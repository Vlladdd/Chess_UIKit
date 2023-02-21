//
//  BackButton.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 08.02.2023.
//

import UIKit

//class that represents back button
class BackButton: MMButtonView {
    
    // MARK: - Properties
    
    weak var delegate: MainMenuViewDelegate?
    
    //view to go back to
    private let backView: UIStackView
    
    // MARK: - Inits
    
    init(backView: UIStackView, delegate: MainMenuViewDelegate) {
        self.delegate = delegate
        self.backView = backView
        super.init(backgroundImageItem: nil, buttonImageItem: nil, buttontext: "Back", action: #selector(back), fontSize: delegate.font.pointSize, needHeightConstraint: true)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Button Methods
    
    @objc private func back(_ sender: UIButton? = nil) {
        delegate?.makeMenu(with: backView, reversed: true)
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        addBackButtonSFImage()
    }
    
}
