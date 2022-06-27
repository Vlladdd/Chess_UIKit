//
//  UIExtensions.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 13.06.2022.
//

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
    
    convenience init(cornerRadius: CGFloat) {
        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        contentMode = .scaleAspectFill
        layer.borderWidth = Constants.borderWidth
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        if traitCollection.userInterfaceStyle == .dark {
            backgroundColor = Constants.darkModeBackgroundColor
            layer.borderColor = Constants.darkModeBorderColor
        } else {
            backgroundColor = Constants.lightBackgroundColor
            layer.borderColor = Constants.lightModeBorderColor
        }
    }
    
    //rectangle view
    convenience init(width: CGFloat) {
        self.init()
        contentMode = .scaleAspectFit
        isUserInteractionEnabled = true
        translatesAutoresizingMaskIntoConstraints = false
        let constraints = [widthAnchor.constraint(equalToConstant: width), heightAnchor.constraint(equalTo: widthAnchor)]
        NSLayoutConstraint.activate(constraints)
        layer.borderWidth = Constants.borderWidth
        if traitCollection.userInterfaceStyle == .dark {
            layer.borderColor = Constants.darkModeBorderColor
        } else {
            layer.borderColor = Constants.lightModeBorderColor
        }
    }
    
    private struct Constants {
        static let borderWidth: CGFloat = 1
        static let darkModeBackgroundColor = UIColor.black
        static let lightBackgroundColor = UIColor.white
        static let darkModeBorderColor = UIColor.white.cgColor
        static let lightModeBorderColor = UIColor.black.cgColor
    }
    
}

extension UIImage {
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        //trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        //move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        //rotate around middle
        context.rotate(by: CGFloat(radians))
        //draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    func alpha(_ value: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
}
