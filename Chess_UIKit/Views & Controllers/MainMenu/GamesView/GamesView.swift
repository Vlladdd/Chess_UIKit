//
//  GamesView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 08.02.2023.
//

import UIKit

// MARK: - GamesViewDelegate

protocol GamesViewDelegate: AnyObject {
    func gamesViewDidRemoveFromSuperview(_ gamesView: GamesView) -> Void
    func gamesViewDidChangeLayout(_ gamesView: GamesView) -> Void
}

// MARK: - GamesView

//class that represents games view
class GamesView: UIStackView {

    override func removeFromSuperview() {
        super.removeFromSuperview()
        delegate?.gamesViewDidRemoveFromSuperview(self)
    }
    
    // MARK: - Properties
    
    let isMultiplayerGames: Bool
    
    weak var delegate: GamesViewDelegate?
    
    private typealias constants = GamesView_Constants
    
    private let font: UIFont
    
    //for multiplayer
    private(set) var loadingSpinner: LoadingSpinner?
    
    private var reduntantGameViews = [MMGameInfoView]()
    
    // MARK: - Inits

    init(gamesInfo: [MMGameInfoView.Data], currentUserNickname: String, font: UIFont, isMultiplayerGames: Bool) {
        self.font = font
        self.isMultiplayerGames = isMultiplayerGames
        super.init(frame: .zero)
        setup(with: gamesInfo, and: currentUserNickname)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup(with gamesInfo: [MMGameInfoView.Data], and currentUserNickname: String) {
        setup(axis: .vertical, alignment: .fill, distribution: .fill, spacing: constants.optimalSpacing)
        let gamesViews = gamesInfo.sorted(by: {$0.startDate > $1.startDate}).map({MMGameInfoView(gameInfo: $0, font: font, currentUserNickname: currentUserNickname)})
        addArrangedSubviews(gamesViews)
        if isMultiplayerGames && gamesInfo.isEmpty {
            makeLoadingSpinner()
        }
    }
    
    func updateGameViews(with gamesInfo: [MMGameInfoView.Data], and currentUserNickname: String) {
        loadingSpinner?.removeFromSuperview()
        loadingSpinner = nil
        for gameView in arrangedSubviews.map({$0 as? MMGameInfoView}) {
            if let gameView {
                if !gamesInfo.contains(where: {$0.id == gameView.gameID}) {
                    gameView.makeUnavailable()
                    reduntantGameViews.append(gameView)
                }
            }
        }
        for gameInfo in gamesInfo {
            if !arrangedSubviews.contains(where: {
                if let gameID = ($0 as? MMGameInfoView)?.gameID {
                    return gameID == gameInfo.id
                }
                return false
            }) {
                let gameView = MMGameInfoView(gameInfo: gameInfo, font: font, currentUserNickname: currentUserNickname)
                //to prevent user randomly pressing on it, while it is animating
                gameView.isUserInteractionEnabled = false
                addArrangedSubview(gameView)
                UIView.animate(withDuration: constants.animationDuration, delay: 0, options: .allowUserInteraction, animations: { [weak self] in
                    guard let self else { return }
                    self.delegate?.gamesViewDidChangeLayout(self)
                }) { _ in
                    gameView.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    //we are not removing games straight away, cuz it will trigger scrolling,
    //when this view is inside UIScrollView, and it won`t be comfortable for the user
    func removeReduntantGameViews() {
        for gameView in reduntantGameViews {
            removeGameView(gameView)
        }
        reduntantGameViews = []
    }
    
    func removeGameView(_ gameView: MMGameInfoView) {
        NSLayoutConstraint.deactivate(gameView.constraints.filter({$0.firstItem === gameView || $0.secondItem === gameView}))
        gameView.heightAnchor.constraint(equalToConstant: 0).isActive = true
        UIView.animate(withDuration: constants.animationDuration, delay: 0, options: .allowUserInteraction, animations: { [weak self] in
            guard let self else { return }
            //there is a spacing in UIStackView
            //without this, it will remove gameView with glitch
            //we can also use default isHidden animation in UIStackView, but
            //by playing with constraints, it looks even better
            gameView.isHidden = true
            self.delegate?.gamesViewDidChangeLayout(self)
        }) { _ in
            gameView.removeFromSuperview()
        }
    }
    
    private func makeLoadingSpinner() {
        loadingSpinner = LoadingSpinner()
        if let loadingSpinner {
            addSubview(loadingSpinner)
            let loadingSpinnerConstraints = [loadingSpinner.leadingAnchor.constraint(equalTo: leadingAnchor), loadingSpinner.trailingAnchor.constraint(equalTo: trailingAnchor), loadingSpinner.topAnchor.constraint(equalTo: topAnchor), loadingSpinner.bottomAnchor.constraint(equalTo: bottomAnchor)]
            NSLayoutConstraint.activate(loadingSpinnerConstraints)
            if arrangedSubviews.isEmpty {
                let loadingSpinnerHeight = MMButtonView.getOptimalHeight(with: font.pointSize)
                loadingSpinner.heightAnchor.constraint(equalToConstant: loadingSpinnerHeight).isActive = true
            }
        }
    }
    
}

// MARK: - Constants

private struct GamesView_Constants {
    static let animationDuration = 0.5
    static let optimalSpacing = 5.0
}
