//
//  GamesView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 08.02.2023.
//

import UIKit

//class that represents games view
class GamesView: UIStackView, MPGamesDelegate {

    override func removeFromSuperview() {
        super.removeFromSuperview()
        searchingForMPgames?.cancel()
    }
    
    // MARK: - MPGamesDelegate
    
    var searchingForMPgames: Task<Void, Error>?
    
    func makeAdditionalButtons() -> AdditionalButtons {
        if let delegate {
            return ABBuilder(delegate: delegate)
                .addBackButton(type: .toGameMenu)
                .build()
        }
        else {
            fatalError("delegate is nil")
        }
    }
    
    // MARK: - Properties
    
    weak var delegate: MainMenuViewDelegate?
    
    private typealias constants = GamesView_Constants
    
    private let storage = Storage.sharedInstance
    
    private var games: [GameLogic] = []
    
    // MARK: - Inits
    
    //when games is nil, it is for multiplayer
    init(games: [GameLogic]?, delegate: MainMenuViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        if let games {
            self.games = games
        }
        else {
            searchForMPGames()
        }
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup() {
        if let delegate {
            setup(axis: .vertical, alignment: .fill, distribution: .fill, spacing: constants.optimalSpacing)
            let gamesViews = games.sorted(by: {$0.startDate > $1.startDate}).map({GameView(game: $0, mainMenuViewDelegate: delegate)})
            for gameView in gamesViews {
                gameView.mpGamesDelegate = self
            }
            addArrangedSubviews(gamesViews)
        }
    }
    
    private func searchForMPGames() {
        if let delegate {
            searchingForMPgames = Task {
                do {
                    for try await games in storage.getMultiplayerGames() {
                        updateGames(with: games)
                    }
                }
                catch {
                    delegate.mainMenuDelegate?.makeErrorAlert(with: error.localizedDescription)
                    let gameButtons = MMGameButtons(delegate: delegate)
                    delegate.makeMenu(with: gameButtons, reversed: true)
                }
            }
        }
    }
    
    private func updateGames(with games: [GameLogic]) {
        if let delegate {
            for gameView in arrangedSubviews.map({$0 as? GameView}) {
                if let gameView {
                    if !games.contains(where: {$0.gameID == gameView.game.gameID}) {
                        UIView.animate(withDuration: constants.animationDuration, animations: {
                            gameView.isHidden = true
                        }) { _ in
                            gameView.removeFromSuperview()
                        }
                    }
                }
            }
            for game in games {
                if !arrangedSubviews.contains(where: {
                    if let gameToCompare = ($0 as? GameView)?.game {
                        return gameToCompare.gameID == game.gameID
                    }
                    return false
                }) {
                    let gameView = GameView(game: game, mainMenuViewDelegate: delegate)
                    gameView.mpGamesDelegate = self
                    addArrangedSubview(gameView)
                    UIView.animate(withDuration: constants.animationDuration, animations: {
                        delegate.mainMenuDelegate?.view.layoutIfNeeded()
                    })
                }
            }
            self.games = games
        }
    }
    
}

// MARK: - Constants

private struct GamesView_Constants {
    static let animationDuration = 0.5
    static let optimalSpacing = 5.0
}
