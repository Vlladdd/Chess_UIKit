//
//  Storage.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 09.09.2022.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseDatabaseSwift
import FirebaseAuth
import GoogleSignIn

//struct that represents storage(currently only FIrebase)
struct Storage {
    
    // MARK: - Properties
    
    private var firebaseDatabase = Database.database().reference()
    private var chatHistory = [ChatMessage]()
    
    private typealias constants = Storage_Constants
    
    var clientID: String? {
        FirebaseApp.app()?.options.clientID
    }
    
    // MARK: - Methods
    
    mutating func addChatMessageToHistory(_ chatMessage: ChatMessage) {
        if !chatHistory.contains(chatMessage) {
            chatHistory.append(chatMessage)
        }
    }
    
    func checkIfChatMessageInHistory(_ chatMessage: ChatMessage) -> Bool {
        chatHistory.contains(chatMessage)
    }
    
    //signs ins user with google account and gets his data from database
    func signInWith(idToken: String, and accessToken: String, callback:  @escaping (Error?, User?, MultiFactorResolver?, String?) -> Void) {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        Auth.auth().signIn(with: credential) { authResult, error in
            callbackForSignIn(error: error, authResult: authResult, callback: { error, user, resolver, displayNameString in
                callback(error, user, resolver, displayNameString)
            })
        }
    }
    
    //signs ins user with email and password and gets his data from database
    func signInWith(email: String, and password: String, callback:  @escaping (Error?, User?, MultiFactorResolver?, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            callbackForSignIn(error: error, authResult: authResult, callback: { error, user, resolver, displayNameString in
                callback(error, user, resolver, displayNameString)
            })
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func checkIfUserIsLoggedIn(callback: @escaping (Bool, Error?, User?) -> Void) {
        if Auth.auth().currentUser != nil {
            findUser(callback: { error, user in
                callback(true, error, user)
            })
        }
        else {
            callback(false, nil, nil)
        }
    }
    
    func checkIfGoogleSignIn() -> Bool {
        Auth.auth().currentUser?.providerData.first?.providerID == constants.googleProviderID
    }
    
    //creates new user for authentication and then new user object in database
    func createUser(with email: String, and password: String, callback:  @escaping (Error?, User?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            guard error == nil else {
                print(error!.localizedDescription)
                callback(error, nil)
                return
            }
            if authResult != nil {
                let newUser = User(email: email)
                saveUser(newUser)
                callback(nil, newUser)
                return
            }
            callback(nil, nil)
        }
    }
    
    //checks if MFA required and tries to get user`s data, if not
    private func callbackForSignIn(error: Error?, authResult: AuthDataResult?, callback:  @escaping (Error?, User?, MultiFactorResolver?, String?) -> Void) {
        guard error == nil else {
            let multifactorRequired = checkIfMultifactorRequired(error: error!)
            print(error!.localizedDescription)
            callback(error, nil, multifactorRequired.resolver, multifactorRequired.displayNameString)
            return
        }
        if let authResult = authResult {
            getCurrentUser(authResult: authResult, callback: { error, user in
                callback(error, user, nil, nil)
            })
        }
        else {
            callback(nil, nil, nil, nil)
        }
    }
    
    //checks if MFA required
    private func checkIfMultifactorRequired(error: Error) -> (resolver: MultiFactorResolver?, displayNameString: String?) {
        let authError = error as NSError
        if authError.code == AuthErrorCode.secondFactorRequired.rawValue {
            // The user is a multi-factor user. Second factor challenge is required.
            let resolver = authError.userInfo[AuthErrorUserInfoMultiFactorResolverKey] as! MultiFactorResolver
            var displayNameString = ""
            for tmpFactorInfo in resolver.hints {
                displayNameString += tmpFactorInfo.displayName ?? ""
                displayNameString += " "
            }
            return (resolver, displayNameString)
        }
        return (nil, nil)
    }
    
    func updateUserAccount(with email: String, and password: String, callback:  @escaping (Error?) -> Void) {
        Auth.auth().currentUser?.updateEmail(to: email, completion: { error in
            guard error == nil else {
                print(error!.localizedDescription)
                callback(error)
                return
            }
            if !password.isEmpty {
                Auth.auth().currentUser?.updatePassword(to: password, completion: { error in
                    guard error == nil else {
                        print(error!.localizedDescription)
                        callback(error)
                        return
                    }
                    callback(nil)
                })
            }
            else {
                callback(nil)
            }
        })
    }
    
    //we are using uid of the user as child name in users node
    func saveUser(_ user: User) {
        do {
            if let key = Auth.auth().currentUser?.uid {
                try firebaseDatabase.child(constants.keyForUsers).child(key).setValue(from: user)
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func saveGameForMultiplayer(_ game: GameLogic) {
        if let gameID = game.gameID {
            do {
                try firebaseDatabase.child(constants.keyForMultiplayerGames).child(gameID).setValue(from: game)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func deleteMultiplayerGame(with gameID: String) {
        firebaseDatabase.child(constants.keyForMultiplayerGames).child(gameID).removeValue()
    }
    
    //observer, which is looking for available multiplayer games
    func getMultiplayerGames(callback: @escaping (Error?, [GameLogic]?) -> ()) {
        let game = firebaseDatabase.child(constants.keyForMultiplayerGames)
        game.observe(.value, with: { snapshot in
            if snapshot.exists() {
                if let games = snapshot.children.allObjects as? [DataSnapshot] {
                    var findedGames = [GameLogic]()
                    for game in games {
                        do {
                            let findedGame = try game.data(as: GameLogic.self)
                            findedGames.append(findedGame)
                        }
                        catch {
                            print(error.localizedDescription)
                            callback(error, nil)
                            return
                        }
                    }
                    callback(nil, findedGames)
                    return
                }
            }
            else {
                callback(nil, nil)
            }
        })
    }
    
    func removeMultiplayerGamesObservers() {
        firebaseDatabase.child(constants.keyForMultiplayerGames).removeAllObservers()
    }
    
    func multifactorAuth(with resolver: MultiFactorResolver, and displayName: String, callback:  @escaping (Error?, String?, PhoneMultiFactorInfo?) -> Void) {
        var selectedHint: PhoneMultiFactorInfo?
        for tmpFactorInfo in resolver.hints {
            if displayName == tmpFactorInfo.displayName {
                selectedHint = tmpFactorInfo as? PhoneMultiFactorInfo
            }
        }
        PhoneAuthProvider.provider().verifyPhoneNumber(with: selectedHint!, uiDelegate: nil, multiFactorSession: resolver.session) { verificationID, error in
            callback(error, verificationID, selectedHint)
        }
    }
    
    func checkVerificationCode(with resolver: MultiFactorResolver, verificationID: String, verificationCode: String, callback:  @escaping (Error?, User?) -> Void) {
        let credential: PhoneAuthCredential? = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        let assertion: MultiFactorAssertion? = PhoneMultiFactorGenerator.assertion(with: credential!)
        resolver.resolveSignIn(with: assertion!) { authResult, error in
            guard error == nil else {
                callback(error, nil)
                return
            }
            if let authResult = authResult {
                getCurrentUser(authResult: authResult, callback: { error, user in
                    callback(error, user)
                })
            }
            else {
                callback(nil, nil)
            }
        }
    }
    
    //looking for an associated data for user uid in a database
    private func findUser(callback: @escaping (Error?, User?) -> ()) {
        if let key = Auth.auth().currentUser?.uid {
            let user = firebaseDatabase.child(constants.keyForUsers).child(key)
            user.getData(completion: { error, snapshot in
                guard error == nil else {
                    print(error!.localizedDescription)
                    callback(error, nil)
                    return
                }
                if snapshot.exists() {
                    do {
                        let findedUser = try snapshot.data(as: User.self)
                        callback(nil, findedUser)
                        return
                    }
                    catch {
                        print(error.localizedDescription)
                        callback(error, nil)
                        return
                    }
                }
                else {
                    callback(nil, nil)
                }
            })
        }
        else {
            callback(nil, nil)
        }
    }
    
    private func getCurrentUser(authResult: AuthDataResult, callback: @escaping (Error?, User?) -> ()) {
        findUser(callback: {error, user in
            guard error == nil else {
                print(error!.localizedDescription)
                callback(error, nil)
                return
            }
            if let user = user {
                callback(nil, user)
                return
            }
            else {
                let newUser = User(email: authResult.user.email ?? "")
                saveUser(newUser)
                callback(nil, newUser)
                return
            }
        })
    }
    
}

// MARK: - Constants

private struct Storage_Constants {
    static let keyForUsers = "users"
    static let keyForMultiplayerGames = "multiplayerGames"
    static let googleProviderID = "google.com"
}
