//
//  Protocols.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 15.11.2022.
//

import Foundation
import UIKit

// MARK: - Some useful protocols

protocol GameItem: Item {
    var type: GameItems { get }
    var cost: Int { get }
    var description: String { get }
    
    static var purchasable: [Self] { get }
}

protocol AuthorizationDelegate: UIViewController {
    func prepareForAuthorizationProcess() -> Void
    func errorCallbackForAuthorization(errorMessage: String) -> Void
    func successCallbackForAuthorization() -> Void
}

protocol StorageItem: Item {
    
    var folderName: Item? { get }
    
    func getFullPath() -> String?
    
}

//image and sound are different things, but right now they have same requirements
protocol ImageItem: StorageItem {}

protocol SoundItem: StorageItem {}

protocol Item {
    var name: String { get }
}
