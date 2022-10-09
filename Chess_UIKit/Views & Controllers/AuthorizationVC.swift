//
//  AuthorizationVC.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 08.09.2022.
//

import UIKit

//VC that represents authorization view
class AuthorizationVC: UIViewController {
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
    }
    
    // MARK: - Properties
    
    private let storage = Storage()
    
    private typealias constants = AuthorizationVC_Constants
    
    // MARK: - Buttons Methods
    
    @objc private func createNewUser(_ sender: UIButton? = nil) {
        dataFieldsStack.isHidden.toggle()
        makeLoadingSpinner()
        storage.createUser(with: emailField.text!, and: passwordField.text!) { [weak self] error, user in
            if let self = self {
                self.callbackForCreateAndLogin(error: error, user: user)
            }
        }
    }
    
    @objc private func login(_ sender: UIButton? = nil) {
        dataFieldsStack.isHidden.toggle()
        makeLoadingSpinner()
        storage.signInUser(with: emailField.text!, and: passwordField.text!) { [weak self] error, user in
            if let self = self {
                self.callbackForCreateAndLogin(error: error, user: user)
            }
        }
    }
    
    // MARK: - Local Methods
    
    private func callbackForCreateAndLogin(error: Error?, user: User?) {
        guard error == nil else {
            createOrLoginFail(with: error?.localizedDescription)
            return
        }
        if let user = user {
            let mainMenuVC = MainMenuVC()
            mainMenuVC.currentUser = user
            mainMenuVC.modalPresentationStyle = .fullScreen
            present(mainMenuVC, animated: false)
            return
        }
        else {
            createOrLoginFail(with: "Something went wrong")
        }
    }
    
    private func createOrLoginFail(with message: String?) {
        let alert = UIAlertController(title: "Error", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        alert.message = message
        present(alert, animated: true)
        loadingSpinner.removeFromSuperview()
        dataFieldsStack.isHidden.toggle()
    }
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private let dataFieldsStack = UIStackView()
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private var loadingSpinner = UIImageView()
    
    // MARK: - UI Methods
    
    private func makeUI() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        makeBackground()
        makeDataFields()
    }
    
    //makes background of the view
    private func makeBackground() {
        let background = UIImageView()
        background.translatesAutoresizingMaskIntoConstraints = false
        background.image = UIImage(named: "misc/defaultBG")
        background.contentMode = .scaleAspectFill
        background.layer.masksToBounds = true
        view.addSubview(background)
        let backgroundConstraints = [background.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor), background.leadingAnchor.constraint(equalTo: view.leadingAnchor), background.trailingAnchor.constraint(equalTo: view.trailingAnchor), background.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        NSLayoutConstraint.activate(backgroundConstraints)
    }
    
    //makes form to let user enter data
    private func makeDataFields() {
        let font = UIFont.systemFont(ofSize: min(view.frame.width, view.frame.height) / constants.dividerForFont)
        dataFieldsStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        dataFieldsStack.defaultSettings()
        dataFieldsStack.layoutMargins = UIEdgeInsets(top: constants.optimalDistanceFromEdgesInStack, left: constants.optimalDistanceFromEdgesInStack, bottom: constants.optimalDistanceFromEdgesInStack, right: constants.optimalDistanceFromEdgesInStack)
        dataFieldsStack.isLayoutMarginsRelativeArrangement = true
        dataFieldsStack.backgroundColor = dataFieldsStack.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        let nicknameLabel = UILabel()
        nicknameLabel.setup(text: "Email", alignment: .center, font: font)
        let passwordLabel = UILabel()
        passwordLabel.setup(text: "Password", alignment: .center, font: font)
        let createButton = UIButton(type: .system)
        createButton.buttonWith(text: "Create", font: font, and: #selector(createNewUser))
        let loginButton = UIButton(type: .system)
        loginButton.buttonWith(text: "Login", font: font, and: #selector(login))
        emailField.setup(placeholder: "Enter email", font: font)
        passwordField.setup(placeholder: "Enter password", font: font)
        dataFieldsStack.addArrangedSubview(makeDataLine(with: [nicknameLabel, emailField]))
        dataFieldsStack.addArrangedSubview(makeDataLine(with: [passwordLabel, passwordField]))
        dataFieldsStack.addArrangedSubview(makeDataLine(with: [createButton, loginButton]))
        view.addSubview(dataFieldsStack)
        let dataConstraints = [dataFieldsStack.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor), dataFieldsStack.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), dataFieldsStack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor), dataFieldsStack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)]
        NSLayoutConstraint.activate(dataConstraints)
    }
    
    private func makeDataLine(with views: [UIView]) -> UIStackView {
        let data = UIStackView()
        data.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        data.addArrangedSubviews(views)
        return data
    }
    
    //makes spinner, while waiting for response
    private func makeLoadingSpinner() {
        loadingSpinner = UIImageView()
        loadingSpinner.defaultSettings()
        loadingSpinner.backgroundColor = loadingSpinner.backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        let figureName = traitCollection.userInterfaceStyle == .dark ? "white_king" : "black_king"
        let spinner = UIImageView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.contentMode = .scaleAspectFit
        spinner.image = UIImage(named: "figuresThemes/defaultTheme/\(figureName)")
        spinner.rotate360Degrees(duration: constants.speedForSpinner)
        loadingSpinner.addSubview(spinner)
        view.addSubview(loadingSpinner)
        let spinnerConstraints = [loadingSpinner.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), loadingSpinner.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor), loadingSpinner.widthAnchor.constraint(equalTo: dataFieldsStack.widthAnchor), loadingSpinner.heightAnchor.constraint(equalTo: dataFieldsStack.heightAnchor), spinner.widthAnchor.constraint(equalTo: loadingSpinner.widthAnchor, multiplier: constants.sizeMultiplierForSpinner), spinner.heightAnchor.constraint(equalTo: loadingSpinner.heightAnchor, multiplier: constants.sizeMultiplierForSpinner), spinner.centerXAnchor.constraint(equalTo: loadingSpinner.centerXAnchor), spinner.centerYAnchor.constraint(equalTo: loadingSpinner.centerYAnchor)]
        NSLayoutConstraint.activate(spinnerConstraints)
    }
    
}

// MARK: - Constants

private struct AuthorizationVC_Constants {
    static let optimalSpacing = 5.0
    static let dividerForFont: CGFloat = 13
    static let optimalDistanceFromEdgesInStack = 10.0
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let speedForSpinner = 1.0
    static let sizeMultiplierForSpinner = 0.6
}
