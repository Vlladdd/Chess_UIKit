//
//  CustomAlert.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 17.03.2023.
//

import UIKit

// MARK: - CustomAlertDelegate

protocol CustomAlertDelegate: AnyObject {
    func customAlertWillRemoveFromSuperview(_ customAlert: CustomAlert) -> Void
    func customAlertDidRemoveFromSuperview(_ customAlert: CustomAlert) -> Void
}

// MARK: - CustomAlert

//class that represents logic of the game
class CustomAlert: UIImageView {
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        delegate?.customAlertDidRemoveFromSuperview(self)
    }
    
    // MARK: - Properties
    
    //just to simplify init
    struct Data {
        
        let type: CustomAlertType
        let title: String
        let message: String
        let closeButtonText: String
        
    }
    
    weak var delegate: CustomAlertDelegate?
    
    private typealias constants = CustomAlert_Constants
    
    private let font: UIFont
    private let buttonsStack = UIStackView()
    
    private(set) var loadingSpinner: LoadingSpinner?
    
    // MARK: - Inits
    
    init(font: UIFont, data: CustomAlert.Data, needLoadingSpinner: Bool) {
        self.font = font
        super.init(frame: .zero)
        setup(with: data, needLoadingSpinner: needLoadingSpinner)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func close(_ sender: UIButton? = nil) {
        removeWithAnimation()
    }
    
    // MARK: - Local Methods
    
    private func setup(with data: CustomAlert.Data, needLoadingSpinner: Bool) {
        defaultSettings()
        isUserInteractionEnabled = true
        setupButtonsStack()
        let titleView = makeTitleView(with: data.title, alertType: data.type)
        let messageView = makeMessageView(with: data.message)
        addSubviews([buttonsStack, titleView, messageView])
        if needLoadingSpinner {
            makeLoadingSpinner()
        }
        let titleViewConstraints = [titleView.leadingAnchor.constraint(equalTo: leadingAnchor), titleView.trailingAnchor.constraint(equalTo: trailingAnchor), titleView.topAnchor.constraint(equalTo: topAnchor)]
        let messageViewConstraints = [messageView.leadingAnchor.constraint(equalTo: leadingAnchor), messageView.trailingAnchor.constraint(equalTo: trailingAnchor), messageView.topAnchor.constraint(equalTo: titleView.bottomAnchor)]
        let buttonsStackConstraints = [buttonsStack.leadingAnchor.constraint(equalTo: leadingAnchor), buttonsStack.trailingAnchor.constraint(equalTo: trailingAnchor), buttonsStack.bottomAnchor.constraint(equalTo: bottomAnchor), buttonsStack.topAnchor.constraint(equalTo: messageView.bottomAnchor)]
        NSLayoutConstraint.activate(titleViewConstraints + messageViewConstraints + buttonsStackConstraints)
        let closeButton = UIButton(type: .system)
        closeButton.buttonWith(text: data.closeButtonText, font: font, and: #selector(close))
        addButton(closeButton)
    }
    
    private func setupButtonsStack() {
        buttonsStack.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        buttonsStack.defaultSettings()
        buttonsStack.backgroundColor = constants.buttonsStackBGColor
        buttonsStack.layer.cornerRadius = 0
    }
    
    private func makeTitleView(with title: String, alertType: CustomAlertType) -> UILabel {
        let titleView = UILabel()
        titleView.setup(text: title, alignment: .center, font: font)
        titleView.labelWithBorderAndCornerRadius()
        titleView.layer.cornerRadius = 0
        switch alertType {
        case .error:
            titleView.backgroundColor = constants.errorColor
        case .success:
            titleView.backgroundColor = constants.successColor
        }
        return titleView
    }
    
    private func makeMessageView(with message: String) -> UIView {
        let messageView = UIView()
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageView.backgroundColor = constants.messageBGColor
        let messageLabel = UILabel()
        messageLabel.setup(text: message, alignment: .center, font: font.withSize(font.pointSize * constants.multiplierForMessageFontSize))
        messageLabel.numberOfLines = 0
        messageView.addSubview(messageLabel)
        let messageLabelConstraints = [messageLabel.leadingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: constants.optimalDistance), messageLabel.trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: -constants.optimalDistance), messageLabel.topAnchor.constraint(equalTo: messageView.topAnchor, constant: constants.optimalDistance), messageLabel.bottomAnchor.constraint(equalTo: messageView.bottomAnchor, constant: -constants.optimalDistance)]
        NSLayoutConstraint.activate(messageLabelConstraints)
        return messageView
    }
    
    private func makeLoadingSpinner() {
        loadingSpinner = LoadingSpinner()
        if let loadingSpinner {
            let backgroundView = UIView()
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            loadingSpinner.addSubview(backgroundView)
            backgroundView.backgroundColor = loadingSpinner.backgroundColor
            addSubview(loadingSpinner)
            sendSubviewToBack(loadingSpinner)
            let backgroundViewConstraints = [backgroundView.leadingAnchor.constraint(equalTo: loadingSpinner.leadingAnchor), backgroundView.trailingAnchor.constraint(equalTo: loadingSpinner.trailingAnchor), backgroundView.topAnchor.constraint(equalTo: loadingSpinner.topAnchor), backgroundView.bottomAnchor.constraint(equalTo: loadingSpinner.bottomAnchor)]
            let loadingSpinnerConstraints = [loadingSpinner.leadingAnchor.constraint(equalTo: leadingAnchor), loadingSpinner.trailingAnchor.constraint(equalTo: trailingAnchor), loadingSpinner.topAnchor.constraint(equalTo: topAnchor), loadingSpinner.bottomAnchor.constraint(equalTo: bottomAnchor)]
            NSLayoutConstraint.activate(loadingSpinnerConstraints + backgroundViewConstraints)
        }
    }
    
    func addButton(_ button: UIButton) {
        buttonsStack.addArrangedSubview(button)
    }
    
    func removeWithAnimation() {
        UIView.animate(withDuration: constants.animationDuration, animations: { [weak self] in
            guard let self else { return }
            self.alpha = 0
        }) { [weak self] _ in
            guard let self else { return }
            self.removeFromSuperview()
        }
        delegate?.customAlertWillRemoveFromSuperview(self)
    }
    
}

// MARK: - Constants

private struct CustomAlert_Constants {
    static let optimalSpacing = 0.5
    static let optimalDistance = 5.0
    static let animationDuration = 0.5
    static let optimalAlpha = 0.5
    static let multiplierForMessageFontSize = 0.75
    static let buttonsStackBGColor = UIColor.yellow.withAlphaComponent(optimalAlpha)
    static let messageBGColor = UIColor.orange.withAlphaComponent(optimalAlpha)
    static let errorColor = UIColor.red.withAlphaComponent(optimalAlpha)
    static let successColor = UIColor.green.withAlphaComponent(optimalAlpha)
}
