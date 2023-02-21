//
//  User.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 10.09.2022.
//

import Foundation

//struct that represents user
struct User: Codable {
    
    // MARK: - Properties
    
    //no-internet mode
    private(set) var guestMode: Bool = false
    private(set) var musicEnabled = true
    private(set) var soundsEnabled = true
    private(set) var nickname: String
    private(set) var email: String
    private(set) var squaresTheme: SquaresThemes = .defaultTheme
    private(set) var playerAvatar: Avatars = .defaultAvatar
    //background of player trash, rank and name
    private(set) var playerBackground: Backgrounds = .defaultBackground
    private(set) var frame: Frames = .defaultFrame
    private(set) var figuresTheme: FiguresThemes = .defaultTheme
    private(set) var boardTheme: BoardThemes = .defaultTheme
    private(set) var coins: Int = 0
    private(set) var points: Int = 0 {
        didSet {
            if points < 0 {
                points = 0
            }
            else if points > Ranks.maxRank.maximumPoints {
                points = Ranks.maxRank.maximumPoints
            }
            rank = getRank(from: points)
        }
    }
    private(set) var rank: Ranks = .bronze
    private(set) var title: Titles = .novice
    private(set) var games = [GameLogic]()
    //items which was unlocked or bought and can be used by a user
    private(set) var availableItems: [GameItem] = [SquaresThemes.defaultTheme, Backgrounds.defaultBackground, Frames.defaultFrame, FiguresThemes.defaultTheme, BoardThemes.defaultTheme, Titles.novice, Avatars.defaultAvatar]
    
    private var availableSquaresThemes = [SquaresThemes.defaultTheme]
    private var availableBackgrounds = [Backgrounds.defaultBackground]
    private var availableFrames = [Frames.defaultFrame]
    private var availableFiguresThemes = [FiguresThemes.defaultTheme]
    private var availableBoardThemes = [BoardThemes.defaultTheme]
    private var availableTitles = [Titles.novice]
    private var availableAvatars = [Avatars.defaultAvatar]
    //whenever new item added to a game or unlocked by a user, we want to add notification icon to point about that
    //then when user have seen it, there is no need in this icon anymore
    private var seenSquaresThemes = [SquaresThemes]()
    private var seenBackgrounds = [Backgrounds]()
    private var seenFrames = [Frames]()
    private var seenFiguresThemes = [FiguresThemes]()
    private var seenBoardThemes = [BoardThemes]()
    private var seenTitles = [Titles]()
    private var seenAvatars = [Avatars]()
    
    //storing encryptionKey along with the password is probably a bad idea, but that`s how it`s for now
    enum CodingKeys: String, CodingKey {
        case nickname, email, games, points, squaresTheme, playerBackground, playerAvatar, frame, figuresTheme, boardTheme, coins, title, availableSquaresThemes, availableBackgrounds, availableFrames, availableFiguresThemes, availableBoardThemes, availableTitles, availableAvatars, seenSquaresThemes, seenBackgrounds, seenFrames, seenFiguresThemes, seenBoardThemes, seenTitles, seenAvatars, musicEnabled, soundsEnabled, rank
    }
    
    // MARK: - Inits
    
    init(email: String, nickname: String = "", guestMode: Bool = false) {
        self.email = email
        self.nickname = nickname
        self.guestMode = guestMode
    }
    
    //Firebase don`t store empty arrays, that`s why we need custom decoder
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try values.decode(String.self, forKey: .nickname)
        email = try values.decode(String.self, forKey: .email)
        points = try values.decode(Int.self, forKey: .points)
        squaresTheme = try values.decode(SquaresThemes.self, forKey: .squaresTheme)
        playerBackground = try values.decode(Backgrounds.self, forKey: .playerBackground)
        playerAvatar = try values.decode(Avatars.self, forKey: .playerAvatar)
        frame = try values.decode(Frames.self, forKey: .frame)
        boardTheme = try values.decode(BoardThemes.self, forKey: .boardTheme)
        figuresTheme = try values.decode(FiguresThemes.self, forKey: .figuresTheme)
        title = try values.decode(Titles.self, forKey: .title)
        coins = (try? values.decode(Int.self, forKey: .coins)) ?? 0
        availableSquaresThemes = (try? values.decode([SquaresThemes].self, forKey: .availableSquaresThemes)) ?? [SquaresThemes.defaultTheme]
        availableBackgrounds = (try? values.decode([Backgrounds].self, forKey: .availableBackgrounds)) ?? [Backgrounds.defaultBackground]
        availableFrames = (try? values.decode([Frames].self, forKey: .availableFrames)) ?? [Frames.defaultFrame]
        availableFiguresThemes = (try? values.decode([FiguresThemes].self, forKey: .availableFiguresThemes)) ?? [FiguresThemes.defaultTheme]
        availableBoardThemes = (try? values.decode([BoardThemes].self, forKey: .availableBoardThemes)) ?? [BoardThemes.defaultTheme]
        availableTitles = (try? values.decode([Titles].self, forKey: .availableTitles)) ?? [Titles.novice]
        availableAvatars = (try? values.decode([Avatars].self, forKey: .availableAvatars)) ?? [Avatars.defaultAvatar]
        seenSquaresThemes = (try? values.decode([SquaresThemes].self, forKey: .seenSquaresThemes)) ?? []
        seenBackgrounds = (try? values.decode([Backgrounds].self, forKey: .seenBackgrounds)) ?? []
        seenFrames = (try? values.decode([Frames].self, forKey: .seenFrames)) ?? []
        seenFiguresThemes = (try? values.decode([FiguresThemes].self, forKey: .seenFiguresThemes)) ?? []
        seenBoardThemes = (try? values.decode([BoardThemes].self, forKey: .seenBoardThemes)) ?? []
        seenTitles = (try? values.decode([Titles].self, forKey: .seenTitles)) ?? []
        seenAvatars = (try? values.decode([Avatars].self, forKey: .seenAvatars)) ?? []
        availableItems = availableSquaresThemes + availableBackgrounds + availableFrames
        availableItems += availableFiguresThemes + availableBoardThemes + availableTitles + availableAvatars
        games = (try? values.decode([GameLogic].self, forKey: .games)) ?? []
        musicEnabled = (try? values.decode(Bool.self, forKey: .musicEnabled)) ?? true
        soundsEnabled = (try? values.decode(Bool.self, forKey: .soundsEnabled)) ?? true
        rank = (try? values.decode(Ranks.self, forKey: .rank)) ?? getRank(from: points)
    }
    
    // MARK: - Methods
    
    //right now only titles can be different in shop and inventory, but it might change in future
    func haveNewItemsInInventory() -> Bool {
        var haveNewInventoryItem = false
        if !guestMode {
            for itemType in GameItems.allCases {
                switch itemType {
                case .squaresThemes:
                    haveNewInventoryItem = haveNewSquaresThemesInInventory()
                case .figuresThemes:
                    haveNewInventoryItem = haveNewFiguresThemesInInventory()
                case .boardThemes:
                    haveNewInventoryItem = haveNewBoardThemesInInventory()
                case .frames:
                    haveNewInventoryItem = haveNewFramesInInventory()
                case .backgrounds:
                    haveNewInventoryItem = haveNewBackgroundsInInventory()
                case .titles:
                    haveNewInventoryItem = haveNewTitlesInInventory()
                case .avatars:
                    //avatars are not part of inventory and instead can be found in user profile
                    break
                }
                if haveNewInventoryItem {
                    return haveNewInventoryItem
                }
            }
        }
        return haveNewInventoryItem
    }
    
    func haveNewItemsInShop() -> Bool {
        var haveNewShopItem = false
        if !guestMode {
            for itemType in GameItems.allCases {
                switch itemType {
                case .squaresThemes:
                    haveNewShopItem = haveNewSquaresThemesInShop()
                case .figuresThemes:
                    haveNewShopItem = haveNewFiguresThemesInShop()
                case .boardThemes:
                    haveNewShopItem = haveNewBoardThemesInShop()
                case .frames:
                    haveNewShopItem = haveNewFramesInShop()
                case .backgrounds:
                    haveNewShopItem = haveNewBackgroundsInShop()
                case .titles:
                    haveNewShopItem = haveNewTitlesInShop()
                case .avatars:
                    haveNewShopItem = haveNewAvatarsInShop()
                }
                if haveNewShopItem {
                    return haveNewShopItem
                }
            }
        }
        return haveNewShopItem
    }
    
    func getRank(from points: Int) -> Ranks {
        switch points {
        case _ where points >= Ranks.bronze.minimumPoints && points <= Ranks.bronze.maximumPoints:
            return .bronze
        case _ where points >= Ranks.silver.minimumPoints && points <= Ranks.silver.maximumPoints:
            return .silver
        case _ where points >= Ranks.gold.minimumPoints && points <= Ranks.gold.maximumPoints:
            return .gold
        case _ where points >= Ranks.diamond.minimumPoints && points <= Ranks.diamond.maximumPoints:
            return .diamond
        case _ where points >= Ranks.master.minimumPoints:
            return .master
        default:
            return .bronze
        }
    }
    
    mutating func addGame(_ game: GameLogic) -> Bool {
        if games.firstIndex(where: {$0.startDate == game.startDate}) == nil {
            games.append(game)
            return true
        }
        return false
    }
    
    mutating func removeGame(_ game: GameLogic) {
        if let gameIndex = games.firstIndex(where: {$0.startDate == game.startDate}) {
            games.remove(at: gameIndex)
        }
    }
    
    mutating func addPoints(_ points: Int) {
        self.points += points
    }
    
    mutating func addCoins(_ coins: Int) {
        self.coins += coins
    }
    
    mutating func addAvailableItem(_ item: GameItem) {
        availableItems.append(item)
        switch item.type {
        case .squaresThemes:
            if let squaresTheme = item as? SquaresThemes {
                availableSquaresThemes.append(squaresTheme)
            }
        case .figuresThemes:
            if let figuresTheme = item as? FiguresThemes {
                availableFiguresThemes.append(figuresTheme)
            }
        case .boardThemes:
            if let boardTheme = item as? BoardThemes {
                availableBoardThemes.append(boardTheme)
            }
        case .frames:
            if let frame = item as? Frames {
                availableFrames.append(frame)
            }
        case .backgrounds:
            if let playerBackground = item as? Backgrounds {
                availableBackgrounds.append(playerBackground)
            }
        case .titles:
            if let title = item as? Titles {
                availableTitles.append(title)
            }
        case .avatars:
            if let playerAvatar = item as? Avatars {
                availableAvatars.append(playerAvatar)
            }
        }
    }
    
    mutating func addSeenItem(_ item: GameItem) {
        switch item.type {
        case .squaresThemes:
            if let squaresTheme = item as? SquaresThemes {
                seenSquaresThemes.append(squaresTheme)
            }
        case .figuresThemes:
            if let figuresTheme = item as? FiguresThemes {
                seenFiguresThemes.append(figuresTheme)
            }
        case .boardThemes:
            if let boardTheme = item as? BoardThemes {
                seenBoardThemes.append(boardTheme)
            }
        case .frames:
            if let frame = item as? Frames {
                seenFrames.append(frame)
            }
        case .backgrounds:
            if let playerBackground = item as? Backgrounds {
                seenBackgrounds.append(playerBackground)
            }
        case .titles:
            if let title = item as? Titles {
                seenTitles.append(title)
            }
        case .avatars:
            if let playerAvatar = item as? Avatars {
                seenAvatars.append(playerAvatar)
            }
        }
    }
    
    func containsNewItemIn(items: [GameItem]) -> Bool {
        if items.count > 0 && !guestMode {
            switch items.first!.type {
            case .squaresThemes:
                if let squaresThemes = items as? [SquaresThemes] {
                    return squaresThemes.first(where: {!seenSquaresThemes.contains($0)}) != nil
                }
            case .figuresThemes:
                if let figuresThemes = items as? [FiguresThemes] {
                    return figuresThemes.first(where: {!seenFiguresThemes.contains($0)}) != nil
                }
            case .boardThemes:
                if let boardThemes = items as? [BoardThemes] {
                    return boardThemes.first(where: {!seenBoardThemes.contains($0)}) != nil
                }
            case .frames:
                if let frames = items as? [Frames] {
                    return frames.first(where: {!seenFrames.contains($0)}) != nil
                }
            case .backgrounds:
                if let playerBackgrounds = items as? [Backgrounds] {
                    return playerBackgrounds.first(where: {!seenBackgrounds.contains($0)}) != nil
                }
            case .titles:
                if let titles = items as? [Titles] {
                    return titles.first(where: {!seenTitles.contains($0)}) != nil
                }
            case .avatars:
                if let playerAvatars = items as? [Avatars] {
                    return playerAvatars.first(where: {!seenAvatars.contains($0)}) != nil
                }
            }
        }
        return false
    }
    
    func haveInInventory(item: GameItem) -> (inInventory: Bool, chosen: Bool, available: Bool) {
        var inInventory = false
        var chosen = false
        switch item.type {
        case .squaresThemes:
            if let squaresTheme = item as? SquaresThemes {
                inInventory = availableItems.contains(where: {$0 as? SquaresThemes == squaresTheme})
                chosen = squaresTheme == self.squaresTheme
            }
        case .figuresThemes:
            if let figuresTheme = item as? FiguresThemes {
                inInventory = availableItems.contains(where: {$0 as? FiguresThemes == figuresTheme})
                chosen = figuresTheme == self.figuresTheme
            }
        case .boardThemes:
            if let boardTheme = item as? BoardThemes {
                inInventory = availableItems.contains(where: {$0 as? BoardThemes == boardTheme})
                chosen = boardTheme == self.boardTheme
            }
        case .frames:
            if let frame = item as? Frames {
                inInventory = availableItems.contains(where: {$0 as? Frames == frame})
                chosen = frame == self.frame
            }
        case .backgrounds:
            if let background = item as? Backgrounds {
                inInventory = availableItems.contains(where: {$0 as? Backgrounds == background})
                chosen = background == self.playerBackground
            }
        case .titles:
            if let title = item as? Titles {
                inInventory = availableItems.contains(where: {$0 as? Titles == title})
                chosen = title == self.title
            }
        case .avatars:
            if let avatar = item as? Avatars {
                inInventory = availableItems.contains(where: {$0 as? Avatars == avatar})
                chosen = avatar == self.playerAvatar
            }
        }
        return (inInventory, chosen, item.cost < coins)
    }
    
    private func haveNewSquaresThemesInInventory() -> Bool {
        containsNewItemIn(items: SquaresThemes.allCases)
    }
    
    private func haveNewFiguresThemesInInventory() -> Bool {
        containsNewItemIn(items: FiguresThemes.allCases)
    }
    
    private func haveNewBoardThemesInInventory() -> Bool {
        containsNewItemIn(items: BoardThemes.allCases)
    }
    
    private func haveNewFramesInInventory() -> Bool {
        containsNewItemIn(items: Frames.allCases)
    }
    
    private func haveNewBackgroundsInInventory() -> Bool {
        containsNewItemIn(items: Backgrounds.allCases)
    }
    
    private func haveNewTitlesInInventory() -> Bool {
        containsNewItemIn(items: Titles.allCases)
    }
    
    func haveNewAvatarsInInventory() -> Bool {
        containsNewItemIn(items: Avatars.allCases)
    }
    
    private func haveNewSquaresThemesInShop() -> Bool {
        containsNewItemIn(items: SquaresThemes.purchasable)
    }
    
    private func haveNewFiguresThemesInShop() -> Bool {
        containsNewItemIn(items: FiguresThemes.purchasable)
    }
    
    private func haveNewBoardThemesInShop() -> Bool {
        containsNewItemIn(items: BoardThemes.purchasable)
    }
    
    private func haveNewFramesInShop() -> Bool {
        containsNewItemIn(items: Frames.purchasable)
    }
    
    private func haveNewBackgroundsInShop() -> Bool {
        containsNewItemIn(items: Backgrounds.purchasable)
    }
    
    private func haveNewTitlesInShop() -> Bool {
        containsNewItemIn(items: Titles.purchasable)
    }
    
    private func haveNewAvatarsInShop() -> Bool {
        containsNewItemIn(items: Avatars.purchasable)
    }
    
    mutating func setValue(with item: GameItem) {
        switch item.type {
        case .squaresThemes:
            if let squaresTheme = item as? SquaresThemes {
                self.squaresTheme = squaresTheme
            }
        case .figuresThemes:
            if let figuresTheme = item as? FiguresThemes {
                self.figuresTheme = figuresTheme
            }
        case .boardThemes:
            if let boardTheme = item as? BoardThemes {
                self.boardTheme = boardTheme
            }
        case .frames:
            if let frame = item as? Frames {
                self.frame = frame
            }
        case .backgrounds:
            if let playerBackground = item as? Backgrounds {
                self.playerBackground = playerBackground
            }
        case .titles:
            if let title = item as? Titles {
                self.title = title
            }
        case .avatars:
            if let playerAvatar = item as? Avatars {
                self.playerAvatar = playerAvatar
            }
        }
    }
    
    mutating func updateNickname(newValue: String) {
        nickname = newValue
    }
    
    mutating func updateEmail(newValue: String) {
        email = newValue
    }
    
    mutating func updatePoints(newValue: Int) {
        points = newValue
    }
    
    mutating func updateSoundsEnabled(newValue: Bool) {
        soundsEnabled = newValue
    }
    
    mutating func updateMusicEnabled(newValue: Bool) {
        musicEnabled = newValue
    }
    
}
