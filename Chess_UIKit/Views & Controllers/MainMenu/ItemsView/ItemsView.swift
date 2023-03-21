//
//  ItemsView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.02.2023.
//

import UIKit

//class that represents items view
class ItemsView: UIStackView {
    
    // MARK: - Properties
    
    let isShopItems: Bool
    
    var pickedItemView: SpecialItemView?
    var chosenItemView: InvItemView?
    
    private typealias constants = ItemsView_Constants
    
    private let font: UIFont
    
    // MARK: - Inits
    
    init(items: [GameItem], isShopItems: Bool, font: UIFont, playerBackground: Backgrounds) {
        self.isShopItems = isShopItems
        self.font = font
        super.init(frame: .zero)
        setup(with: playerBackground, and: items)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup(with playerBackground: Backgrounds, and items: [GameItem]) {
        var itemsViews = [ItemView]()
        setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        if items.count > 0 {
            switch items.first!.type {
            case .squaresThemes:
                if let squaresThemes = items as? [SquaresThemes] {
                    itemsViews = makeSquaresThemesViews(squaresThemes: squaresThemes)
                }
            case .figuresThemes:
                if let figuresThemes = items as? [FiguresThemes] {
                    itemsViews = makeFiguresViews(figuresThemes: figuresThemes)
                }
            case .boardThemes:
                if let boardThemes = items as? [BoardThemes] {
                    itemsViews = makeBoardThemesView(boardThemes: boardThemes)
                }
            case .frames:
                if let frames = items as? [Frames] {
                    itemsViews = makeFramesView(frames: frames, background: playerBackground)
                }
            case .backgrounds:
                if let backgroundThemes = items as? [Backgrounds] {
                    itemsViews = makeBackgroundThemesView(backgroundThemes: backgroundThemes)
                }
            case .titles:
                if let titles = items as? [Titles] {
                    itemsViews = makeTitlesView(titles: titles)
                }
            case .avatars:
                if isShopItems, let avatars = items as? [Avatars] {
                    itemsViews = makeAvatarsViews(avatars: avatars)
                }
            }
        }
        createItemsView(with: itemsViews)
    }
    
    private func createItemsView(with views: [ItemView]) {
        for view in views {
            var itemView: MMButtonView!
            if isShopItems {
                itemView = ShopItemView(itemView: view, font: font, needHeightConstraint: false)
            }
            else {
                itemView = InvItemView(itemView: view, font: font, needHeightConstraint: false)
            }
            let itemViewWithNI = ViewWithNotifIcon(mainView: itemView, height: MMButtonView.getOptimalHeight(with: font.pointSize))
            addArrangedSubview(itemViewWithNI)
        }
    }
    
    private func makeSquaresThemesViews(squaresThemes: [SquaresThemes]) -> [ItemView] {
        var squaresThemesViews = [ItemView]()
        for squaresTheme in squaresThemes {
            let itemView = SThemeView(squaresTheme: squaresTheme, font: font)
            squaresThemesViews.append(itemView)
        }
        return squaresThemesViews
    }
    
    private func makeFiguresViews(figuresThemes: [FiguresThemes]) -> [ItemView] {
        var figuresViews = [ItemView]()
        for figuresTheme in figuresThemes {
            let itemView = FThemeView(figuresTheme: figuresTheme)
            figuresViews.append(itemView)
        }
        return figuresViews
    }
    
    private func makeBoardThemesView(boardThemes: [BoardThemes]) -> [ItemView] {
        var boardThemesViews = [ItemView]()
        for boardTheme in boardThemes {
            let itemView = BThemeView(boardTheme: boardTheme)
            boardThemesViews.append(itemView)
        }
        return boardThemesViews
    }
    
    private func makeFramesView(frames: [Frames], background: Backgrounds) -> [ItemView] {
        var framesViews = [ItemView]()
        for frame in frames {
            let itemView = FrameView(frame: frame, font: font, background: background)
            framesViews.append(itemView)
        }
        return framesViews
    }
    
    private func makeBackgroundThemesView(backgroundThemes: [Backgrounds]) -> [ItemView] {
        var backgroundThemesViews = [ItemView]()
        for backgroundTheme in backgroundThemes {
            let itemView = BKThemeView(backgroundTheme: backgroundTheme, font: font)
            backgroundThemesViews.append(itemView)
        }
        return backgroundThemesViews
    }
    
    private func makeTitlesView(titles: [Titles]) -> [ItemView] {
        var titlesViews = [ItemView]()
        for title in titles {
            let itemView = TitleView(title: title, font: font)
            titlesViews.append(itemView)
        }
        return titlesViews
    }
    
    private func makeAvatarsViews(avatars: [Avatars]) -> [ItemView] {
        var avatarsViews = [ItemView]()
        for avatar in avatars {
            let itemView = AvatarView(avatar: avatar, font: font)
            avatarsViews.append(itemView)
        }
        return avatarsViews
    }
    
    //when device changed orientation
    func onRotate() {
        for button in arrangedSubviews {
            if let viewWithNotifIcon = button as? ViewWithNotifIcon {
                if let specialItemView = viewWithNotifIcon.mainView as? SpecialItemView {
                    specialItemView.onRotate()
                }
            }
        }
    }
    
}

// MARK: - Constants

private struct ItemsView_Constants {
    static let optimalSpacing = 5.0
}
