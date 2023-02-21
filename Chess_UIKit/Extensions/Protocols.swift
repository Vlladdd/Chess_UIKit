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
    func authorizationErrorWith(errorMessage: String) -> Void
    func successAuthorization() -> Void
}

protocol WSManagerDelegate: UIViewController {
    func socketConnected(with headers: [String: String])
    func socketDisconnected(with reason: String, and code: UInt16)
    func socketReceivedData(_ data: Data)
    func socketReceivedText(_ text: String)
    func webSocketError(with message: String)
    func lostInternet()
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

protocol MainMenuDelegate: UIViewController {
    func signOut() -> Void
    func toggleUserProfileVC() -> Void
    func toggleCreateGameVC() -> Void
    func showGameVC(with game: GameLogic) -> Void
    func makeErrorAlert(with message: String) -> Void
}

protocol NotificationIconsDelegate: UIView {
    func updateNotificationIcons() -> Void
}

protocol MainMenuViewDelegate: UIView, NotificationIconsDelegate {
    var font: UIFont { get }
    var mainMenuDelegate: MainMenuDelegate? { get set }
    
    func makeMenu(with elements: UIStackView, reversed: Bool) -> Void
    func buyItem(itemView: ItemView, additionalChanges: @escaping () -> Void) -> Void
}

protocol ItemView: UIView {
    var item: GameItem { get }
}

protocol SpecialItemView: ItemView {
    var itemView: ItemView { get }
}

//if view need additional buttons
protocol AdditionalButtonsDelegate: UIView {
    func makeAdditionalButtons() -> AdditionalButtons
}

protocol InvItemDelegate: AdditionalButtonsDelegate, NotificationIconsDelegate {
    var font: UIFont { get }
    
    func updateItemsColor(inShop: Bool) -> Void
}

protocol MPGamesDelegate: AdditionalButtonsDelegate {
    var searchingForMPgames: Task<Void, Error>? { get set }
}

protocol AdditionalButtonsBuilder {
    func addBackButton(type: BackButtonType) -> Self
    func addCoinsView() -> Self
}
