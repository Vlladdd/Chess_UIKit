//
//  SegmentData.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 05.07.2022.
//

import Foundation
import QuartzCore

//struct that represents data of the angle of the wheel
struct SegmentData: Equatable {
    
    // MARK: - Properties
    
    let layer: CAShapeLayer
    let angle: CGFloat
    let coinsPrize: Int
    
}
