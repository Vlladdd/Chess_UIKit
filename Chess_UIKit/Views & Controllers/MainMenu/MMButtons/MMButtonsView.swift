//
//  MMButtonsView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 10.02.2023.
//

import UIKit

//class that represents buttons in main menu
class MMButtonsView: UIScrollView {
    
    //allows to scroll buttons, which have isExclusiveTouch set to true and/or if user holds them
    override func touchesShouldCancel(in view: UIView) -> Bool {
        true
    }
    
    // MARK: - Properties
    
    //available buttons in current menu
    let buttonsStack: UIStackView
    
    private typealias constants = MMButtonsView_Constants
    
    // MARK: - Inits
    
    init(buttonsStack: UIStackView) {
        self.buttonsStack = buttonsStack
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        delaysContentTouches = false
        addSubview(buttonsStack)
        let contentHeight = buttonsStack.heightAnchor.constraint(equalTo: heightAnchor)
        contentHeight.priority = .defaultLow
        let buttonsStackConstraints = [buttonsStack.topAnchor.constraint(equalTo: topAnchor), buttonsStack.bottomAnchor.constraint(equalTo: bottomAnchor), buttonsStack.leadingAnchor.constraint(equalTo: leadingAnchor), buttonsStack.trailingAnchor.constraint(equalTo: trailingAnchor), buttonsStack.widthAnchor.constraint(equalTo: widthAnchor), contentHeight]
        NSLayoutConstraint.activate(buttonsStackConstraints)
        scrollToTop(animated: false)
    }
    
    func removeWithAnimation(reversed: Bool) {
        let yForAnimation = reversed ? -contentSize.height : contentSize.height
        UIView.animate(withDuration: constants.animationDuration, animations: { [weak self] in
            guard let self else { return }
            self.buttonsStack.transform = CGAffineTransform(translationX: 0, y: yForAnimation)
        }) { [weak self] _ in
            guard let self else { return }
            self.removeFromSuperview()
        }
    }
    
    func animateAppearance(reversed: Bool, extraY: CGFloat) {
        let yForAnimation = contentSize.height + extraY
        buttonsStack.transform = CGAffineTransform(translationX: 0, y: reversed ? yForAnimation : -yForAnimation)
        UIView.animate(withDuration: constants.animationDuration, animations: { [weak self] in
            guard let self else { return }
            self.buttonsStack.transform = .identity
        })
    }
    
}

// MARK: - Constants

private struct MMButtonsView_Constants {
    static let animationDuration = 0.5
}
