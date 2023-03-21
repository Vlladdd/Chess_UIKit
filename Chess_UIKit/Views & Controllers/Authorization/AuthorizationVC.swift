//
//  AuthorizationVC.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 08.09.2022.
//

import UIKit
import Firebase
import GoogleSignIn

//VC that represents authorization view
class AuthorizationVC: UIViewController {
    
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
                    removeLoadingSpinner()
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
    private let storage = Storage.sharedInstance
    
    // MARK: - Methods
    
    private func loginOperation(with resolver: MultiFactorResolver?, displayNameString: String?) {
        if let resolver, let displayNameString {
            showTextInputPrompt(withMessage: "Select factor to sign in\n\(displayNameString)", completionBlock: {
                [weak self] userPressedOK, displayName in
                guard let self else { return }
                if let displayName {
                    Task {
                        do {
                            let result = try await self.storage.multifactorAuth(with: resolver, and: displayName)
                            self.multiFactorOperation(verificationID: result.verificationID, selectedHint: result.selectedHint, resolver: resolver)
                        }
                        catch {
                            self.authorizationErrorWith(errorMessage: "Multi factor start sign in failed. Error: \(error.localizedDescription.debugDescription)")
                        }
                    }
                }
                else {
                    self.authorizationErrorWith(errorMessage: "DisplayName is nil")
                }
            })
            return
        }
        else {
            successAuthorization()
        }
    }
    
    private func multiFactorOperation(verificationID: String?, selectedHint: PhoneMultiFactorInfo?, resolver: MultiFactorResolver) {
        if let verificationID {
            showTextInputPrompt(withMessage: "Verification code for \(selectedHint?.displayName ?? "")", completionBlock: {
                [weak self] userPressedOK, verificationCode in
                guard let self else { return }
                if let verificationCode {
                    Task {
                        do {
                            try await self.storage.checkVerificationCode(with: resolver, verificationID: verificationID, verificationCode: verificationCode)
                            self.navigationController?.popViewController(animated: true)
                            self.successAuthorization()
                        }
                        catch {
                            self.authorizationErrorWith(errorMessage: "Multi factor finalize sign in failed. Error: \(error.localizedDescription.debugDescription)")
                        }
                    }
                }
                else {
                    self.authorizationErrorWith(errorMessage: "VerificationCode is nil")
                }
            })
        }
        else {
            authorizationErrorWith(errorMessage: "VerificationID is nil")
        }
    }
    
    private func prepareForAuthorizationProcess() {
        authorizationView.isHidden.toggle()
        makeLoadingSpinner()
    }
    
    private func authorizationErrorWith(errorMessage: String) {
        print(errorMessage)
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alert, animated: true)
        removeLoadingSpinner()
        authorizationView.isHidden.toggle()
        audioPlayer.playSound(Sounds.errorSound)
    }
    
    private func successAuthorization() {
        let mainMenuVC = MainMenuVC()
        mainMenuVC.modalPresentationStyle = .fullScreen
        present(mainMenuVC, animated: false) { [weak self] in
            guard let self else { return }
            self.removeLoadingSpinner()
            self.authorizationView.isHidden = false
            self.authorizationView.emailField.text?.removeAll()
            self.authorizationView.passwordField.text?.removeAll()
        }
    }
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private var authorizationView: AuthorizationView!
    private var loadingSpinner: LoadingSpinner?
    
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
        authorizationView.goggleSignInButton.delegate = self
        view.addSubview(authorizationView)
        let dataFieldsStackConstraints = [authorizationView.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor), authorizationView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), authorizationView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor), authorizationView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)]
        NSLayoutConstraint.activate(dataFieldsStackConstraints)
    }
    
    //makes spinner, while waiting for response
    private func makeLoadingSpinner() {
        loadingSpinner = LoadingSpinner()
        if let loadingSpinner {
            loadingSpinner.delegate = self
            audioPlayer.playSound(Music.waitingMusic, volume: constants.volumeForWaitingMusic)
            view.addSubview(loadingSpinner)
            let spinnerConstraints = [loadingSpinner.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor), loadingSpinner.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor), loadingSpinner.widthAnchor.constraint(equalTo: authorizationView.widthAnchor), loadingSpinner.heightAnchor.constraint(equalTo: authorizationView.heightAnchor)]
            NSLayoutConstraint.activate(spinnerConstraints)
        }
    }
    
    private func removeLoadingSpinner() {
        loadingSpinner?.removeFromSuperview()
        loadingSpinner = nil
    }
    
}

// MARK: - Constants

private struct AuthorizationVC_Constants {
    static let volumeForWaitingMusic: Float = 0.3
    static let dividerForFont: CGFloat = 13
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
}

// MARK: - AuthorizationViewDelegate

extension AuthorizationVC: AuthorizationViewDelegate {
    
    func authorizationViewDidTriggerSignUp(_ authorizationView: AuthorizationView) {
        prepareForAuthorizationProcess()
        Task {
            do {
                try await storage.createUser(with: authorizationView.emailField.text!, and: authorizationView.passwordField.text!)
                successAuthorization()
            }
            catch {
                authorizationErrorWith(errorMessage: error.localizedDescription)
            }
        }
    }
    
    func authorizationViewDidTriggerSignIn(_ authorizationView: AuthorizationView) {
        prepareForAuthorizationProcess()
        Task {
            do {
                let result = try await storage.signInWith(email: authorizationView.emailField.text!, and: authorizationView.passwordField.text!)
                loginOperation(with: result.resolver, displayNameString: result.displayNameString)
            }
            catch {
                authorizationErrorWith(errorMessage: error.localizedDescription)
            }
        }
    }
    
    func authorizationViewDidTriggerSignInAsGuest(_ authorizationView: AuthorizationView) {
        storage.signInAsGuest()
        successAuthorization()
    }
    
}

// MARK: - GoogleSignInButtonDelegate

extension AuthorizationVC: GoogleSignInButtonDelegate {
    
    func googleSignInButtonDidTriggerSignIn(_ googleSignInButton: GoogleSignInButton) {
        guard let clientID = storage.clientID else { return }
        //Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        //Start the sign in flow!
        prepareForAuthorizationProcess()
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [weak self] user, error in
            guard let self else { return }
            guard error == nil else {
                self.authorizationErrorWith(errorMessage: error!.localizedDescription)
                return
            }
            guard let authentication = user?.authentication, let idToken = authentication.idToken else {
                self.authorizationErrorWith(errorMessage: "Can`t find idToken")
                return
            }
            Task {
                do {
                    let result = try await self.storage.signInWith(idToken: idToken, and: authentication.accessToken)
                    self.loginOperation(with: result.resolver, displayNameString: result.displayNameString)
                }
                catch {
                    self.authorizationErrorWith(errorMessage: error.localizedDescription)
                }
            }
        }
    }
    
}

// MARK: - LoadingSpinnerDelegate

extension AuthorizationVC: LoadingSpinnerDelegate {
    
    func loadingSpinnerDidRemoveFromSuperview(_ loadingSpinner: LoadingSpinner) {
        audioPlayer.pauseSound(Music.waitingMusic)
    }
    
}
