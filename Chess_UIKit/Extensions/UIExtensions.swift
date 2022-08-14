//
//  UIExtensions.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 13.06.2022.
//

import UIKit

// MARK: - Some usefull UI Extensions

extension UIButton {
    
    func buttonWith(image: UIImage?, and function: Selector) {
        translatesAutoresizingMaskIntoConstraints = false
        addTarget(nil, action: function, for: .touchUpInside)
        setBackgroundImage(image, for: .normal)
    }
    
}

extension UIStackView {
    
    func setup(axis: NSLayoutConstraint.Axis, alignment: UIStackView.Alignment, distribution: UIStackView.Distribution, spacing: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        self.alignment = alignment
        self.distribution = distribution
        self.spacing = spacing
        self.axis = axis
    }
    
    func defaultSettings() {
        layer.borderWidth = Constants.borderWidth
        layer.cornerRadius = Constants.cornerRadius
        if traitCollection.userInterfaceStyle == .dark {
            backgroundColor = Constants.darkModeBackgroundColor
            layer.borderColor = Constants.darkModeBorderColor
        } else {
            backgroundColor = Constants.lightBackgroundColor
            layer.borderColor = Constants.lightModeBorderColor
        }
    }
    
    private struct Constants {
        static let cornerRadius: CGFloat = 10
        static let borderWidth: CGFloat = 1
        static let darkModeBackgroundColor = UIColor.black
        static let lightBackgroundColor = UIColor.white
        static let darkModeBorderColor = UIColor.white.cgColor
        static let lightModeBorderColor = UIColor.black.cgColor
    }
    
}

extension UILabel {
    
    func setup(text: String, alignment: NSTextAlignment, font: UIFont) {
        translatesAutoresizingMaskIntoConstraints = false
        //for proper animation, when label and his font changing size
        contentMode = .scaleAspectFit
        adjustsFontSizeToFitWidth = true
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
    
    func defaultSettings() {
        translatesAutoresizingMaskIntoConstraints = false
        contentMode = .scaleAspectFill
        layer.borderWidth = Constants.borderWidth
        layer.cornerRadius = Constants.cornerRadius
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
    func rectangleView(width: CGFloat) {
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
        static let cornerRadius: CGFloat = 10
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

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(
           red:   .random(),
           green: .random(),
           blue:  .random(),
           alpha: 1.0
        )
    }
}

extension CALayer {
    
    func moveTo(position: CGPoint, animated: Bool, duration: TimeInterval = 0) {
        if animated {
            let animation = CABasicAnimation(keyPath: #keyPath(CALayer.position))
            animation.fromValue = self.position
            animation.toValue = position
            animation.fillMode = .forwards
            animation.duration = duration
            self.position = position
            add(animation, forKey: #keyPath(CALayer.position))
        } else {
            self.position = position
        }
    }
    
    func rotate(from startAngle: CGFloat, to endAngle: CGFloat, animated: Bool, duration: TimeInterval = 0) {
        if animated {
            let animation = CABasicAnimation(keyPath: "transform.rotation")
            animation.fromValue = startAngle
            animation.toValue = endAngle
            animation.duration = duration
            transform = CATransform3DMakeRotation(endAngle, 0.0, 0.0, 1.0)
            add(animation, forKey: nil)
        }
        else {
            transform = CATransform3DMakeRotation(endAngle, 0.0, 0.0, 1.0)
        }
    }
    
}

extension CAShapeLayer {
    
    func updatePath(with newPath: CGPath, animated: Bool, duration: TimeInterval = 0) {
        if animated {
            let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
            animation.fromValue = path
            animation.toValue = newPath
            animation.duration = duration
            path = newPath
            add(animation, forKey: #keyPath(CAShapeLayer.path))
        }
        else {
            path = newPath
        }
    }
    
    func updateStroke(to color: CGColor, animated: Bool, duration: TimeInterval = 0) {
        if animated {
            let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeColor))
            animation.fromValue = strokeColor
            animation.toValue = color
            animation.duration = duration
            strokeColor = color
            add(animation, forKey: #keyPath(CAShapeLayer.strokeColor))
        }
        else {
            strokeColor = color
        }
    }
    
}

extension UIScrollView {
    
    //scrols to view and centers him on center of ScrollView on the available area on screen
    func scrollToViewAndCenterOnScreen(view: UIView, animated: Bool) {
        if let content = subviews.first, content.subviews.contains(view) {
            let childPoint = convert(view.frame, to: self)
            let screenMidY = bounds.maxY - bounds.midY
            let screenMidX = bounds.maxX - bounds.midX
            setContentOffset(CGPoint(x: childPoint.midX - screenMidX, y: childPoint.midY - screenMidY), animated: animated)
        }
    }
    
    func checkIfViewInCenterOfTheScreen(view: UIView) -> Bool {
        if let content = subviews.first, content.subviews.contains(view) {
            let childPoint = convert(view.frame, to: self)
            let screenMidY = bounds.maxY - bounds.midY
            let screenMidX = bounds.maxX - bounds.midX
            let offset = CGPoint(x: round(childPoint.midX - screenMidX), y: round(childPoint.midY - screenMidY))
            let currentOffset = CGPoint(x: round(contentOffset.x), y: round(contentOffset.y))
            return currentOffset == offset
        }
        else if contentSize == bounds.size {
            return true
        }
        return false
    }
    
}
