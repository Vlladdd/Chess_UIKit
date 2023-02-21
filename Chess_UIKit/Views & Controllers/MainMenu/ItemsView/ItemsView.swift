//
//  ItemsView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.02.2023.
//

import UIKit

//class that represents items view
class ItemsView: UIStackView, InvItemDelegate {
    
    // MARK: - InvItemDelegate
    
    var font: UIFont {
        delegate?.font ?? UIFont.systemFont(ofSize: constants.defaultFontSize)
    }
    
    func updateNotificationIcons() {
        for button in arrangedSubviews {
            if let viewWithNotifIcon = button as? ViewWithNotifIcon {
                if let specialItemView = viewWithNotifIcon.mainView as? SpecialItemView {
                    if storage.currentUser.containsNewItemIn(items: [specialItemView.item]) {
                        viewWithNotifIcon.addNotificationIcon()
                    }
                    else {
                        viewWithNotifIcon.removeNotificationIcon()
                    }
                    if let frameView = specialItemView.itemView as? FrameView {
                        frameView.setNeedsDisplay()
                    }
                }
            }
        }
    }
    
    func makeAdditionalButtons() -> AdditionalButtons {
        if let delegate {
            return ABBuilder(delegate: delegate)
                .addBackButton(type: isShopItems ? .toShopMenu : .toInventoryMenu)
                .addCoinsView()
                .build()
        }
        else {
            fatalError("delegate is nil")
        }
    }
    
    func updateItemsColor(inShop: Bool) {
        for button in arrangedSubviews {
            if let viewWithNotifIcon = button as? ViewWithNotifIcon, let itemView = viewWithNotifIcon.mainView as? ItemView {
                let itemInfo = storage.currentUser.haveInInventory(item: itemView.item)
                let inInventory = itemInfo.inInventory
                let chosen = itemInfo.chosen
                let available = itemInfo.available
                var color = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
                let textColor = defaultTextColor
                var isEnabled = false
                if inShop {
                    if inInventory {
                        color = constants.inInventoryColor
                    }
                    else if !available {
                        color = constants.notAvailableColor
                    }
                    isEnabled = !inInventory && available
                }
                else {
                    if chosen {
                        color = constants.chosenItemColor
                    }
                    else if !inInventory {
                        color = constants.notAvailableColor
                    }
                    isEnabled = inInventory && !chosen
                }
                var button: UIButton?
                if let itemView = itemView as? InvItemView {
                    button = itemView.chooseButton
                }
                else if let itemView = itemView as? ShopItemView {
                    button = itemView.buyButton
                }
                UIView.animate(withDuration: constants.animationDuration, animations: {
                    itemView.backgroundColor = color
                    button?.backgroundColor = color
                    button?.isEnabled = isEnabled
                    if inShop && !isEnabled {
                        button?.setTitleColor(textColor, for: .normal)
                    }
                })
            }
        }
    }
    
    // MARK: - Properties
    
    weak var delegate: MainMenuViewDelegate?
    
    private typealias constants = ItemsView_Constants
    
    private let isShopItems: Bool
    private let items: [GameItem]
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    
    private lazy var defaultTextColor = traitCollection.userInterfaceStyle == .dark ? constants.lightModeTextColor : constants.darkModeTextColor
    
    // MARK: - Inits
    
    init(items: [GameItem], isShopItems: Bool, delegate: MainMenuViewDelegate) {
        self.items = items
        self.isShopItems = isShopItems
        self.delegate = delegate
        super.init(frame: .zero)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    //highlights picked item and removes notification icon from him
    @objc private func pickitem(_ sender: UITapGestureRecognizer? = nil) {
        if let viewWithNotifIcon = (sender?.view as? ViewWithNotifIcon), let specialItemView = viewWithNotifIcon.mainView as? SpecialItemView {
            audioPlayer.playSound(Sounds.pickItemSound)
            storage.currentUser.addSeenItem(specialItemView.item)
            unpickAllItems()
            specialItemView.layer.borderColor = constants.pickItemBorderColor
            delegate?.updateNotificationIcons()
        }
    }
    
    // MARK: - Methods
    
    private func setup() {
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
                    itemsViews = makeFramesView(frames: frames)
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
        updateItemsColor(inShop: isShopItems)
    }
    
    private func createItemsView(with views: [ItemView]) {
        for view in views {
            var itemView: MMButtonView!
            if isShopItems, let delegate {
                itemView = ShopItemView(itemView: view, delegate: delegate, needHeightConstraint: false)
            }
            else {
                itemView = InvItemView(itemView: view, delegate: self, needHeightConstraint: false)
            }
            let itemViewWithNI = ViewWithNotifIcon(mainView: itemView, height: MMButtonView.getOptimalHeight(with: font.pointSize))
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pickitem))
            itemViewWithNI.addGestureRecognizer(tapGesture)
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
    
    private func makeFramesView(frames: [Frames]) -> [ItemView] {
        var framesViews = [ItemView]()
        for frame in frames {
            let itemView = FrameView(frame: frame, font: font)
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
    
    private func unpickAllItems() {
        for button in arrangedSubviews {
            if let viewWithNotifIcon = button as? ViewWithNotifIcon {
                viewWithNotifIcon.mainView.layer.borderColor = defaultTextColor.cgColor
            }
        }
    }
    
    //when device changed orientation
    func onRotate() {
        for button in arrangedSubviews {
            if let viewWithNotifIcon = button as? ViewWithNotifIcon {
                if let specialItemView = viewWithNotifIcon.mainView as? SpecialItemView {
                    if let itemView = specialItemView.itemView as? FrameView {
                        itemView.setNeedsDisplay()
                    }
                }
            }
        }
    }
    
}

// MARK: - Constants

private struct ItemsView_Constants {
    static let optimalAlpha = 0.5
    static let animationDuration = 0.5
    static let optimalSpacing = 5.0
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let darkModeTextColor = UIColor.black
    static let lightModeTextColor = UIColor.white
    static let inInventoryColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let notAvailableColor = UIColor.red.withAlphaComponent(optimalAlpha)
    static let chosenItemColor = UIColor.green.withAlphaComponent(optimalAlpha)
    static let pickItemBorderColor = UIColor.yellow.cgColor
    static let defaultFontSize: CGFloat = 10
}
