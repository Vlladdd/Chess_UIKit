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
    
    var storage: Storage {
        Storage.sharedInstance
    }
    
    func loginOperation(with resolver: MultiFactorResolver?, displayNameString: String?) {
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
                            await self.navigationController?.popViewController(animated: true)
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
    
}

extension Item where Self: RawRepresentable, Self.RawValue == String {
    var name: String { asString }
}

extension Item {
    
    func getHumanReadableName() -> String {
        name.getHumanReadableString()
    }
    
}

extension StorageItem {
    
    //some items have different folders, depending on what theme is used,
    //so we are not specifying it here, instead using CustomItem
    var folderName: Item? {
        nil
    }
    
    //some items can`t exist without theme, CustomItem should be used
    func getFullPath() -> String? {
        if let folderName {
            return "\(folderName)/\(name)"
        }
        return nil
    }
    
}

extension StorageItem where Self: GameItem {
    var folderName: Item? {
        type
    }
}

extension WSManagerDelegate {
    
    func socketConnected(with headers: [String: String]) {
        print("websocket is connected: \(headers)")
    }
    
    func socketDisconnected(with reason: String, and code: UInt16) {
        print("websocket is disconnected: \(reason) with code: \(code)")
    }
    
    func socketReceivedData(_ data: Data) {
        print("Received data: \(data.count)")
    }
    
    func socketReceivedText(_ text: String) {
        print("Received text: \(text)")
    }
    
    func webSocketError(with message: String) {
        print(message)
    }
    
    func lostInternet() {
        print("Lost internet connection")
    }
    
}
