//
//  LoadingSpinner.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 10.11.2022.
//

import UIKit

// MARK: - LoadingSpinnerDelegate

protocol LoadingSpinnerDelegate: AnyObject {
    func loadingSpinnerDidRemoveFromSuperview(_ loadingSpinner: LoadingSpinner) -> Void
}

// MARK: - LoadingSpinner

//class that represents loading spinner
class LoadingSpinner: UIImageView {
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        delegate?.loadingSpinnerDidRemoveFromSuperview(self)
    }
    
    // MARK: - Properties
    
    weak var delegate: LoadingSpinnerDelegate?
    
    private typealias constants = LoadingSpinner_Constants
    
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
        let figureItem = traitCollection.userInterfaceStyle == .dark ? constants.spinningFigureDarkMode : constants.spinningFigureLightMode
        let spinner = UIImageView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.contentMode = .scaleAspectFit
        spinner.setImage(with: FiguresThemes.defaultTheme.getSkinedFigure(from: figureItem))
        spinner.rotate360Degrees(duration: constants.speedForSpinner)
        addSubview(spinner)
        let spinnerConstraints = [spinner.widthAnchor.constraint(equalTo: widthAnchor, multiplier: constants.sizeMultiplierForSpinner), spinner.heightAnchor.constraint(equalTo: heightAnchor, multiplier: constants.sizeMultiplierForSpinner), spinner.centerXAnchor.constraint(equalTo: centerXAnchor), spinner.centerYAnchor.constraint(equalTo: centerYAnchor)]
        NSLayoutConstraint.activate(spinnerConstraints)
    }
    
}

// MARK: - Constants

private struct LoadingSpinner_Constants {
    static let optimalAlpha = 0.5
    static let speedForSpinner = 1.0
    static let sizeMultiplierForSpinner = 0.6
    static let spinningFigureLightMode = Figure(type: .king, color: .black)
    static let spinningFigureDarkMode = Figure(type: .king, color: .white)
}
