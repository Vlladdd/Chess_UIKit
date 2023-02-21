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
    
    let mainView: UIView
    
    private let height: CGFloat?
    private var specialHeightConstraint: NSLayoutConstraint? = nil
    private var notificationIcon: UIImageView?
    
    private typealias constants = ViewWithNotifIcon_Constants
    
    // MARK: - Inits
    
    init(mainView: UIView, height: CGFloat?) {
        self.height = height
        self.mainView = mainView
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        addSubview(mainView)
        let mainViewConstraints = [mainView.leadingAnchor.constraint(equalTo: leadingAnchor), mainView.bottomAnchor.constraint(equalTo: bottomAnchor), mainView.topAnchor.constraint(equalTo: topAnchor), mainView.trailingAnchor.constraint(equalTo: trailingAnchor)]
        if let height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        NSLayoutConstraint.activate(mainViewConstraints)
    }
    
    func addNotificationIcon() {
        if notificationIcon == nil {
            notificationIcon = UIImageView()
            if let notificationIcon {
                notificationIcon.defaultSettings()
                notificationIcon.settingsForBackgroundOfTheButton(cornerRadius: mainView.layer.cornerRadius)
                notificationIcon.isUserInteractionEnabled = false
                notificationIcon.backgroundColor = constants.notificationIconBackgroundColor
                addSubview(notificationIcon)
                //in case if we are re-adding notification icon
                NSLayoutConstraint.deactivate(constraints.filter({$0.firstItem === mainView}))
                let notificationViewConstraints = [notificationIcon.heightAnchor.constraint(equalTo: heightAnchor, multiplier: constants.sizeMultiplierForNotificationIcon), notificationIcon.widthAnchor.constraint(equalTo: notificationIcon.heightAnchor), notificationIcon.trailingAnchor.constraint(equalTo: trailingAnchor), notificationIcon.topAnchor.constraint(equalTo: topAnchor), mainView.topAnchor.constraint(equalTo: notificationIcon.centerYAnchor), mainView.trailingAnchor.constraint(equalTo: notificationIcon.centerXAnchor), mainView.leadingAnchor.constraint(equalTo: leadingAnchor), mainView.bottomAnchor.constraint(equalTo: bottomAnchor)]
                if height == nil, let mainView = mainView as? UITextField, let pointSize = mainView.font?.pointSize {
                    specialHeightConstraint = heightAnchor.constraint(equalToConstant: pointSize * constants.multiplierForHeightTF)
                    specialHeightConstraint?.isActive = true
                }
                NSLayoutConstraint.activate(notificationViewConstraints)
                //transition animation seems enough, but sometimes for some reason it might not work here
                //and also this combination looks cool
                layer.rotate(from: -.pi, to: 0, animated: true, duration: constants.animationDuration)
                UIView.transition(with: self, duration: constants.animationDuration, options: .transitionFlipFromBottom, animations: { [weak self] in
                    guard let self else { return }
                    self.rootView.layoutIfNeeded()
                })
            }
        }
    }
     
    func removeNotificationIcon() {
        if let notificationIcon {
            notificationIcon.removeFromSuperview()
            self.notificationIcon = nil
            let newConstraints = [mainView.trailingAnchor.constraint(equalTo: trailingAnchor), mainView.topAnchor.constraint(equalTo: topAnchor)]
            NSLayoutConstraint.activate(newConstraints)
            specialHeightConstraint?.isActive = false
            UIView.transition(with: self, duration: constants.animationDuration, options: .transitionFlipFromTop, animations: { [weak self] in
                guard let self else { return }
                self.rootView.layoutIfNeeded()
            })
        }
    }
    
}

// MARK: - Constants

private struct ViewWithNotifIcon_Constants {
    static let notificationIconBackgroundColor = UIColor.red
    static let sizeMultiplierForNotificationIcon = 0.5
    static let animationDuration = 0.5
    //if mainView is UITextField
    static let multiplierForHeightTF = 1.5
}
