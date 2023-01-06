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
    private let wheelContainer = UIView()
    private let audioPlayer = AudioPlayer.sharedInstance
    
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
        figureView.contentMode = .scaleAspectFit
        var segmentAngleSize: CGFloat = 0
        var totalOcupiedSize: CGFloat = 0
        //making a circle with certain amount of segments
        while totalOcupiedSize < constants.circleDegrees {
            segmentAngleSize = CGFloat.random(in: constants.minumumAngleSize...constants.circleSize - totalOcupiedSize)
            //we need to have at least 2 segments
            if totalOcupiedSize == 0 {
                segmentAngleSize = CGFloat.random(in: constants.minumumAngleSize...constants.circleSize / constants.dividerForFirstSegmentSize)
            }
            var angle = segmentAngleSize + constants.gapSize
            totalOcupiedSize += angle
            if constants.circleDegrees - totalOcupiedSize < constants.minumumAngleSize + constants.gapSize {
                segmentAngleSize += (constants.circleDegrees - totalOcupiedSize)
                totalOcupiedSize += (constants.circleDegrees - totalOcupiedSize)
                angle = segmentAngleSize + constants.gapSize
            }
            let arcLayer = CAShapeLayer()
            arcLayer.fillColor = UIColor.clear.cgColor
            arcLayer.strokeColor = constants.defaultColorForSegment
            arcLayer.lineWidth = constants.lineWidth
            wheelContainer.layer.addSublayer(arcLayer)
            let coinsPrize = Int(CGFloat(maximumCoins) / angle)
            segmentsData.append(SegmentData(layer: arcLayer, angle: angle, coinsPrize: coinsPrize))
        }
        wheelContainer.translatesAutoresizingMaskIntoConstraints = false
        wheelContainer.addSubview(figureView)
        addSubviews([wheelContainer, coinsText])
        let figureConstrants = [wheelContainer.bottomAnchor.constraint(equalTo: coinsText.topAnchor, constant: -constants.distanceForCoins), wheelContainer.topAnchor.constraint(equalTo: topAnchor), wheelContainer.leadingAnchor.constraint(equalTo: leadingAnchor), wheelContainer.trailingAnchor.constraint(equalTo: trailingAnchor), figureView.widthAnchor.constraint(equalTo: wheelContainer.widthAnchor, multiplier: constants.dividerForFigureSize), figureView.heightAnchor.constraint(equalTo: wheelContainer.heightAnchor, multiplier: constants.dividerForFigureSize), figureView.centerXAnchor.constraint(equalTo: wheelContainer.centerXAnchor), figureView.centerYAnchor.constraint(equalTo: wheelContainer.centerYAnchor)]
        let coinsTextConstrants = [coinsText.centerXAnchor.constraint(equalTo: centerXAnchor), coinsText.bottomAnchor.constraint(equalTo: bottomAnchor)]
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
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: {[weak self] _ in
            if let self = self {
                if self.isVisible() {
                    self.audioPlayer.playSound(Sounds.toggleSound)
                }
                self.coinsText.text = String(segmentData.coinsPrize) + " coins"
                //changes stroke color of wheel segment
                segmentData.layer.updateStroke(to: constants.colorForWinnerSegment, animated: true, duration: constants.animationDuration)
                //rotates figure in middle of the wheel
                self.figureView.layer.rotate(from: startAngle, to: startAngle + segmentData.angle / angleModifier, animated: true, duration: animationDuration)
                if reverse {
                    let timerForReverse = Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: false, block: {_ in
                        segmentData.layer.updateStroke(to: constants.defaultColorForSegment, animated: true, duration: constants.animationDuration)
                    })
                    RunLoop.main.add(timerForReverse, forMode: .common)
                }
            }
        })
        RunLoop.main.add(timer, forMode: .common)
    }
    
    // MARK: - Draw
    
    override func layoutSubviews() {
        super.layoutSubviews()
        coinsText.font = UIFont.systemFont(ofSize: min(bounds.height, bounds.width) / constants.dividerForFont)
        let rect = wheelContainer.bounds
        let radius = min(rect.height, rect.width) / 2
        let center = CGPoint(x: rect.width / 2.0, y: rect.height / 2.0)
        var end: CGFloat = 0
        var firstSegment = true
        for segment in segmentsData {
            let start = firstSegment ? end : end + constants.gapSize
            firstSegment = false
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
    static let dividerForFont: CGFloat = 6
    static let animationDuration = 0.5
    static let gapSize: CGFloat = 0.020
    static let lineWidth: CGFloat = 20
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
    static let defaultColorForSegment = UIColor.red.cgColor
    static let colorForWinnerSegment = UIColor.green.cgColor
    static let rangeForLuckyNumbers = 1...100
    static let minimumSizeForLuckyAngle = 1.0
    //360 degress - gapSize
    static let circleSize = circleDegrees - gapSize
}
