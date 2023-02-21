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
    
    func prepareForAuthorizationProcess() {
        authorizationView.isHidden.toggle()
        makeLoadingSpinner()
    }
    
    func authorizationErrorWith(errorMessage: String) {
        print(errorMessage)
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alert, animated: true)
        loadingSpinner.removeFromSuperview()
        authorizationView.isHidden.toggle()
        audioPlayer.playSound(Sounds.errorSound)
    }
    
    func successAuthorization() {
        let mainMenuVC = MainMenuVC()
        mainMenuVC.modalPresentationStyle = .fullScreen
        present(mainMenuVC, animated: false) { [weak self] in
            guard let self else { return }
            self.loadingSpinner.removeFromSuperview()
            self.authorizationView.isHidden = false
        }
    }
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        configureKeyboardToHideWhenTappedAround()
        prepareForAuthorizationProcess()
        Task {
            do {
                let userIsLoggedIn = try await storage.checkIfUserIsLoggedIn()
                if userIsLoggedIn {
                    successAuthorization()
                }
                else {
                    loadingSpinner.removeFromSuperview()
                    authorizationView.isHidden.toggle()
                }
            }
            catch {
                authorizationErrorWith(errorMessage: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Properties
    
    private typealias constants = AuthorizationVC_Constants
    
    private let audioPlayer = AudioPlayer.sharedInstance
    
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
        background.setImage(with: MiscImages.defaultBG)
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
        loadingSpinner.waiting()
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
