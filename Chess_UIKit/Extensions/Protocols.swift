//
//  Protocols.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 15.11.2022.
//

import Foundation
import UIKit

// MARK: - Some useful protocols

protocol Item {
    var type: ItemTypes { get }
    var name: String { get }
    var cost: Int { get }
    var description: String { get }
    
    static var purchasable: [Self] { get }
}

protocol AuthorizationDelegate: UIViewController {
    var storage: Storage { get }
    
    func prepareForAuthorizationProcess() -> Void
    func errorCallbackForAuthorization(errorMessage: String) -> Void
    func successCallbackForAuthorization(user: User?) -> Void
}

protocol Sound {
    var name: String { get }
    var folderName: String { get }
}
