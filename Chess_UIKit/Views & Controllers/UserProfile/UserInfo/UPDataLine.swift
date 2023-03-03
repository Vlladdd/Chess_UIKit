//
//  UPDataLine.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

//class that represents line with 1 object of user info
//basically it is just a line with label, which represents name of field,
//and field(data), where user can type new data or choose preferences, in case
//of music/sound, for example, or it also can be not redactable
class UPDataLine: UIStackView {
    
    // MARK: - Properties
    
    private(set) var data: UIView?
    
    private typealias constants = UPDataLine_Constants
    
    // MARK: - Inits
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup() {
        setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
    }
    
    func updateData(with newValue: UIView) {
        data = newValue
    }
    
}

// MARK: - Constants

private struct UPDataLine_Constants {
    static let optimalSpacing = 5.0
}
