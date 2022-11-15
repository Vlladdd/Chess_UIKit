//
//  AuthorizationVC.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 08.09.2022.
//

import UIKit

//VC that represents authorization view
class AuthorizationVC: UIViewController, AuthorizationDelegate {
    
    // MARK: - AuthorizationDelegate
    
    let storage = Storage()
    
    func prepareForAuthorizationProcess() {
        authorizationView.isHidden.toggle()
        makeLoadingSpinner()
    }
    
    func errorCallbackForAuthorization(errorMessage: String) {
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alert, animated: true)
        loadingSpinner.removeFromSuperview()
        authorizationView.isHidden.toggle()
    }
    
    func successCallbackForAuthorization(user: User?) {
        if let user = user {
            let mainMenuVC = MainMenuVC()
            mainMenuVC.currentUser = user
            mainMenuVC.modalPresentationStyle = .fullScreen
            present(mainMenuVC, animated: false) {[weak self] in
                self?.loadingSpinner.removeFromSuperview()
                self?.authorizationView.isHidden.toggle()
            }
            return
        }
        else {
            errorCallbackForAuthorization(errorMessage: "Something went wrong")
        }
    }
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        configureKeyboardToHideWhenTappedAround()
        prepareForAuthorizationProcess()
        storage.checkIfUserIsLoggedIn(callback: { [weak self] isLoggedIn, error, user in
            if isLoggedIn {
                guard error == nil else {
                    self?.errorCallbackForAuthorization(errorMessage: error!.localizedDescription)
                    return
                }
                self?.successCallbackForAuthorization(user: user)
            }
            else {
                self?.loadingSpinner.removeFromSuperview()
                self?.authorizationView.isHidden.toggle()
            }
        })
    }
    
    // MARK: - Properties
    
    private typealias constants = AuthorizationVC_Constants
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private var authorizationView: AuthorizationView!
    private var loadingSpinner = LoadingSpinner()
    
    // MARK: - UI Methods
    
    private func makeUI() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        makeBackground()
        makeAuthorizationView()
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
    private func makeAuthorizationView() {
        let font = UIFont.systemFont(ofSize: min(view.frame.width, view.frame.height) / constants.dividerForFont)
        authorizationView = AuthorizationView(font: font)
        authorizationView.delegate = self
        view.addSubview(authorizationView)
        let dataFieldsStackConstraints = [authorizationView.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor), authorizationView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), authorizationView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor), authorizationView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)]
        NSLayoutConstraint.activate(dataFieldsStackConstraints)
    }
    
    //makes spinner, while waiting for response
    private func makeLoadingSpinner() {
        loadingSpinner = LoadingSpinner()
        view.addSubview(loadingSpinner)
        let spinnerConstraints = [loadingSpinner.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), loadingSpinner.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor), loadingSpinner.widthAnchor.constraint(equalTo: authorizationView.widthAnchor), loadingSpinner.heightAnchor.constraint(equalTo: authorizationView.heightAnchor)]
        NSLayoutConstraint.activate(spinnerConstraints)
    }
    
}

// MARK: - Constants

private struct AuthorizationVC_Constants {
    static let dividerForFont: CGFloat = 13
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
}
