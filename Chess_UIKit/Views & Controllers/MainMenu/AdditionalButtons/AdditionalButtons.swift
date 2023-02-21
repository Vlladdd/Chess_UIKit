//
//  AdditionalButtons.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 04.02.2023.
//

import UIKit

//class that represents view with additional buttons
class AdditionalButtons: UIStackView {
    
    // MARK: - Properties
    
    private typealias constants = AdditionalButtons_Constants

    //sometimes additional buttons might not contain view about coins
    private(set) var coinsText: UILabel?
    
    // MARK: - Inits
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup() {
        setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
    }
    
    func updateCoinsText(with newValue: UILabel) {
        coinsText = newValue
    }
    
    func removeWithAnimation() {
        let width = superview?.bounds.width ?? bounds.width
        UIView.animate(withDuration: constants.animationDuration, animations: { [weak self] in
            guard let self else { return }
            self.transform = CGAffineTransform(translationX: -width, y: 0)
        }) { [weak self] _ in
            guard let self else { return }
            self.removeFromSuperview()
        }
    }
    
    func animateAppearance() {
        let width = superview?.bounds.width ?? bounds.width
        transform = CGAffineTransform(translationX: -width, y: 0)
        UIView.animate(withDuration: constants.animationDuration, animations: { [weak self] in
            guard let self else { return }
            self.transform = .identity
        })
    }
    
}

// MARK: - Constants

private struct AdditionalButtons_Constants {
    static let optimalSpacing = 5.0
    static let animationDuration = 0.5
}
