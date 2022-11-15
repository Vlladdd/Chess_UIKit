//
//  GoogleSignInButton.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 13.11.2022.
//

import UIKit
import GoogleSignIn

//class that represents custom Google Sign In button
class GoogleSignInButton: GIDSignInButton {
    
    // MARK: - Properties
    
    weak var delegate: AuthorizationDelegate?
    
    // MARK: - Inits
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    @objc private func signIn(_ sender: GoogleSignInButton? = nil) {
        if let delegate = delegate {
            guard let clientID = delegate.storage.clientID else { return }
            // Create Google Sign In configuration object.
            let config = GIDConfiguration(clientID: clientID)
            // Start the sign in flow!
            delegate.prepareForAuthorizationProcess()
            GIDSignIn.sharedInstance.signIn(with: config, presenting: delegate) { user, error in
                guard error == nil else {
                    delegate.errorCallbackForAuthorization(errorMessage: error!.localizedDescription)
                    return
                }
                guard let authentication = user?.authentication, let idToken = authentication.idToken else {
                    delegate.errorCallbackForAuthorization(errorMessage: "Can`t find idToken")
                    return
                }
                delegate.storage.signInWith(idToken: idToken, and: authentication.accessToken, callback: { error, user, resolver, displayNameString in
                    delegate.loginOperation(currentUser: user, error: error, resolver: resolver, displayNameString: displayNameString)
                })
            }
        }
        else {
            fatalError("delegate is nil")
        }
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        addTarget(nil, action: #selector(signIn), for: .touchUpInside)
    }
    
}
