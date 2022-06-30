//
//  PlayerFrame.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 29.06.2022.
//

import UIKit

//view that represents frame of the player
class PlayerFrame: UIView {
    
    // MARK: - Properties
    
    private let backgroundLayer = CAShapeLayer()
    private let textLayer = CAShapeLayer()
    private let frameLayer = CAShapeLayer()
    
    private var frameBorder = UIImageView()
    private var frameBackground = UIImageView()
    
    private typealias constants = PlayerFrame_Constants
    
    // MARK: - Inits
    
    convenience init(frame: CGRect, background: Backgrounds, playerFrame: Frames) {
        self.init(frame: frame)
        setup(background: background, playerFrame: playerFrame)
    }
    
    // MARK: - Methods
    
    private func createFrame(frame: CGRect) -> UIBezierPath {
        let height = frame.height
        let width = frame.width
        let path = UIBezierPath()
        path.move(to: CGPoint(x: constants.edgeSideLength, y: 0))
        path.addLine(to: CGPoint(x: width - constants.edgeSideLength, y: 0))
        path.addLine(to: CGPoint(x: width, y: height / 2))
        path.addLine(to: CGPoint(x: width - constants.edgeSideLength, y: height))
        path.addLine(to: CGPoint(x: constants.edgeSideLength, y: height))
        path.addLine(to: CGPoint(x: 0, y: height / 2))
        path.close()
        return path
    }
    
    private func setup(background: Backgrounds, playerFrame: Frames) {
        frameBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
        frameBorder = UIImageView(frame: CGRect(x: -constants.sizeForFrameBorder, y: -constants.sizeForFrameBorder, width: bounds.width + constants.sizeForFrameBorder * 2, height: bounds.height + constants.sizeForFrameBorder * 2))
        frameBorder.defaultSettings()
        frameBackground.defaultSettings()
        frameBorder.translatesAutoresizingMaskIntoConstraints = true
        frameBackground.translatesAutoresizingMaskIntoConstraints = true
        let path = createFrame(frame: frame).cgPath
        backgroundLayer.path = path
        textLayer.path = path
        frameLayer.path = createFrame(frame: frameBorder.frame).cgPath
        textLayer.fillColor = UIColor.white.withAlphaComponent(constants.alphaForTextBackground).cgColor
        let backgroundImage = UIImage(named: "backgrounds/\(background.rawValue)")
        let frameImage = UIImage(named: "frames/\(playerFrame.rawValue)")
        frameBackground.layer.mask = backgroundLayer
        frameBackground.image = backgroundImage
        frameBorder.layer.mask = frameLayer
        frameBorder.image = frameImage
        addSubview(frameBorder)
        addSubview(frameBackground)
        layer.addSublayer(textLayer)
    }
    
    func updateTextBackgroundColor(_ color: UIColor) {
        let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.fillColor))
        animation.fromValue = textLayer.fillColor
        animation.toValue = color.withAlphaComponent(constants.alphaForTextBackground).cgColor
        animation.duration = constants.animationDuration
        textLayer.fillColor = color.withAlphaComponent(constants.alphaForTextBackground).cgColor
        textLayer.add(animation, forKey: #keyPath(CAShapeLayer.fillColor))
    }
    
}

// MARK: - Constants

private struct PlayerFrame_Constants {
    static let edgeSideLength: CGFloat = 50
    static let alphaForTextBackground: CGFloat = 0.6
    static let animationDuration = 0.5
    static let sizeForFrameBorder: CGFloat = 10
}
