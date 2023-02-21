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
    func signInWith(idToken: String, and accessToken: String) async throws -> (resolver: MultiFactorResolver?, displayNameString: String?) {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            let result = try await signInResultWith(error: nil, authResult: authResult)
            return (result.resolver, result.displayNameString)
        }
        catch {
            do {
                let result = try await signInResultWith(error: error, authResult: nil)
                return (result.resolver, result.displayNameString)
            }
            catch {
                throw error
            }
        }
    }
    
    //signs ins user with email and password and gets his data from database
    func signInWith(email: String, and password: String) async throws -> (resolver: MultiFactorResolver?, displayNameString: String?) {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let result = try await signInResultWith(error: nil, authResult: authResult)
            return (result.resolver, result.displayNameString)
        }
        catch {
            do {
                let result = try await signInResultWith(error: error, authResult: nil)
                return (result.resolver, result.displayNameString)
            }
            catch {
                throw error
            }
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
    
    func checkIfUserIsLoggedIn() async throws -> Bool {
        if Auth.auth().currentUser != nil {
            do {
                try await findUser()
                return true
            }
            catch {
                throw error
            }
        }
        return false
    }
    
    func checkIfGoogleSignIn() -> Bool {
        Auth.auth().currentUser?.providerData.first?.providerID == constants.googleProviderID
    }
    
    //creates new user for authentication and then new user object in database
    func createUser(with email: String, and password: String) async throws {
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
            currentUser = User(email: email)
        }
        catch {
            throw error
        }
    }
    
    //checks if MFA required and tries to get user`s data, if not
    private func signInResultWith(error: Error?, authResult: AuthDataResult?) async throws -> (resolver: MultiFactorResolver?, displayNameString: String?) {
        guard error == nil else {
            do {
                let multifactorRequired = try checkIfMultifactorRequired(error: error!)
                return (multifactorRequired.resolver, multifactorRequired.displayNameString)
            }
            catch {
                throw error
            }
        }
        if let authResult {
            do {
                try await getCurrentUser(authResult: authResult)
                return (nil, nil)
            }
            catch {
                throw error
            }
        }
        else {
            throw ExtraFirebaseErrors.authResultIsEmpty
        }
    }
    
    //checks if MFA required
    private func checkIfMultifactorRequired(error: Error) throws -> (resolver: MultiFactorResolver, displayNameString: String) {
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
        else {
            throw error
        }
    }
    
    func updateUserAccount(with email: String, and password: String) async throws {
        do {
            try await Auth.auth().currentUser?.updateEmail(to: email)
            currentUser.updateEmail(newValue: email)
            if !password.isEmpty {
                try await Auth.auth().currentUser?.updatePassword(to: password)
            }
        }
        catch {
            throw error
        }
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
    func getMultiplayerGames() -> AsyncThrowingStream<[GameLogic], Error> {
        let game = firebaseDatabase.child(constants.keyForMultiplayerGames)
        return AsyncThrowingStream { continuation in
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
                                continuation.finish(throwing: error)
                            }
                        }
                        continuation.yield(findedGames)
                    }
                }
                else {
                    continuation.finish(throwing: ExtraFirebaseErrors.snapshotNotExist)
                }
            })
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.removeMultiplayerGamesObservers()
            }
        }
    }
    
    private func removeMultiplayerGamesObservers() {
        firebaseDatabase.child(constants.keyForMultiplayerGames).removeAllObservers()
    }
    
    func multifactorAuth(with resolver: MultiFactorResolver, and displayName: String) async throws -> (verificationID: String, selectedHint: PhoneMultiFactorInfo?) {
        var selectedHint: PhoneMultiFactorInfo?
        for tmpFactorInfo in resolver.hints {
            if displayName == tmpFactorInfo.displayName {
                selectedHint = tmpFactorInfo as? PhoneMultiFactorInfo
            }
        }
        do {
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(with: selectedHint!, uiDelegate: nil, multiFactorSession: resolver.session)
            return (verificationID, selectedHint)
        }
        catch {
            throw error
        }
    }
    
    func checkVerificationCode(with resolver: MultiFactorResolver, verificationID: String, verificationCode: String) async throws {
        let credential: PhoneAuthCredential? = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        let assertion: MultiFactorAssertion? = PhoneMultiFactorGenerator.assertion(with: credential!)
        do {
            let authResult = try await resolver.resolveSignIn(with: assertion!)
            do {
                try await getCurrentUser(authResult: authResult)
            }
            catch {
                throw error
            }
        }
        catch {
            throw error
        }
    }
    
    //looking for an associated data for user uid in a database
    private func findUser() async throws {
        if let key = Auth.auth().currentUser?.uid {
            let user = firebaseDatabase.child(constants.keyForUsers).child(key)
            do {
                let snapshot = try await user.getData()
                if snapshot.exists() {
                    do {
                        currentUser = try snapshot.data(as: User.self)
                    }
                    catch {
                        throw error
                    }
                }
                else {
                    throw ExtraFirebaseErrors.snapshotNotExist
                }
            }
            catch {
                throw error
            }
        }
        else {
            throw ExtraFirebaseErrors.userNotLoggedIn
        }
    }
    
    private func getCurrentUser(authResult: AuthDataResult) async throws {
        do {
            try await findUser()
        }
        catch {
            if error as? ExtraFirebaseErrors == .snapshotNotExist {
                currentUser = User(email: authResult.user.email ?? "")
            }
            else {
                throw error
            }
        }
    }
    
}

// MARK: - Constants

private struct Storage_Constants {
    static let keyForUsers = "users"
    static let keyForMultiplayerGames = "multiplayerGames"
    static let googleProviderID = "google.com"
    static let defaultNickname = "Player1"
}
