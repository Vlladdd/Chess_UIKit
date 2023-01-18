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

//class that represents storage(currently only Firebase)
class Storage {
    
    // MARK: - Properties
    
    static let sharedInstance = Storage()
    
    private let firebaseDatabase = Database.database().reference()
    
    private var chatHistory = [ChatMessage]()
    
    private typealias constants = Storage_Constants
    
    var clientID: String? {
        FirebaseApp.app()?.options.clientID
    }
    
    var currentUser: User! {
        didSet {
            saveCurrentUser()
        }
    }
    
    private enum ExtraFirebaseErrors: Error, LocalizedError {
        
        case userNotLoggedIn
        case authResultIsEmpty
        case snapshotNotExist
        
        var errorDescription: String? {
            switch self {
            case .userNotLoggedIn:
                return NSLocalizedString("Current user in Firebase is not valid", comment: "ExtraFirebaseErrors")
            case .authResultIsEmpty:
                return NSLocalizedString("Authorization result from sign in method of Firebase is not valid", comment: "ExtraFirebaseErrors")
            case .snapshotNotExist:
                return NSLocalizedString("Data in Firebase not found", comment: "ExtraFirebaseErrors")
            }
        }
        
    }
    
    // MARK: - Inits
    
    //singleton
    private init() {}
    
    // MARK: - Methods
    
    func signInAsGuest() {
        currentUser = User(email: "", nickname: constants.defaultNickname, guestMode: true)
    }
    
    func addChatMessageToHistory(_ chatMessage: ChatMessage) {
        if !chatHistory.contains(chatMessage) {
            chatHistory.append(chatMessage)
        }
    }
    
    func checkIfChatMessageInHistory(_ chatMessage: ChatMessage) -> Bool {
        chatHistory.contains(chatMessage)
    }
    
    //signs ins user with google account and gets his data from database
    func signInWith(idToken: String, and accessToken: String, callback:  @escaping (Error?, MultiFactorResolver?, String?) -> Void) {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            self?.callbackForSignIn(error: error, authResult: authResult, callback: { error, resolver, displayNameString in
                callback(error, resolver, displayNameString)
            })
        }
    }
    
    //signs ins user with email and password and gets his data from database
    func signInWith(email: String, and password: String, callback:  @escaping (Error?, MultiFactorResolver?, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            self?.callbackForSignIn(error: error, authResult: authResult, callback: { error, resolver, displayNameString in
                callback(error, resolver, displayNameString)
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
        currentUser = nil
    }
    
    func checkIfUserIsLoggedIn(callback: @escaping (Bool, Error?) -> Void) {
        if Auth.auth().currentUser != nil {
            findUser(callback: { error in
                callback(true, error)
            })
        }
        else {
            callback(false, ExtraFirebaseErrors.userNotLoggedIn)
        }
    }
    
    func checkIfGoogleSignIn() -> Bool {
        Auth.auth().currentUser?.providerData.first?.providerID == constants.googleProviderID
    }
    
    //creates new user for authentication and then new user object in database
    func createUser(with email: String, and password: String, callback:  @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard error == nil else {
                print(error!.localizedDescription)
                callback(error)
                return
            }
            if authResult != nil {
                self?.currentUser = User(email: email)
                callback(nil)
                return
            }
            callback(ExtraFirebaseErrors.authResultIsEmpty)
        }
    }
    
    //checks if MFA required and tries to get user`s data, if not
    private func callbackForSignIn(error: Error?, authResult: AuthDataResult?, callback:  @escaping (Error?, MultiFactorResolver?, String?) -> Void) {
        guard error == nil else {
            let multifactorRequired = checkIfMultifactorRequired(error: error!)
            print(error!.localizedDescription)
            callback(error, multifactorRequired.resolver, multifactorRequired.displayNameString)
            return
        }
        if let authResult = authResult {
            getCurrentUser(authResult: authResult, callback: { error in
                callback(error, nil, nil)
            })
        }
        else {
            callback(ExtraFirebaseErrors.authResultIsEmpty, nil, nil)
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
    
    func addGameToCurrentUserAndSave(_ game: GameLogic) {
        //if game was already in games array, saveCurrentUser() will not be trigered, so we have to do it
        //manually, to be sure, that it is saved
        if !currentUser.addGame(game) {
            saveCurrentUser()
        }
    }
    
    //we are using uid of the user as child name in users node
    func saveCurrentUser() {
        do {
            if let key = Auth.auth().currentUser?.uid {
                try firebaseDatabase.child(constants.keyForUsers).child(key).setValue(from: currentUser)
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
                callback(ExtraFirebaseErrors.snapshotNotExist, nil)
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
    
    func checkVerificationCode(with resolver: MultiFactorResolver, verificationID: String, verificationCode: String, callback:  @escaping (Error?) -> Void) {
        let credential: PhoneAuthCredential? = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        let assertion: MultiFactorAssertion? = PhoneMultiFactorGenerator.assertion(with: credential!)
        resolver.resolveSignIn(with: assertion!) { [weak self] authResult, error in
            guard error == nil else {
                callback(error)
                return
            }
            if let authResult = authResult {
                self?.getCurrentUser(authResult: authResult, callback: { error in
                    callback(error)
                })
            }
            else {
                callback(ExtraFirebaseErrors.authResultIsEmpty)
            }
        }
    }
    
    //looking for an associated data for user uid in a database
    private func findUser(callback: @escaping (Error?) -> ()) {
        if let key = Auth.auth().currentUser?.uid {
            let user = firebaseDatabase.child(constants.keyForUsers).child(key)
            user.getData(completion: { [weak self] error, snapshot in
                guard error == nil else {
                    print(error!.localizedDescription)
                    callback(error)
                    return
                }
                if let snapshot, snapshot.exists() {
                    do {
                        self?.currentUser = try snapshot.data(as: User.self)
                        callback(nil)
                        return
                    }
                    catch {
                        print(error.localizedDescription)
                        callback(error)
                        return
                    }
                }
                else {
                    callback(ExtraFirebaseErrors.snapshotNotExist)
                }
            })
        }
        else {
            callback(ExtraFirebaseErrors.userNotLoggedIn)
        }
    }
    
    private func getCurrentUser(authResult: AuthDataResult, callback: @escaping (Error?) -> ()) {
        findUser(callback: { [weak self] error in
            guard error == nil else {
                if error as? ExtraFirebaseErrors == .snapshotNotExist {
                    self?.currentUser = User(email: authResult.user.email ?? "")
                    callback(nil)
                    return
                }
                else {
                    print(error!.localizedDescription)
                    callback(error)
                    return
                }
            }
            callback(nil)
        })
    }
    
}

// MARK: - Constants

private struct Storage_Constants {
    static let keyForUsers = "users"
    static let keyForMultiplayerGames = "multiplayerGames"
    static let googleProviderID = "google.com"
    static let defaultNickname = "Player1"
}
