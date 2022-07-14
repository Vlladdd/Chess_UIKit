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
    //it is used to make text look better and to show current player
    private let textLayer = CAShapeLayer()
    private let frameLayer = CAShapeLayer()
    private let frameBackground = UIImageView()
    //second background for actual frame
    private let frameBorder = UIImageView()
    
    private var data: UIView!
    private var background: Backgrounds!
    private var playerFrame: Frames!
    
    private typealias constants = PlayerFrame_Constants
    
    // MARK: - Inits
    
    convenience init(background: Backgrounds, playerFrame: Frames, data: UIView) {
        self.init()
        self.background = background
        self.playerFrame = playerFrame
        self.data = data
        setup()
    }
    
    // MARK: - Methods
    
    //custom shape for frame
    private func createPlayerFrameShape(with size: CGRect) -> UIBezierPath {
        let height = size.height
        let width = size.width
        let path = UIBezierPath()
        path.move(to: CGPoint(x: constants.edgeSideLength, y: constants.startYInShape))
        path.addLine(to: CGPoint(x: width - constants.edgeSideLength, y: constants.startYInShape))
        path.addLine(to: CGPoint(x: width, y: height / constants.dividerForHeightInShape))
        path.addLine(to: CGPoint(x: width - constants.edgeSideLength, y: height))
        path.addLine(to: CGPoint(x: constants.edgeSideLength, y: height))
        path.addLine(to: CGPoint(x: constants.startXInShape, y: height / constants.dividerForHeightInShape))
        path.close()
        return path
    }
    
    private func setup() {
        textLayer.masksToBounds = true
        frameBorder.defaultSettings()
        frameBackground.defaultSettings()
        textLayer.fillColor = constants.defaultColorForTextBackground
        let backgroundImage = UIImage(named: "backgrounds/\(background.rawValue)")
        let frameImage = UIImage(named: "frames/\(playerFrame.rawValue)")
        frameBackground.image = backgroundImage
        frameBorder.image = frameImage
        addSubview(frameBorder)
        addSubview(frameBackground)
        layer.addSublayer(textLayer)
        addSubview(data)
        let constraints = [data.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: constants.distanceForTextInFrame), data.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -constants.distanceForTextInFrame), data.centerXAnchor.constraint(equalTo: centerXAnchor), data.centerYAnchor.constraint(equalTo: centerYAnchor), frameBackground.widthAnchor.constraint(equalTo: widthAnchor), frameBackground.heightAnchor.constraint(equalTo: heightAnchor), frameBorder.widthAnchor.constraint(equalTo: widthAnchor, constant: constants.additionalSizeForFrameBorder), frameBorder.heightAnchor.constraint(equalTo: heightAnchor, constant: constants.additionalSizeForFrameBorder), frameBorder.centerXAnchor.constraint(equalTo: centerXAnchor), frameBorder.centerYAnchor.constraint(equalTo: centerYAnchor)]
        NSLayoutConstraint.activate(constraints)
        frameBackground.layer.mask = backgroundLayer
        frameBorder.layer.mask = frameLayer
    }
    
    //when switching current player
    func updateTextBackgroundColor(_ color: UIColor) {
        let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.fillColor))
        animation.fromValue = textLayer.fillColor
        animation.toValue = color.withAlphaComponent(constants.alphaForTextBackground).cgColor
        animation.duration = constants.animationDuration
        textLayer.fillColor = color.withAlphaComponent(constants.alphaForTextBackground).cgColor
        textLayer.add(animation, forKey: #keyPath(CAShapeLayer.fillColor))
    }
    
    // MARK: - Draw
    
    override func draw(_ rect: CGRect) {
        textLayer.frame = rect
        //in other words we have 2 backgrounds, second is bigger then first a little bit
        //and in this way he looks like a frame
        let frameRect = CGRect(x: constants.startXInFrame, y: constants.startYInFrame, width: rect.width + constants.additionalSizeForFrameBorder, height: rect.height + constants.additionalSizeForFrameBorder)
        let path = createPlayerFrameShape(with: rect).cgPath
        backgroundLayer.path = path
        textLayer.path = path
        frameLayer.path = createPlayerFrameShape(with: frameRect).cgPath
    }
    
}

// MARK: - Constants

private struct PlayerFrame_Constants {
    static let startXInShape: CGFloat = 0
    static let startYInShape: CGFloat = 0
    static let dividerForHeightInShape: CGFloat = 2
    static let edgeSideLength: CGFloat = 50
    static let alphaForTextBackground: CGFloat = 0.6
    static let animationDuration = 0.5
    static let additionalSizeForFrameBorder: CGFloat = 20
    static let dividerForFont: CGFloat = 13
    static let distanceForTextInFrame: CGFloat = 30
    static let startXInFrame: CGFloat = startXInShape - (additionalSizeForFrameBorder / dividerForHeightInShape)
    static let startYInFrame: CGFloat = startYInShape - (additionalSizeForFrameBorder / dividerForHeightInShape)
    static let defaultColorForTextBackground = UIColor.white.withAlphaComponent(alphaForTextBackground).cgColor
}
