//
//  CustomImageItem.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 14.01.2023.
//

import Foundation

//struct that represents skined image item
struct CustomImageItem: ImageItem {
    
    // MARK: - Properties
    
    var name: String {
        theme.name + item.name.capitalizingFirstLetter()
    }
    
    var item: ImageItem
    var theme: ImageItem
    
    // MARK: - Methods
    
    func getFullPath() -> String? {
        if let folderName = theme.folderName {
            return "\(folderName)/\(theme.name)/\(item.name)"
        }
        return nil
    }
    
}
