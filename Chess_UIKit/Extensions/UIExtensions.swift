//
//  UIExtensions.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 13.06.2022.
//

import UIKit

// MARK: - Some useful UI extensions

extension UIViewController {
    
    func configureKeyboardToHideWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func showTextInputPrompt(withMessage message: String, completionBlock: @escaping ((Bool, String?) -> Void)) {
        let prompt = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionBlock(false, nil)
        }
        weak var weakPrompt = prompt
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard let text = weakPrompt?.textFields?.first?.text else { return }
            completionBlock(true, text)
        }
        prompt.addTextField(configurationHandler: nil)
        prompt.addAction(cancelAction)
        prompt.addAction(okAction)
        present(prompt, animated: true, completion: nil)
    }
    
}

extension UIApplication {

    class func getTopMostViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter{$0.isKeyWindow}.first
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController, !presentedViewController.isBeingDismissed {
                topController = presentedViewController
            }
            return topController
        }
        else {
            return nil
        }
    }
    
}

extension UISwitch {
    
    @objc private func playToggleSound(_ sender: UISwitch? = nil) {
        AudioPlayer.sharedInstance.playSound(Sounds.toggleSound)
    }
    
    func defaultSettings(with function: Selector? = nil, isOn: Bool = true) {
        translatesAutoresizingMaskIntoConstraints = false
        self.isOn = isOn
        set(offTint: Constants.offTintColor)
        if let function = function {
            addTarget(nil, action: function, for: .valueChanged)
        }
        addTarget(nil, action: #selector(playToggleSound), for: .valueChanged)
    }

    func set(offTint color: UIColor ) {
        let minSide = min(bounds.size.height, bounds.size.width)
        layer.cornerRadius = minSide / 2
        backgroundColor = color
        tintColor = color
    }
    
    private struct Constants {
        static let offTintColor = UIColor.red
    }
    
}

extension UIView {
    
    var rootView: UIView {
        superview?.rootView ?? self
    }
    
    func rotate360Degrees(duration: CFTimeInterval = 3) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi * 2)
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = Float.infinity
        layer.add(rotateAnimation, forKey: nil)
    }
    
    func setAnchorPoint(_ point: CGPoint) {
        var newPoint = CGPoint(x: bounds.size.width * point.x, y: bounds.size.height * point.y)
        var oldPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y);
        newPoint = newPoint.applying(transform)
        oldPoint = oldPoint.applying(transform)
        var position = layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        position.y -= oldPoint.y
        position.y += newPoint.y
        layer.position = position
        layer.anchorPoint = point
    }
    
    func addSubviews(_ views: [UIView]) {
        for view in views {
            addSubview(view)
        }
    }
    
    func isVisible() -> Bool {
        if window == nil {
            return false
        }
        var currentView = self
        while let superview = currentView.superview {
            if (superview.bounds).intersects(currentView.frame) == false {
                return false
            }
            if currentView.isHidden {
                return false
            }
            if currentView.alpha == 0 {
                return false
            }
            currentView = superview
        }
        return true
    }
    
}

extension UIButton {
    
    func buttonWith(imageItem: ImageItem? = nil, text: String? = nil, font: UIFont? = nil, and function: Selector) {
        translatesAutoresizingMaskIntoConstraints = false
        isExclusiveTouch = true
        addTarget(nil, action: function, for: .touchUpInside)
        if let imageItem {
            var image: UIImage?
            if let imageItem = imageItem as? SystemImages {
                image = UIImage(systemName: imageItem.getSystemName())
            }
            else if let imagePath = imageItem.getFullPath() {
                image = UIImage(named: "\(imagePath)")
            }
            if let image {
                setImage(image, for: .normal)
                settingsForButtonWithImage()
            }
        }
        setTitle(text, for: .normal)
        titleLabel?.textAlignment = .center
        titleLabel?.font = font
        titleLabel?.adjustsFontSizeToFitWidth = true
    }
    
    func setImage(with imageItem: ImageItem) {
        if let imageItem = imageItem as? SystemImages {
            setImage(UIImage(systemName: imageItem.getSystemName()), for: .normal)
        }
        else if let imagePath = imageItem.getFullPath() {
            setImage(UIImage(named: imagePath), for: .normal)
        }
        settingsForButtonWithImage()
    }
    
    private func settingsForButtonWithImage() {
        contentVerticalAlignment = .fill
        contentHorizontalAlignment = .fill
        imageView?.contentMode = .scaleAspectFit
    }
    
    func compareCurrentImageTo(_ imageItem: ImageItem) -> Bool {
        if let imageItem = imageItem as? SystemImages {
            return currentImage == UIImage(systemName: imageItem.getSystemName())
        }
        else if let imagePath = imageItem.getFullPath() {
            return currentImage == UIImage(named: imagePath)
        }
        return false
    }
    
}

extension UITextField {
    
    func setup(placeholder: String, font: UIFont) {
        translatesAutoresizingMaskIntoConstraints = false
        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor : Constants.placeholderColor])
        layer.cornerRadius = Constants.cornerRadius
        layer.borderWidth = Constants.borderWidth
        backgroundColor = Constants.backgroundColor
        self.font = font
        adjustsFontSizeToFitWidth = true
        if traitCollection.userInterfaceStyle == .dark {
            layer.borderColor = Constants.darkModeBorderColor
        }
        else {
            layer.borderColor = Constants.lightModeBorderColor
        }
    }
    
    private struct Constants {
        static let backgroundColor = UIColor.clear
        static let cornerRadius: CGFloat = 10
        static let borderWidth: CGFloat = 1
        static let optimalAlpha = 0.5
        static let placeholderColor = UIColor.red.withAlphaComponent(optimalAlpha)
        static let darkModeBorderColor = UIColor.white.cgColor
        static let lightModeBorderColor = UIColor.black.cgColor
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
    
    func addArrangedSubviews(_ views: [UIView]) {
        for view in views {
            addArrangedSubview(view)
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
    
    func labelWithBorderAndCornerRadius() {
        layer.borderWidth = Constants.borderWidth
        layer.cornerRadius = Constants.cornerRadius
        if traitCollection.userInterfaceStyle == .dark {
            layer.borderColor = Constants.darkModeBorderColor
        }
        else {
            layer.borderColor = Constants.lightModeBorderColor
        }
    }
    
    //custom adjustFontSizeToFitWidth, which can be beautifully animated
    //i am not using it now, but may come in handy in future
    func updateFontSizeToFitSuperview() {
        if let superview = superview {
            let fontSize = getFontSizeToFitRect(superview.bounds)
            if fontSize > 0 && font.pointSize > 0 {
                transform = CGAffineTransform(scaleX: fontSize/font.pointSize , y: fontSize/font.pointSize)
            }
        }
    }
    
    private func getFontSizeToFitRect(_ rect: CGRect) -> CGFloat {
        var currentFont = UIFont.systemFont(ofSize: font.pointSize)
        if let text = text, rect.size.width > 0 && rect.size.height > 0 {
            var initialSize : CGSize = text.size(withAttributes: [NSAttributedString.Key.font : currentFont])
            if initialSize.width > rect.size.width || initialSize.height > rect.size.height {
                while initialSize.width > rect.size.width || initialSize.height > rect.size.height {
                    currentFont = currentFont.withSize(currentFont.pointSize - 1)
                    initialSize = text.size(withAttributes: [NSAttributedString.Key.font : currentFont])
                }
            }
            else {
                while initialSize.width < rect.size.width && initialSize.height < rect.size.height {
                    currentFont = currentFont.withSize(currentFont.pointSize + 1)
                    initialSize = text.size(withAttributes: [NSAttributedString.Key.font : currentFont])
                }
                //went 1 point too large so compensate here
                currentFont = currentFont.withSize(currentFont.pointSize - 1)
            }
            return currentFont.pointSize
        }
        return .zero
    }
    
    private struct Constants {
        static let cornerRadius: CGFloat = 10
        static let borderWidth: CGFloat = 1
        static let darkModeTextColor = UIColor.white
        static let lightModeTextColor = UIColor.black
        static let darkModeBorderColor = UIColor.white.cgColor
        static let lightModeBorderColor = UIColor.black.cgColor
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
    
    //when imageView is used as background of the button
    func settingsForBackgroundOfTheButton(cornerRadius: CGFloat) {
        backgroundColor = .clear
        layer.cornerRadius = cornerRadius
        isUserInteractionEnabled = true
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
    
    func setImage(with imageItem: ImageItem, upsideDown: Bool = false) {
        if let imageItem = imageItem as? SystemImages {
            image = UIImage(systemName: imageItem.getSystemName())
        }
        else if let imagePath = imageItem.getFullPath() {
            image = UIImage(named: imagePath)
        }
        if upsideDown {
            rotateImageOn90()
        }
    }
    
    func rotateImageOn90() {
        rotateImage(on: .pi)
    }
    
    func rotateImage(on radians: Float) {
        image = image?.rotate(radians: radians)
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

extension UIStepper {
    
    @objc private func playToggleSound(_ sender: UISwitch? = nil) {
        AudioPlayer.sharedInstance.playSound(Sounds.toggleSound)
    }
    
    func stepperWith(minValue: Double, maxValue: Double, stepValue: Double, and action: Selector) {
        translatesAutoresizingMaskIntoConstraints = false
        wraps = true
        addTarget(nil, action: #selector(playToggleSound), for: .valueChanged)
        addTarget(nil, action: action, for: .valueChanged)
        minimumValue = minValue
        maximumValue = maxValue
        self.stepValue = stepValue
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
    
    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return self
        }
    }
    
    //used for background of toolbar
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
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
            let childPoint = content.convert(view.frame, to: self)
            let screenMidY = bounds.maxY - bounds.midY
            let screenMidX = bounds.maxX - bounds.midX
            setContentOffset(CGPoint(x: childPoint.midX - screenMidX, y: childPoint.midY - screenMidY), animated: animated)
        }
    }
    
    func checkIfViewInCenterOfTheScreen(view: UIView) -> Bool {
        if let content = subviews.first, content.subviews.contains(view) {
            let childPoint = content.convert(view.frame, to: self)
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
