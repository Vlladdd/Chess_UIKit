//
//  ProtocolsExtensions.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 15.11.2022.
//

import Foundation
import UIKit
import Firebase

// MARK: - Some useful protocols extensions

extension AuthorizationDelegate {
    
    func loginOperation(currentUser: User?, error: Error?, resolver: MultiFactorResolver?, displayNameString: String?) {
        guard error == nil else {
            if let resolver = resolver, let displayNameString = displayNameString {
                showTextInputPrompt(withMessage: "Select factor to sign in\n\(displayNameString)", completionBlock: {
                    [weak self] userPressedOK, displayName in
                    if let displayName = displayName {
                        self?.storage.multifactorAuth(with: resolver, and: displayName, callback: { error, verificationID, selectedHint in
                            self?.multiFactorOperation(error: error, verificationID: verificationID, selectedHint: selectedHint, resolver: resolver)
                        })
                    }
                    else {
                        self?.errorCallbackForAuthorization(errorMessage: "DisplayName is nil")
                    }
                })
                return
            }
            else {
                errorCallbackForAuthorization(errorMessage: error!.localizedDescription)
                return
            }
        }
        successCallbackForAuthorization(user: currentUser)
    }
    
    private func multiFactorOperation(error: Error?, verificationID: String?, selectedHint: PhoneMultiFactorInfo?, resolver: MultiFactorResolver) {
        guard error == nil else {
            errorCallbackForAuthorization(errorMessage: "Multi factor start sign in failed. Error: \(error.debugDescription)")
            return
        }
        if let verificationID = verificationID {
            showTextInputPrompt(withMessage: "Verification code for \(selectedHint?.displayName ?? "")", completionBlock: {
                [weak self] userPressedOK, verificationCode in
                if let verificationCode = verificationCode {
                    self?.storage.checkVerificationCode(with: resolver, verificationID: verificationID, verificationCode: verificationCode, callback: {
                        error, user in
                        self?.checkVerificationCodeOperation(error: error, currentUser: user)
                    })
                }
                else {
                    self?.errorCallbackForAuthorization(errorMessage: "VerificationCode is nil")
                }
            })
        }
        else {
            errorCallbackForAuthorization(errorMessage: "VerificationID is nil")
        }
    }
    
    private func checkVerificationCodeOperation(error: Error?, currentUser: User?) {
        guard error == nil else {
            errorCallbackForAuthorization(errorMessage: "Multi factor finalize sign in failed. Error: \(error.debugDescription)")
            return
        }
        navigationController?.popViewController(animated: true)
        successCallbackForAuthorization(user: currentUser)
    }
    
}

extension Item where Self: RawRepresentable, Self.RawValue == String {
    var name: String { rawValue }
}

extension Sound where Self: RawRepresentable, Self.RawValue == String {
    var name: String { rawValue }
}

