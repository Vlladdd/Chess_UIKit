//
//  Showcase.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.02.2023.
//

import UIKit

//class that represents showcase of items
class Showcase: UIScrollView, ItemView {
    
    // MARK: - ItemView
    
    let item: GameItem
    
    // MARK: - Properties
    
    private typealias constants = Showcase_Constants
    
    // MARK: - Inits
    
    init(items: UIStackView, item: GameItem, axis: NSLayoutConstraint.Axis) {
        self.item = item
        super.init(frame: .zero)
        setup(with: items, and: axis)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup(with items: UIStackView, and axis: NSLayoutConstraint.Axis) {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(items)
        let widthConstraint = items.widthAnchor.constraint(equalTo: widthAnchor)
        let heightConstraint = items.heightAnchor.constraint(equalTo: heightAnchor)
        var itemsConstraints = [NSLayoutConstraint]()
        if axis == .vertical {
            widthConstraint.priority = .defaultLow
            itemsConstraints += [items.leadingAnchor.constraint(equalTo: leadingAnchor, constant: constants.optimalDistance), items.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -constants.optimalDistance), items.centerYAnchor.constraint(equalTo: centerYAnchor), items.topAnchor.constraint(equalTo: topAnchor, constant: constants.distanceForContentInHorizontalShowcase), items.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -constants.distanceForContentInHorizontalShowcase), widthConstraint]
        }
        else {
            heightConstraint.priority = .defaultLow
            itemsConstraints += [items.topAnchor.constraint(equalTo: topAnchor, constant: constants.optimalDistance), items.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -constants.optimalDistance), items.leadingAnchor.constraint(equalTo: leadingAnchor, constant: constants.optimalDistance), items.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -constants.optimalDistance), items.centerXAnchor.constraint(equalTo: centerXAnchor), heightConstraint]
        }
        NSLayoutConstraint.activate(itemsConstraints)
    }
    
}

// MARK: - Constants

private struct Showcase_Constants {
    static let optimalDistance = 10.0
    static let distanceForContentInHorizontalShowcase = 20.0
}
