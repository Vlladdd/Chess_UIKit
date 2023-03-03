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
    
    private let storage = Storage.sharedInstance
    
    let userProgress = ProgressBar()
    
    // MARK: - Inits
    
    init(font: UIFont) {
        super.init(frame: .zero)
        setup(font: font)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup(font: UIFont) {
        setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let userRank = UILabel()
        userRank.setup(text: storage.currentUser.rank.asString, alignment: .center, font: font)
        userProgress.backgroundColor = constants.backgroundColorForProgressBar
        let currentUserRank = storage.currentUser.rank
        //how much percentage is filled
        userProgress.progress = CGFloat(storage.currentUser.points - currentUserRank.minimumPoints) / CGFloat(currentUserRank.maximumPoints - currentUserRank.minimumPoints)
        let userPoints = UILabel()
        userPoints.setup(text: String(storage.currentUser.points) + "/" + String(storage.currentUser.rank.maximumPoints), alignment: .center, font: font)
        addArrangedSubviews([userRank, userProgress, userPoints])
    }
    
}

// MARK: - Constants

private struct RankInfoView_Constants {
    static let optimalSpacing = 5.0
    static let backgroundColorForProgressBar = UIColor.white
}
