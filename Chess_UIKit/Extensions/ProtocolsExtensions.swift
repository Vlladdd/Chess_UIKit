//
//  ProtocolsExtensions.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 15.11.2022.
//

import Foundation
import UIKit

// MARK: - Some useful protocols extensions

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

extension SpecialItemView {
    
    var item: GameItem {
        itemView.item
    }
    
    func unpickItem() {
        let lightModeTextColor = UIColor.white
        let darkModeTextColor = UIColor.black
        layer.borderColor = (traitCollection.userInterfaceStyle == .dark ? lightModeTextColor : darkModeTextColor).cgColor
    }
    
    func onRotate() {
        if let itemView = itemView as? FrameView {
            itemView.setNeedsDisplay()
        }
    }
    
}
