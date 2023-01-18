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
    //it is used to make data look better and to show current player
    private let dataBackgroundLayer = CAShapeLayer()
    private let frameLayer = CAShapeLayer()
    private let frameBackground = UIImageView()
    //second background for actual frame
    private let frameBorder = UIImageView()
    private let dataBackgroundView = UIView()
    private let borderForFrame = CAShapeLayer()
    private let borderForData = CAShapeLayer()
    
    private var data: UIView!
    private var background: Backgrounds!
    private var playerFrame: Frames!
    
    private typealias constants = PlayerFrame_Constants
    
    // MARK: - Inits
    
    convenience init(background: Backgrounds, playerFrame: Frames, data: UIView) {
        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
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
        path.move(to: CGPoint(x: size.minX + constants.edgeSideLength, y: size.minY))
        path.addLine(to: CGPoint(x: size.minX + width - constants.edgeSideLength, y: size.minY))
        path.addLine(to: CGPoint(x: size.minX + width, y: size.minY + height / constants.dividerForHeightInShape))
        path.addLine(to: CGPoint(x: size.minX + width - constants.edgeSideLength, y: size.minY + height))
        path.addLine(to: CGPoint(x: size.minX + constants.edgeSideLength, y: size.minY + height))
        path.addLine(to: CGPoint(x: size.minX, y: size.minY + height / constants.dividerForHeightInShape))
        path.close()
        return path
    }
    
    private func setup() {
        configureBorderLayer(borderForFrame)
        configureBorderLayer(borderForData)
        if let data = data as? UILabel {
            //for proper animation, when label and his font changing size
            data.contentMode = .scaleAspectFit
            data.baselineAdjustment = .alignCenters
        }
        dataBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        frameBorder.defaultSettings()
        frameBackground.defaultSettings()
        let backgroundColorForData = traitCollection.userInterfaceStyle == .dark ? constants.defaultDarkModeColorForDataBackground : constants.defaultLightModeColorForDataBackground
        dataBackgroundView.backgroundColor = backgroundColorForData
        frameBackground.setImage(with: background)
        frameBorder.setImage(with: playerFrame)
        addSubviews([frameBorder, frameBackground, dataBackgroundView, data])
        let constraints = [data.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: constants.distanceForTextInFrame), data.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -constants.distanceForTextInFrame), data.centerXAnchor.constraint(equalTo: centerXAnchor), data.centerYAnchor.constraint(equalTo: centerYAnchor), frameBackground.widthAnchor.constraint(equalTo: widthAnchor), frameBackground.heightAnchor.constraint(equalTo: heightAnchor), frameBorder.widthAnchor.constraint(equalTo: widthAnchor), frameBorder.heightAnchor.constraint(equalTo: heightAnchor), frameBorder.centerXAnchor.constraint(equalTo: centerXAnchor), frameBorder.centerYAnchor.constraint(equalTo: centerYAnchor), dataBackgroundView.heightAnchor.constraint(equalTo: heightAnchor), dataBackgroundView.widthAnchor.constraint(equalTo: widthAnchor), frameBackground.centerXAnchor.constraint(equalTo: centerXAnchor), frameBackground.centerYAnchor.constraint(equalTo: centerYAnchor), dataBackgroundView.centerXAnchor.constraint(equalTo: centerXAnchor), dataBackgroundView.centerYAnchor.constraint(equalTo: centerYAnchor)]
        NSLayoutConstraint.activate(constraints)
        frameBackground.layer.mask = backgroundLayer
        frameBorder.layer.mask = frameLayer
        frameBorder.layer.addSublayer(borderForFrame)
        dataBackgroundView.layer.mask = dataBackgroundLayer
        dataBackgroundView.layer.addSublayer(borderForData)
    }
    
    private func configureBorderLayer(_ layer: CAShapeLayer) {
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = traitCollection.userInterfaceStyle == .dark ? constants.defaultLightModeColorForDataBackground.cgColor : constants.defaultDarkModeColorForDataBackground.cgColor
        layer.lineWidth = constants.borderWidth
    }
    
    //when switching current player
    func updateDataBackgroundColor(_ color: UIColor) {
        dataBackgroundView.backgroundColor = color
    }
    
    // MARK: - Draw
    
    override func draw(_ rect: CGRect) {
        //in other words we have 2 backgrounds, second is bigger then first a little bit
        //and in this way he looks like a frame
        let dataRect = CGRect(x: constants.startXInData, y: constants.startYInData, width: rect.width - constants.additionalSizeForFrameBorder, height: rect.height - constants.additionalSizeForFrameBorder)
        let dataPath = createPlayerFrameShape(with: dataRect).cgPath
        let frameRect = CGRect(x: constants.startXInFrame, y: constants.startYInFrame, width: rect.width, height: rect.height)
        let framePath = createPlayerFrameShape(with: frameRect).cgPath
        backgroundLayer.updatePath(with: dataPath, animated: true, duration: constants.animationDuration)
        dataBackgroundLayer.updatePath(with: dataPath, animated: true, duration: constants.animationDuration)
        frameLayer.updatePath(with: framePath, animated: true, duration: constants.animationDuration)
        borderForFrame.updatePath(with: framePath, animated: true, duration: constants.animationDuration)
        borderForData.updatePath(with: dataPath, animated: true, duration: constants.animationDuration)
    }
    
}

// MARK: - Constants

private struct PlayerFrame_Constants {
    static let borderWidth: CGFloat = 3
    static let startXInFrame: CGFloat = 0
    static let startYInFrame: CGFloat = 0
    static let dividerForHeightInShape: CGFloat = 2
    static let edgeSideLength: CGFloat = 50
    static let alphaForDataBackground: CGFloat = 0.5
    static let animationDuration = 0.5
    static let additionalSizeForFrameBorder: CGFloat = 20
    static let dividerForFont: CGFloat = 13
    static let distanceForTextInFrame: CGFloat = 30
    static let startXInData: CGFloat = startXInFrame + (additionalSizeForFrameBorder / dividerForHeightInShape)
    static let startYInData: CGFloat = startYInFrame + (additionalSizeForFrameBorder / dividerForHeightInShape)
    static let defaultLightModeColorForDataBackground = UIColor.white.withAlphaComponent(alphaForDataBackground)
    static let defaultDarkModeColorForDataBackground = UIColor.black.withAlphaComponent(alphaForDataBackground)
}
