//
//  UserProfileVC.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 05.11.2022.
//

import UIKit

//VC that represents user profile view
class UserProfileVC: UIViewController {
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        configureKeyboardToHideWhenTappedAround()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        userProfileView.onRotate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayer.playSound(Sounds.closePopUpSound)
    }
    
    // MARK: - Properties
    
    private typealias constants = UserProfileVC_Constants
    
    private let audioPlayer = AudioPlayer.sharedInstance
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private(set) var userProfileView: UserProfileView!
    
    // MARK: - UI Methods
    
    private func makeUI() {
        let fontSize = min(view.frame.width, view.frame.height) / constants.dividerForFont
        let widthForAvatar = min(view.frame.height, view.frame.width) / constants.sizeMultiplayerForAvatar
        userProfileView = UserProfileView(widthForAvatar: widthForAvatar, fontSize: fontSize)
        userProfileView.userProfileDelegate = self
        view.addSubview(userProfileView)
        let userProfileViewConstraints = [userProfileView.leadingAnchor.constraint(equalTo: view.leadingAnchor), userProfileView.trailingAnchor.constraint(equalTo: view.trailingAnchor), userProfileView.topAnchor.constraint(equalTo: view.topAnchor), userProfileView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        NSLayoutConstraint.activate(userProfileViewConstraints)
    }
    
}

// MARK: - Constants

private struct UserProfileVC_Constants {
    static let dividerForFont: CGFloat = 13
    static let sizeMultiplayerForAvatar = 4.0
}
