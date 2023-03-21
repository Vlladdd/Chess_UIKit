//
//  AuthorizationView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 14.11.2022.
//

import UIKit

// MARK: - AuthorizationViewDelegate

protocol AuthorizationViewDelegate: AnyObject {
    func authorizationViewDidTriggerSignUp(_ authorizationView: AuthorizationView) -> Void
    func authorizationViewDidTriggerSignIn(_ authorizationView: AuthorizationView) -> Void
    func authorizationViewDidTriggerSignInAsGuest(_ authorizationView: AuthorizationView) -> Void
}

// MARK: - AuthorizationView

//class that represents authorization view
class AuthorizationView: UIStackView {
    
    // MARK: - Properties
    
    weak var delegate: AuthorizationViewDelegate?

    private let font: UIFont
    
    let emailField = UITextField()
    let passwordField = UITextField()
    let goggleSignInButton = GoogleSignInButton()
    
    private typealias constants = LoginView_Constants
    
    // MARK: - Inits
    
    init(font: UIFont) {
        self.font = font
        super.init(frame: .zero)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func signUp(_ sender: UIButton? = nil) {
        delegate?.authorizationViewDidTriggerSignUp(self)
    }
    
    @objc private func signIn(_ sender: UIButton? = nil) {
        delegate?.authorizationViewDidTriggerSignIn(self)
    }
    
    @objc private func signInViaGuestMode(_ sender: UIButton? = nil) {
        delegate?.authorizationViewDidTriggerSignInAsGuest(self)
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        defaultSettings()
        layoutMargins = UIEdgeInsets(top: constants.optimalDistanceFromEdgesInStack, left: constants.optimalDistanceFromEdgesInStack, bottom: constants.optimalDistanceFromEdgesInStack, right: constants.optimalDistanceFromEdgesInStack)
        isLayoutMarginsRelativeArrangement = true
        backgroundColor = backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        let guestModeButton = UIButton()
        guestModeButton.buttonWith(imageItem: SystemImages.noInternetImage, and: #selector(signInViaGuestMode))
        let goggleSignInView = UIView()
        goggleSignInView.translatesAutoresizingMaskIntoConstraints = false
        goggleSignInView.addSubview(goggleSignInButton)
        let emailLabel = UILabel()
        emailLabel.setup(text: "Email", alignment: .center, font: font)
        let passwordLabel = UILabel()
        passwordLabel.setup(text: "Password", alignment: .center, font: font)
        let createButton = UIButton(type: .system)
        createButton.buttonWith(text: "Create", font: font, and: #selector(signUp))
        let loginButton = UIButton(type: .system)
        loginButton.buttonWith(text: "Login", font: font, and: #selector(signIn))
        emailField.setup(placeholder: "Enter email", font: font)
        passwordField.setup(placeholder: "Enter password", font: font)
        addArrangedSubview(makeDataLine(with: [emailLabel, emailField]))
        addArrangedSubview(makeDataLine(with: [passwordLabel, passwordField]))
        addArrangedSubview(makeDataLine(with: [createButton, loginButton, guestModeButton]))
        addArrangedSubview(makeDataLine(with: [goggleSignInView]))
        let goggleSignInButtonConstraints = [goggleSignInButton.centerXAnchor.constraint(equalTo: goggleSignInView.centerXAnchor), goggleSignInButton.centerYAnchor.constraint(equalTo: goggleSignInView.centerYAnchor)]
        NSLayoutConstraint.activate(goggleSignInButtonConstraints)
    }
    
    private func makeDataLine(with views: [UIView]) -> UIStackView {
        let data = UIStackView()
        data.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        data.addArrangedSubviews(views)
        return data
    }
    
}

// MARK: - Constants

private struct LoginView_Constants {
    static let optimalSpacing = 5.0
    static let optimalDistanceFromEdgesInStack = 10.0
    static let optimalAlpha = 0.5
}
