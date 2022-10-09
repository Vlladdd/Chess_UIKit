//
//  Storage.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 09.09.2022.
//

import Foundation
import FirebaseDatabase
import FirebaseDatabaseSwift
import FirebaseAuth

//struct that represents storage(currently only FIrebase)
struct Storage {
    
    // MARK: - Properties
    
    private var firebaseDatabase = Database.database().reference()
    
    private typealias constants = Storage_Constants
    
    // MARK: - Methods
    
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
    
    //signs ins user and gets his data from database
    func signInUser(with email: String, and password: String, callback:  @escaping (Error?, User?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            guard error == nil else {
                print(error!.localizedDescription)
                callback(error, nil)
                return
            }
            if authResult != nil {
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
                    callback(nil, nil)
                })
                return
            }
            callback(nil, nil)
        }
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
        do {
            try firebaseDatabase.child(constants.keyForMultiplayerGames).child(game.startDate.toStringDateHMS).setValue(from: game)
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    //looking for an associated data for user uid in a database
    private func findUser(callback: @escaping (Error?, User?) -> ()) {
        if let key = Auth.auth().currentUser?.uid {
            let user = firebaseDatabase.child("users").child(key)
            user.getData(completion: { error, snapshot in
                guard error == nil else {
                    print(error!.localizedDescription)
                    callback(error, nil)
                    return
                }
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
            })
        }
        else {
            callback(nil, nil)
        }
    }
    
}

// MARK: - Constants

private struct Storage_Constants {
    static let keyForUsers = "users"
    static let keyForMultiplayerGames = "multiplayerGames"
}
