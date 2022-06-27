//
//  Extensions.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 23.06.2022.
//

import Foundation

// MARK: - Some usefull extensions

extension Array {
    
    var second: Self.Element? {
        if self.count > 1 {
            return self[1]
        }
        return nil
    }
    
    var third: Self.Element? {
        if self.count > 2 {
            return self[2]
        }
        return nil
    }
    
    var beforeLast: Self.Element? {
        if self.count > 1 {
            return self[self.count-2]
        }
        return nil
    }
    
}
