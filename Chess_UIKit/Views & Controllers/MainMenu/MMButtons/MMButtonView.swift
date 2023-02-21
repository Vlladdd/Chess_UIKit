//
//  MMButtonView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.02.2023.
//

import UIKit

//class that represents main menu button view
class MMButtonView: UIImageView {
    
    // MARK: - Properties
    
    private typealias constants = MMButtons_Constants
    
    private let font: UIFont
    
    private(set) var button: UIButton?
    
    // MARK: - Inits
    
    init(backgroundImageItem: ImageItem?, buttonImageItem: ImageItem?, buttontext: String, action: Selector?, fontSize: CGFloat, needHeightConstraint: Bool) {
        font = UIFont.systemFont(ofSize: fontSize)
        super.init(frame: .zero)
        setup(with: backgroundImageItem, buttonImageItem: buttonImageItem, buttontext: buttontext, and: action, needHeightConstraint: needHeightConstraint)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    //makes big round buttons to navigate through main menu
    private func setup(with backgroundImageItem: ImageItem?, buttonImageItem: ImageItem?, buttontext: String, and action: Selector?, needHeightConstraint: Bool) {
        defaultSettings()
        settingsForBackgroundOfTheButton(cornerRadius: font.pointSize * constants.multiplierForButtonSize / constants.optimalDividerForCornerRadius)
        if let backgroundImageItem {
            setImage(with: backgroundImageItem)
        }
        var buttonConstraints = [NSLayoutConstraint]()
        if let action {
            button = MainMenuButton(type: .system)
            if let button {
                button.buttonWith(imageItem: buttonImageItem, text: buttontext, font: font, and: action)
                if buttonImageItem != nil {
                    button.contentEdgeInsets = constants.insetsForCircleButton
                }
                addSubview(button)
                buttonConstraints += [button.widthAnchor.constraint(equalTo: widthAnchor), button.heightAnchor.constraint(equalTo: heightAnchor), button.centerXAnchor.constraint(equalTo: centerXAnchor), button.centerYAnchor.constraint(equalTo: centerYAnchor)]
            }
        }
        if needHeightConstraint {
            buttonConstraints += [heightAnchor.constraint(equalToConstant: MMButtonView.getOptimalHeight(with: font.pointSize))]
        }
        NSLayoutConstraint.activate(buttonConstraints)
    }
    
    //when we are using system image(SF Symbol) in imageView, it causes a bug with constraints for some reason(height of imageView is
    //less than it should be), so we have to add it like this
    func addBackButtonSFImage() {
        let backButtonView = UIImageView()
        backButtonView.translatesAutoresizingMaskIntoConstraints = false
        backButtonView.contentMode = contentMode
        backButtonView.setImage(with: SystemImages.backImage)
        addSubview(backButtonView)
        sendSubviewToBack(backButtonView)
        let backButtonViewConstraints = [backButtonView.topAnchor.constraint(equalTo: topAnchor), backButtonView.bottomAnchor.constraint(equalTo: bottomAnchor), backButtonView.leadingAnchor.constraint(equalTo: leadingAnchor), backButtonView.trailingAnchor.constraint(equalTo: trailingAnchor)]
        NSLayoutConstraint.activate(backButtonViewConstraints)
    }
    
    static func getOptimalHeight(with fontSize: CGFloat) -> CGFloat {
        fontSize * constants.multiplierForButtonSize
    }
    
}

// MARK: - Constants

private struct MMButtons_Constants {
    static let optimalDividerForCornerRadius = 4.0
    static let multiplierForButtonSize = 3.0
    static let insetsForCircleButton = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
}
