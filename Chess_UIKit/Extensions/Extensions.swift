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
        self.count > 1 ? self[1] : nil
    }
    
    var third: Self.Element? {
        self.count > 2 ? self[2] : nil
    }
    
    var beforeLast: Self.Element? {
        self.count > 1 ? self[self.count-2] : nil
    }
    
}

extension String {
    
    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = capitalizingFirstLetter()
    }
    
    //converts variable name in string sentence
    func getHumanReadableString() -> String {
        var string = self
        var indexOffset = 0
        for (index, character) in string.enumerated() {
            let stringCharacter = String(character)
            if stringCharacter.lowercased() != stringCharacter {
                guard index != 0 else { continue }
                let stringIndex = string.index(string.startIndex, offsetBy: index + indexOffset)
                let endStringIndex = string.index(string.startIndex, offsetBy: index + 1 + indexOffset)
                let range = stringIndex..<endStringIndex
                indexOffset += 1
                string.replaceSubrange(range, with: " \(stringCharacter)")
            }
        }
        return string.capitalizingFirstLetter()
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

extension Data {
    
    var MB: Double {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB]
        bcf.countStyle = .file
        return Double(bcf.string(fromByteCount: Int64(count)).replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: " MB", with: "")) ?? 0.0
    }
    
}

extension RawRepresentable where RawValue == String {
    
    var asString: String {
        rawValue
    }
    
}
