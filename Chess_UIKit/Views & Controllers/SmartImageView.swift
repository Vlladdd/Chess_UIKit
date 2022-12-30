//
//  SmartImageView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 29.12.2022.
//

import UIKit

//class that represents custom UIImageView without intrinsicContentSize
class SmartImageView: UIImageView {
    
    // MARK: - Properties
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    
}
