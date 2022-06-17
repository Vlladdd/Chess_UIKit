//
//  UIExtensions.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 13.06.2022.
//

import Foundation
import UIKit

// MARK: - Some usefull UI Extensions

extension UIStackView {
    
    convenience init(axis: NSLayoutConstraint.Axis, alignment: UIStackView.Alignment, distribution: UIStackView.Distribution, spacing: CGFloat) {
        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        self.alignment = alignment
        self.distribution = distribution
        self.spacing = spacing
        self.axis = axis
    }
    
}

extension UILabel {
    
    convenience init(text: String, alignment: NSTextAlignment, font: UIFont) {
        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        self.text = text
        self.textAlignment = alignment
        self.font = font
        if traitCollection.userInterfaceStyle == .dark {
            textColor = Constants.darkModeTextColor
        } else {
            textColor = Constants.lightModeTextColor
        }
    }
    
    private struct Constants {
        static let darkModeTextColor = UIColor.white
        static let lightModeTextColor = UIColor.black
    }
    
}

extension UIImageView {
    
    //rectangle view
    convenience init(width: CGFloat) {
        self.init()
        contentMode = .scaleAspectFit
        isUserInteractionEnabled = true
        translatesAutoresizingMaskIntoConstraints = false
        let constraints = [widthAnchor.constraint(equalToConstant: width), heightAnchor.constraint(equalTo: widthAnchor)]
        NSLayoutConstraint.activate(constraints)
        layer.borderWidth = 1
        if traitCollection.userInterfaceStyle == .dark {
            layer.borderColor = Constants.darkModeBorderColor
        } else {
            layer.borderColor = Constants.lightModeBorderColor
        }
    }
    
    private struct Constants {
        static let darkModeBorderColor = UIColor.white.cgColor
        static let lightModeBorderColor = UIColor.black.cgColor
    }
    
}
