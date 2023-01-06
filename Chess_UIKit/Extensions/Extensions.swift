//
//  Extensions.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 23.06.2022.
//

import Foundation

// MARK: - Some useful extensions

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

extension String {
    
    func capitalizingFirstLetter() -> String {
      return prefix(1).uppercased() + self.dropFirst()
    }

    mutating func capitalizeFirstLetter() {
      self = self.capitalizingFirstLetter()
    }
    
}

extension Date {
    
    var toStringDateHMS: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.string(from: self)
    }
    
}

extension Int {
    
    //converts timer time into human readable string
    var timeAsString: String {
        let prodMinutes = self / 60 % 60
        let prodSeconds = self % 60
        return String(format: "%02d:%02d", prodMinutes, prodSeconds)
    }
    
    var seconds: Self {
        self * 60
    }
    
}
