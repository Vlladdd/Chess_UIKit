//
//  ProgressBar.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.07.2022.
//

import UIKit

//view that represents custom progress bar
class ProgressBar: UIView {
    
    // MARK: - Properties
    
    var progressColor: UIColor = constants.defaultProgressColor {
        didSet {
            setNeedsDisplay()
        }
    }
    var progress: CGFloat = constants.defaultProgressValue {
        didSet {
            if progress == 1 || progress == 0 {
                backgroundColor = progressColor
                progressColor = .random()
            }
            setNeedsDisplay()
        }
    }

    private let progressLayer = CALayer()
    private let backgroundMask = CAShapeLayer()
    
    private typealias constants = ProgressBar_Constants

    // MARK: - Inits
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Methods
    
    func reset() {
        progress = 0
    }
    
    func fill() {
        progress = 1
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.addSublayer(progressLayer)
        layer.mask = backgroundMask
    }
    
    // MARK: - Draw

    override func draw(_ rect: CGRect) {
        let newPath = UIBezierPath(roundedRect: rect, cornerRadius: rect.height * constants.multiplierForCornerRadius).cgPath
        backgroundMask.updatePath(with: newPath, animated: true, duration: constants.animationDuration)
        let progressRect = CGRect(origin: .zero, size: CGSize(width: rect.width * progress, height: rect.height))
        progressLayer.frame = progressRect
        progressLayer.backgroundColor = progressColor.cgColor
    }
    
}

// MARK: - Constants

private struct ProgressBar_Constants {
    static let defaultProgressColor = UIColor.gray
    static let defaultProgressValue = 0.0
    static let multiplierForCornerRadius = 0.25
    static let animationDuration = 0.5
}
