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

protocol ItemView: UIView {
    var item: GameItem { get }
}

protocol SpecialItemView: ItemView {
    var itemView: ItemView { get }
    
    func unpickItem() -> Void
    func onRotate() -> Void
}

protocol AdditionalButtonsBuilder {
    func addBackButton(with font: UIFont) -> Self
    func addCoinsView(with font: UIFont, and coins: Int) -> Self
}

protocol UPDataLineBuilder {
    func addLabel(with font: UIFont, and text: String) -> Self
    func addTextField(with font: UIFont, placeHolder: String, and startValue: String?, isNotifView: Bool) -> Self
    func addTextData(with font: UIFont, and text: String) -> Self
    func addSwitch(with currentState: Bool, and selector: Selector) -> Self
}

protocol CGDataLineBuilder {
    func addLabel(with font: UIFont, and text: String, isData: Bool) -> Self
    func addPicker<T>(with placeholder: String, font: UIFont, data: [T]) -> Self where T: RawRepresentable, T.RawValue == String
    func addSwitch(with currentState: Bool, and selector: Selector?) -> Self
    func addStepper(with minValue: Double, maxValue: Double, stepValue: Double, and selector: Selector) -> Self
}
