//
//  GoogleSignInButton.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 13.11.2022.
//

import UIKit
import GoogleSignIn

// MARK: - GoogleSignInButtonDelegate

protocol GoogleSignInButtonDelegate: AnyObject {
    func googleSignInButtonDidTriggerSignIn(_ googleSignInButton: GoogleSignInButton) -> Void
}

// MARK: - GoogleSignInButton

//class that represents custom Google Sign In button
class GoogleSignInButton: GIDSignInButton {
    
    // MARK: - Properties
    
    weak var delegate: GoogleSignInButtonDelegate?
    
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
        delegate?.googleSignInButtonDidTriggerSignIn(self)
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        addTarget(nil, action: #selector(signIn), for: .touchUpInside)
    }
    
}
