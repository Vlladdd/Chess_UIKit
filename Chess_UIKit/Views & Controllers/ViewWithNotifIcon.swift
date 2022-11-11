//
//  ViewWithNotifIcon.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 10.11.2022.
//

import UIKit

//class, that represents view with notification icon
//it`s easier to make it like this, to prevent notification icon going beyond view frame, which will
//give wrong result, if masksToBounds = true and also to prevent icon to go beyond device screen, in case if we will add
//notifation icon to view`s superview and if superview`s masksToBounds = false
//and also if we want to fit notification icon, view must have constraints related to notification icon, which also means
//view must be subview of notification icon or have same superview, but cuz view`s superview can be stack view,
//it is better not to attach any constraints in that case to view, cuz it can break stack view
class ViewWithNotifIcon: UIImageView {
    
    // MARK: - Properties
    
    private(set) var mainView: UIView!
    
    private var cornerRadius: CGFloat = 0
    
    private typealias constants = ViewWithNotifIcon_Constants
    
    // MARK: - Inits
    
    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = true
    }
    
    init(mainView: UIView, cornerRadius: CGFloat) {
        super.init(frame: .zero)
        self.mainView = mainView
        self.cornerRadius = cornerRadius
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        layer.setValue(true, forKey: constants.keyForViewWithNotifIcon)
        addSubview(mainView)
        addNotificationIcon()
    }
    
    private func addNotificationIcon() {
        let notificationIcon = UIImageView()
        notificationIcon.defaultSettings()
        notificationIcon.settingsForBackgroundOfTheButton(cornerRadius: cornerRadius)
        notificationIcon.isUserInteractionEnabled = false
        notificationIcon.backgroundColor = constants.notificationIconBackgroundColor
        //makes it easier to find this view
        notificationIcon.layer.setValue(true, forKey: constants.keyForNotifIcon)
        addSubview(notificationIcon)
        //in case if we are re-adding notification icon
        NSLayoutConstraint.deactivate(constraints.filter({$0.firstItem === mainView}))
        let notificationViewConstraints = [notificationIcon.heightAnchor.constraint(equalTo: heightAnchor, multiplier: constants.sizeMultiplierForNotificationIcon), notificationIcon.widthAnchor.constraint(equalTo: notificationIcon.heightAnchor), notificationIcon.trailingAnchor.constraint(equalTo: trailingAnchor), notificationIcon.topAnchor.constraint(equalTo: topAnchor), mainView.topAnchor.constraint(equalTo: notificationIcon.centerYAnchor), mainView.trailingAnchor.constraint(equalTo: notificationIcon.centerXAnchor), mainView.leadingAnchor.constraint(equalTo: leadingAnchor), mainView.bottomAnchor.constraint(equalTo: bottomAnchor)]
        NSLayoutConstraint.activate(notificationViewConstraints)
        UIView.transition(with: self, duration: constants.animationDuration, options: .transitionFlipFromBottom, animations: {[weak self] in
            self?.superview?.layoutIfNeeded()
        })
    }
    
    func removeNotificationIcon() {
        if let notificationIcon = subviews.first(where: {
            if let isNotifIcon = $0.layer.value(forKey: constants.keyForNotifIcon) as? Bool {
                return isNotifIcon
            }
            return false
        }) {
            notificationIcon.removeFromSuperview()
            let newConstraints = [mainView.trailingAnchor.constraint(equalTo: trailingAnchor), mainView.topAnchor.constraint(equalTo: topAnchor)]
            NSLayoutConstraint.activate(newConstraints)
            UIView.transition(with: self, duration: constants.animationDuration, options: .transitionFlipFromTop, animations: {[weak self] in
                self?.superview?.layoutIfNeeded()
            })
        }
    }
    
}

// MARK: - Constants

private struct ViewWithNotifIcon_Constants {
    static let keyForNotifIcon = "isNotifIcon"
    static let keyForViewWithNotifIcon = "isSpecial"
    static let notificationIconBackgroundColor = UIColor.red
    static let sizeMultiplierForNotificationIcon = 0.5
    static let animationDuration = 0.5
}
