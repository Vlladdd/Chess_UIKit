//
//  WheelOfFortune.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.07.2022.
//

import UIKit

//view that represents Wheel Of Fortune
class WheelOfFortune: UIView {
    
    // MARK: - Properties
    
    private typealias constants = WheelOfFortune_Constants
    
    private var segmentsData = [SegmentData]()
    private var figuresTheme: FiguresThemes!
    private var maximumCoins: Int!
    
    private let coinsText = UILabel()
    private let figureView = UIImageView()
    
    private(set) var winCoins = 0
    
    // MARK: - Inits
    
    convenience init(figuresTheme: FiguresThemes, maximumCoins: Int) {
        self.init()
        self.figuresTheme = figuresTheme
        self.maximumCoins = maximumCoins
        setup()
    }
    
    // MARK: - Methods
    
    private func setup() {
        coinsText.setup(text: "0 coins", alignment: .center, font: UIFont.systemFont(ofSize: constants.defaultFontSize))
        let figureImage = UIImage(named: "figuresThemes/\(figuresTheme.rawValue)/black_bishop")
        figureView.defaultSettings()
        figureView.image = figureImage
        figureView.backgroundColor = constants.figureBackgroundColor
        figureView.layer.borderWidth = constants.figureBorderWidth
        var segmentAngleSize: CGFloat = 0
        var end: CGFloat = 0
        var totalOcupiedSize: CGFloat = 0
        //making a circle with certain amount of segments
        while totalOcupiedSize < constants.circleDegrees{
            segmentAngleSize = CGFloat.random(in: constants.minumumAngleSize...constants.circleSize - totalOcupiedSize)
            //we need to have at least 2 segments
            if totalOcupiedSize == 0 {
                segmentAngleSize = CGFloat.random(in: constants.minumumAngleSize...constants.circleSize / constants.dividerForFirstSegmentSize)
            }
            var angle = segmentAngleSize + constants.gapSize
            totalOcupiedSize += angle
            if constants.circleSize - totalOcupiedSize < constants.minumumAngleSize{
                segmentAngleSize += (constants.circleSize - totalOcupiedSize)
                totalOcupiedSize += (constants.circleDegrees - totalOcupiedSize)
                angle = segmentAngleSize + constants.gapSize
            }
            let start = end + constants.gapSize
            end = start + segmentAngleSize
            let arcLayer = CAShapeLayer()
            arcLayer.fillColor = UIColor.clear.cgColor
            arcLayer.strokeColor = constants.strokeColor
            arcLayer.lineWidth = constants.lineWidth
            layer.addSublayer(arcLayer)
            let coinsPrize = Int(CGFloat(maximumCoins) / angle)
            segmentsData.append(SegmentData(layer: arcLayer, angle: angle, coinsPrize: coinsPrize))
        }
        addSubview(figureView)
        addSubview(coinsText)
        let figureConstrants = [figureView.centerXAnchor.constraint(equalTo: centerXAnchor), figureView.centerYAnchor.constraint(equalTo: centerYAnchor), figureView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: constants.dividerForFigureSize), figureView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: constants.dividerForFigureSize)]
        let coinsTextConstrants = [coinsText.centerXAnchor.constraint(equalTo: centerXAnchor), coinsText.topAnchor.constraint(equalTo: bottomAnchor, constant: constants.distanceForCoins)]
        NSLayoutConstraint.activate(figureConstrants + coinsTextConstrants)
        if maximumCoins != 0 {
            spin()
        }
    }
    
    //spins the wheel
    private func spin() {
        var delay = constants.defaultDelay
        var spinsCount = Int.random(in: constants.spinsRange)
        let totalCount = spinsCount
        //we are starting from 45 degrees
        var totalDegrees: CGFloat = constants.startDegrees
        var winnerIndex = getWinnerIndex()
        //speed, if all segments are same size
        var avgSpeed = constants.totalSpeed / Double(segmentsData.count)
        //average size of segment
        let avgDegrees = constants.circleDegrees / Double(segmentsData.count)
        //this is used on last circle to slow even more
        var additionalSpeed = avgSpeed
        let winnerSegment = segmentsData[winnerIndex]
        winCoins = winnerSegment.coinsPrize
        //we want to stop somewhere on the winner segment
        let angleModifier = Double.random(in: constants.minimumAngleModifier...constants.minimumAngleModifier + winnerSegment.angle)
        while spinsCount > 0 {
            if spinsCount != 1 {
                for segmentData in segmentsData {
                    var speed = avgSpeed * (segmentData.angle / avgDegrees)
                    //if winner segment is, for example, first, we need to slow down not on the last spin,
                    //but before that
                    if winnerIndex <= segmentsData.count / constants.dividerToSlowSpeed && spinsCount == constants.spinsForThirdSpeed {
                        speed = avgSpeed * (segmentData.angle / avgDegrees) + additionalSpeed * (segmentData.angle / avgDegrees)
                        additionalSpeed += avgSpeed
                    }
                    segmentAnimation(segmentData: segmentData, delay: delay, animationDuration: speed, startAngle: totalDegrees)
                    totalDegrees += segmentData.angle
                    delay += speed
                }
            }
            //last spin
            else {
                for segmentData in segmentsData[0..<winnerIndex] {
                    let speed = avgSpeed * (segmentData.angle / avgDegrees) + additionalSpeed * (segmentData.angle / avgDegrees)
                    segmentAnimation(segmentData: segmentData, delay: delay, animationDuration: speed, startAngle: totalDegrees)
                    totalDegrees += segmentData.angle
                    delay += speed
                    additionalSpeed += avgSpeed
                }
                //we need to get speed of segment, which is before winner segment
                if winnerIndex == 0 {
                    winnerIndex = segmentsData.count - 1
                }
                //even more slow down for winner segment
                let speed = avgSpeed * (segmentsData[winnerIndex - 1].angle / avgDegrees) + (additionalSpeed * (winnerSegment.angle / avgDegrees)) * constants.additionalMultiplierForSpeed
                //animation for winner segment
                segmentAnimation(segmentData: winnerSegment, delay: delay, animationDuration: speed, startAngle: totalDegrees, reverse: false, angleModifier: angleModifier)
            }
            //as we go closer to last spin, we slow down
            if spinsCount == totalCount / constants.dividerForSecondSpeed {
                avgSpeed *= constants.multiplierForSecondSpeed
            }
            if spinsCount == constants.spinsForThirdSpeed {
                avgSpeed *= constants.multiplierForThirdSpeed
            }
            spinsCount -= 1
        }
    }
    
    //method for low chance of small segments
    private func getWinnerIndex() -> Int{
        let chance = Int.random(in: constants.rangeForLuckyNumbers)
        var luckyNumbers = [Int]()
        var luckyIndexes = [Int]()
        var unluckyIndexes = [Int]()
        for segmentData in segmentsData {
            luckyNumbers.append(Int.random(in: constants.rangeForLuckyNumbers))
            if let index = segmentsData.firstIndex(of: segmentData) {
                if segmentData.angle < constants.minimumSizeForLuckyAngle {
                    luckyIndexes.append(index)
                }
                else {
                    unluckyIndexes.append(index)
                }
            }
        }
        var winnerIndex = 0
        if (luckyNumbers.contains(chance) && !luckyIndexes.isEmpty) || (unluckyIndexes.isEmpty && !luckyIndexes.isEmpty) {
            winnerIndex = luckyIndexes.randomElement()!
        }
        else if !unluckyIndexes.isEmpty {
            winnerIndex = unluckyIndexes.randomElement()!
        }
        return winnerIndex
    }
    
    private func segmentAnimation(segmentData: SegmentData, delay: Double, animationDuration: Double, startAngle: CGFloat, reverse: Bool = true, angleModifier: Double = constants.defaultAngleModifier) {
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: {[weak self] _ in
            if let self = self {
                self.coinsText.text = String(segmentData.coinsPrize) + " coins"
                self.strokeAnimation(for: segmentData.layer, to: constants.colorForWinnerSegment)
                self.rotateAnimation(from: startAngle, to: startAngle + segmentData.angle / angleModifier, with: animationDuration)
                if reverse {
                    Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: false, block: {_ in
                        self.strokeAnimation(for: segmentData.layer, to: constants.defaultColorForSegment)
                    })
                }
            }
        })
    }
    
    //changes stroke color of wheel segment
    private func strokeAnimation(for layer: CAShapeLayer, to color: UIColor) {
        let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeColor))
        animation.fromValue = layer.strokeColor
        animation.toValue = color.cgColor
        animation.duration = constants.animationDuration
        layer.strokeColor = color.cgColor
        layer.add(animation, forKey: #keyPath(CAShapeLayer.strokeColor))
    }
    
    //rotates figure in middle of the wheel
    private func rotateAnimation(from startAngle: CGFloat, to endAngle: CGFloat, with animationDuration: Double) {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = startAngle
        rotationAnimation.toValue = endAngle
        rotationAnimation.duration = animationDuration
        figureView.layer.transform = CATransform3DMakeRotation(endAngle, 0.0, 0.0, 1.0)
        figureView.layer.add(rotationAnimation, forKey: nil)
    }
    
    // MARK: - Draw
    
    override func draw(_ rect: CGRect) {
        let radius = rect.width / 2
        coinsText.font = UIFont.systemFont(ofSize: radius / constants.dividerForFont)
        let center = CGPoint(x: rect.width / 2.0, y: rect.height / 2.0)
        var end: CGFloat = 0
        for segment in segmentsData {
            let start = end + constants.gapSize
            end = start + segment.angle - constants.gapSize
            let segmentPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: start, endAngle: end, clockwise: true)
            segment.layer.path = segmentPath.cgPath
        }
    }
    
}

// MARK: - Constants

private struct WheelOfFortune_Constants {
    //in case if you need hardcoded font size value, but if not, that
    //font value is calculated in draw method
    static let defaultFontSize = 0.0
    static let figureBackgroundColor = UIColor.clear
    static let figureBorderWidth = 0.0
    static let dividerForFirstSegmentSize = 2.0
    static let circleDegrees = 2.0 * CGFloat.pi
    static let spinsRange = 2...20
    static let defaultDelay = 0.1
    static let distanceForCoins: CGFloat = 30
    static let dividerForFont: CGFloat = 3
    static let animationDuration = 0.5
    static let gapSize: CGFloat = 0.020
    static let lineWidth: CGFloat = 20
    static let strokeColor = UIColor.red.cgColor
    static let minumumAngleSize: CGFloat = 0.1
    static let startDegrees = CGFloat.pi / 2
    static let totalSpeed = 1.0
    static let dividerForFigureSize = 0.5
    static let defaultAngleModifier = 1.0
    static let minimumAngleModifier = 1.1
    static let dividerToSlowSpeed = 2
    static let additionalMultiplierForSpeed = 2.0
    static let dividerForSecondSpeed = 2
    static let spinsForThirdSpeed = 2
    static let multiplierForSecondSpeed = 1.5
    static let multiplierForThirdSpeed = 2.0
    static let defaultColorForSegment = UIColor.red
    static let colorForWinnerSegment = UIColor.green
    static let rangeForLuckyNumbers = 1...100
    static let minimumSizeForLuckyAngle = 1.0
    //360 degress - gapSize
    static let circleSize = circleDegrees - gapSize
}
