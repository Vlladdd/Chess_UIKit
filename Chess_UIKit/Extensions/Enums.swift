//
//  Enums.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 12.06.2022.
//

import Foundation

// MARK: - Some useful enums

//columns in chess called files
enum BoardFiles: String, CaseIterable, Equatable, Comparable, Codable, ImageItem {
    
    case A
    case B
    case C
    case D
    case E
    case F
    case G
    case H
    
    static func < (lhs: BoardFiles, rhs: BoardFiles) -> Bool {
        lhs.asString < rhs.asString
    }
    
    var index: Int {
        switch self {
        case .A:
            return 1
        case .B:
            return 2
        case .C:
            return 3
        case .D:
            return 4
        case .E:
            return 5
        case .F:
            return 6
        case .G:
            return 7
        case .H:
            return 8
        }
    }
    
}

enum Figures: String, Equatable, Codable, CaseIterable {

    case pawn
    case rook
    case knight
    case bishop
    case queen
    case king
    
    static let forPawnTransform: [Self] = [.rook, .knight, .bishop, .queen]
    
}

enum GamePlayers: String, Codable {
    case player1
    case player2
}

enum MultiplayerPlayerType: String, Codable {
    case creator
    case joiner
}

enum GameColors: String, CaseIterable, Codable {
    case white
    case black
    case random
    
    func opposite() -> Self {
        switch self {
        case .white:
            return .black
        case .black:
            return .white
        case .random:
            return random()
        }
    }
    
    func random() -> Self {
        let possibleCases: [Self] = [.black, .white]
        return possibleCases.randomElement() ?? .random
    }
    
}

enum Colors: String, Codable {
    case white
    case black
    case blue
    case orange
    case red
    case green
}

enum SquaresThemes: String, Codable, CaseIterable, GameItem {
    case defaultTheme
    
    static let purchasable: [Self] = SquaresThemes.allCases
    
    var cost: Int {
        switch self {
        case .defaultTheme:
            return 0
        }
    }
    
    var type: GameItems {
        .squaresThemes
    }
    
    var description: String {
        switch self {
        case .defaultTheme:
            return "Just a default theme, nothing special"
        }
    }
    
    func getTheme() -> SquaresTheme {
        switch self {
        case .defaultTheme:
            return SquaresTheme(name: .defaultTheme, firstColor: .white, secondColor: .black, turnColor: .orange, availableSquaresColor: .green, pickColor: .red, checkColor: .blue)
        }
    }
    
}

enum FiguresThemes: String, Codable, CaseIterable, GameItem, ImageItem {
    case defaultTheme
    
    static let purchasable: [Self] = FiguresThemes.allCases
    
    var cost: Int {
        switch self {
        case .defaultTheme:
            return 0
        }
    }
    
    var type: GameItems {
        .figuresThemes
    }
    
    var description: String {
        switch self {
        case .defaultTheme:
            return "Just a default theme, nothing special"
        }
    }
    
    func getSkinedFigure(from figure: Figure) -> ImageItem {
        CustomImageItem(item: figure, theme: self)
    }
    
}

enum BoardThemes: String, CaseIterable, Codable, GameItem, ImageItem {
    case defaultTheme
    
    static let purchasable: [Self] = BoardThemes.allCases
    
    var cost: Int {
        switch self {
        case .defaultTheme:
            return 0
        }
    }
    
    var type: GameItems {
        .boardThemes
    }
    
    var description: String {
        switch self {
        case .defaultTheme:
            return "Just a default theme, nothing special"
        }
    }
    
    var emptySquareItem: ImageItem {
        CustomImageItem(item: SpecialImageItems.letter, theme: self)
    }
    
    func getSkinedLetter(from file: BoardFiles) -> ImageItem {
        CustomImageItem(item: file, theme: self)
    }
    
    func getSkinedNumber(from number: Int) -> ImageItem? {
        let numberItem = BoardNumberItems.fromNumber(number)
        if let numberItem {
            return CustomImageItem(item: numberItem, theme: self)
        }
        return nil
    }
    
    func getSkinedNumber(from numberItem: BoardNumberItems) -> ImageItem {
        CustomImageItem(item: numberItem, theme: self)
    }
    
}

enum Frames: String, Codable, CaseIterable, GameItem, ImageItem {
    case defaultFrame
    case ukraineFlag
    
    static let purchasable: [Self] = Frames.allCases
    
    var cost: Int {
        switch self {
        case .defaultFrame:
            return 0
        case .ukraineFlag:
            return 100
        }
    }
    
    var type: GameItems {
        .frames
    }
    
    var description: String {
        switch self {
        case .defaultFrame:
            return "Just a default frame, nothing special"
        case .ukraineFlag:
            return "Show support to Ukraine with this frame"
        }
    }
    
}

enum Backgrounds: String, Codable, CaseIterable, GameItem, ImageItem {
    case defaultBackground
    
    static let purchasable: [Self] = Backgrounds.allCases
    
    var cost: Int {
        switch self {
        case .defaultBackground:
            return 0
        }
    }
    
    var type: GameItems {
        .backgrounds
    }
    
    var description: String {
        switch self {
        case .defaultBackground:
            return "Just a default background, nothing special"
        }
    }
    
}

enum Avatars: String, Codable, CaseIterable, GameItem, ImageItem {
    case defaultAvatar
    case ukraineFlag
    
    static let purchasable: [Self] = Avatars.allCases
    
    var cost: Int {
        switch self {
        case .defaultAvatar:
            return 0
        case .ukraineFlag:
            return 300
        }
    }
    
    var type: GameItems {
        .avatars
    }
    
    var description: String {
        switch self {
        case .defaultAvatar:
            return "Just a default avatar, nothing special"
        case .ukraineFlag:
            return "Show support to Ukraine with this avatar"
        }
    }
    
}

enum Ranks: String, Codable {
    case bronze
    case silver
    case gold
    case diamond
    case master
    
    static let maxRank: Self = .master
    
    var minimumPoints: Int {
        switch self {
        case .bronze:
            return 0
        case .silver:
            return 501
        case .gold:
            return 1501
        case .diamond:
            return 3001
        case .master:
            return 10001
        }
    }
    
    var maximumPoints: Int {
        switch self {
        case .bronze:
            return 500
        case .silver:
            return 1500
        case .gold:
            return 3000
        case .diamond:
            return 10000
        case .master:
            return 1_000_000
        }
    }
    
    var nextRank: Self {
        switch self {
        case .bronze:
            return .silver
        case .silver:
            return .gold
        case .gold:
            return .diamond
        case .diamond:
            return .master
        case .master:
            return .master
        }
    }
    
    var previousRank: Self {
        switch self {
        case .bronze:
            return .bronze
        case .silver:
            return .bronze
        case .gold:
            return .silver
        case .diamond:
            return .gold
        case .master:
            return .diamond
        }
    }
    
    //used in points calculation
    var factor: Int {
        switch self {
        case .bronze:
            return 2
        case .silver:
            return 4
        case .gold:
            return 8
        case .diamond:
            return 16
        case .master:
            return 32
        }
    }
    
}

enum Titles: String, Codable, CaseIterable, GameItem {
    case novice
    case admin
    case theChosenOne
    case waster
    
    static let purchasable: [Self] = [.waster]
    
    var cost: Int {
        switch self {
        case .novice, .admin, .theChosenOne:
            return 0
        case .waster:
            return 10000
        }
    }
    
    var type: GameItems {
        .titles
    }
    
    var description: String {
        switch self {
        case .novice:
            return "First step to become master"
        case .waster:
            return "You really spend 10000 coins for this?"
        case .admin:
            return "I am an admin, ye boy"
        case .theChosenOne:
            return "Gods believe in you"
        }
    }
    
    
}

enum GameModes: String, CaseIterable, Codable {
    case oneScreen
    case multiplayer
}

enum Answers: String, CaseIterable {
    case yes
    case no
}

enum GameItems: String, CaseIterable, Item {
    case squaresThemes
    case figuresThemes
    case boardThemes
    case frames
    case backgrounds
    case titles
    case avatars
}

enum Music: String, SoundItem {

    case dangerMusic
    case gameBackgroundMusic
    case menuBackgroundMusic
    case waitingMusic
    
    var folderName: Item? {
        SoundItems.music
    }
    
}

enum Sounds: String, SoundItem {

    case buyItemSound
    case castleSound
    case checkmateSound
    case checkSound
    case chooseItemSound
    case clockTickSound
    case closePopUpSound
    case errorSound
    case figureCaptureSound
    case loseSound
    case moveSound1
    case moveSound2
    case moveSound3
    case moveSound4
    case openPopUpSound
    case pickItemSound
    case removeSound
    case sadSound
    case successSound
    case toggleSound
    case winSound
    
    var folderName: Item? {
        SoundItems.sounds
    }
    
}

enum AudioStatus: String {
    case notPlaying
    case playing
    case paused
    case loading
}

enum MiscImages: String, ImageItem {
    
    case boardsButtonBG
    case coinsBG
    case createButtonBG
    case defaultBG
    case figuresButtonBG
    case framesButtonBG
    case gameButtonBG
    case inventoryButtonBG
    case joinButtonBG
    case loadButtonBG
    case shopButtonBG
    case squaresButtonBG
    
    var folderName: Item? {
        OtherItems.misc
    }
    
}

enum SystemImages: String, ImageItem {
    
    case backImage
    case deleteImage
    case expandImage
    case expandImage2
    case enterImage
    case chooseImage
    case descriptionImage
    case exitImage
    case exitImageiOS15
    case noInternetImage
    case unlockedImage
    case lockedImage
    case stopImage
    case playImage
    case surrenderImage
    case backwardImage
    case forwardImage
    case detailedInfoImage
    case chatImage
    case hideImage
    case showImage
    case saveImage
    case autorotateFiguresImage
    case restoreImage
    case speedupImage
    case sendImage
    
    func getSystemName() -> String {
        switch self {
        case .backImage:
            return "arrow.left"
        case .deleteImage:
            return "trash"
        case .expandImage:
            return "menubar.arrow.down.rectangle"
        case .expandImage2:
            return "arrowtriangle.down.fill"
        case .enterImage:
            return "arrow.right.to.line"
        case .chooseImage:
            return "checkmark"
        case .descriptionImage:
            return "info"
        case .exitImageiOS15:
            return "rectangle.portrait.and.arrow.right"
        case .exitImage:
            return "arrow.left.square"
        case .noInternetImage:
            return "wifi.slash"
        case .unlockedImage:
            return "lock.open"
        case .lockedImage:
            return "lock"
        case .stopImage:
            return "stop"
        case .playImage:
            return "play"
        case .surrenderImage:
            return "flag.fill"
        case .backwardImage:
            return "backward"
        case .forwardImage:
            return "forward"
        case .detailedInfoImage:
            return "doc.text.magnifyingglass"
        case .chatImage:
            return "text.bubble"
        case .hideImage:
            return "eye.slash"
        case .showImage:
            return "eye"
        case .saveImage:
            return "square.and.arrow.down"
        case .autorotateFiguresImage:
            return "arrow.2.squarepath"
        case .restoreImage:
            return "arrow.uturn.backward"
        case .speedupImage:
            return "timer"
        case .sendImage:
            return "paperplane"
        }
    }
    
}

enum BoardNumberItems: String, CaseIterable, ImageItem {
    
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    
    func getNumber() -> Int {
        switch self {
        case .one:
            return 1
        case .two:
            return 2
        case .three:
            return 3
        case .four:
            return 4
        case .five:
            return 5
        case .six:
            return 6
        case .seven:
            return 7
        case .eight:
            return 8
        }
    }
    
    static func fromNumber(_ number: Int) -> Self? {
        Self.allCases.first(where: {$0.getNumber() == number})
    }
    
}

enum SpecialImageItems: String, ImageItem {
    case letter
}

enum SoundItems: String, Item {
    case music
    case sounds
}

enum OtherItems: String, Item {
    case misc
}

enum BackButtonType: String {
    case toMainMenu
    case toInventoryMenu
    case toShopMenu
    case toGameMenu
}
