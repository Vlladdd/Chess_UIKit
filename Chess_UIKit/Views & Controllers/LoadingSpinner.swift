//
//  LoadingSpinner.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 10.11.2022.
//

import UIKit

//class that represents loading spinner
class LoadingSpinner: UIImageView {
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        audioPlayer.stopSound(Music.waitingMusic)
    }
    
    // MARK: - Properties
    
    private typealias constants = LoadingSpinner_Constants
    
    private let audioPlayer = AudioPlayer.sharedInstance
    
    // MARK: - Inits
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup() {
        defaultSettings()
        backgroundColor = backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        let figureName = traitCollection.userInterfaceStyle == .dark ? "white_king" : "black_king"
        let spinner = UIImageView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.contentMode = .scaleAspectFit
        spinner.image = UIImage(named: "figuresThemes/defaultTheme/\(figureName)")
        spinner.rotate360Degrees(duration: constants.speedForSpinner)
        addSubview(spinner)
        let spinnerConstraints = [spinner.widthAnchor.constraint(equalTo: widthAnchor, multiplier: constants.sizeMultiplierForSpinner), spinner.heightAnchor.constraint(equalTo: heightAnchor, multiplier: constants.sizeMultiplierForSpinner), spinner.centerXAnchor.constraint(equalTo: centerXAnchor), spinner.centerYAnchor.constraint(equalTo: centerYAnchor)]
        NSLayoutConstraint.activate(spinnerConstraints)
    }
    
    func waiting() {
        audioPlayer.playSound(Music.waitingMusic, volume: constants.volumeForWaitingMusic)
    }
    
}

// MARK: - Constants

private struct LoadingSpinner_Constants {
    static let optimalAlpha = 0.5
    static let speedForSpinner = 1.0
    static let sizeMultiplierForSpinner = 0.6
    static let volumeForWaitingMusic: Float = 0.3
}
