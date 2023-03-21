//
//  RankInfoView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

//class that represents view with info about user rank
class RankInfoView: UIStackView {
    
    // MARK: - Properties
    
    private typealias constants = RankInfoView_Constants
    
    private let userProgress = ProgressBar()
    
    // MARK: - Inits
    
    init(font: UIFont, rank: Ranks, currentPoints: Int) {
        super.init(frame: .zero)
        setup(with: font, rank: rank, currentPoints: currentPoints)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup(with font: UIFont, rank: Ranks, currentPoints: Int) {
        setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let userRank = UILabel()
        userRank.setup(text: rank.asString, alignment: .center, font: font)
        userProgress.backgroundColor = constants.backgroundColorForProgressBar
        //how much percentage is filled
        userProgress.progress = CGFloat(currentPoints - rank.minimumPoints) / CGFloat(rank.maximumPoints - rank.minimumPoints)
        let userPoints = UILabel()
        userPoints.setup(text: String(currentPoints) + "/" + String(rank.maximumPoints), alignment: .center, font: font)
        addArrangedSubviews([userRank, userProgress, userPoints])
    }
    
    func onRotate() {
        userProgress.setNeedsDisplay()
    }
    
}

// MARK: - Constants

private struct RankInfoView_Constants {
    static let optimalSpacing = 5.0
    static let backgroundColorForProgressBar = UIColor.white
}
