//
//  UPDLBuilder.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.02.2023.
//

import UIKit

//class that represents builder for UPDataLine
class UPDLBuilder: UPDataLineBuilder {
    
    // MARK: - Properties
    
    private var product = UPDataLine()
    
    // MARK: - Methods
    
    func reset() {
        product = UPDataLine()
    }
    
    func addLabel(with font: UIFont, and text: String) -> Self {
        let lineName = UILabel()
        lineName.setup(text: text, alignment: .center, font: font)
        product.addArrangedSubview(lineName)
        return self
    }
    
    func addTextField(with font: UIFont, placeHolder: String, and startValue: String?, isNotifView: Bool) -> Self {
        let lineField = UITextField()
        lineField.setup(placeholder: placeHolder, font: font)
        lineField.text = startValue
        if isNotifView {
            let viewWithNI = ViewWithNotifIcon(mainView: lineField, height: nil)
            product.addArrangedSubview(viewWithNI)
            product.updateData(with: viewWithNI)
        }
        else {
            product.addArrangedSubview(lineField)
            product.updateData(with: lineField)
        }
        return self
    }
    
    //basically just scrollable UILabel
    func addTextData(with font: UIFont, and text: String) -> Self {
        let lineDataScrollView = UIScrollView()
        lineDataScrollView.translatesAutoresizingMaskIntoConstraints = false
        lineDataScrollView.delaysContentTouches = false
        let lineData = UILabel()
        lineData.setup(text: text, alignment: .center, font: font)
        lineDataScrollView.addSubview(lineData)
        let widthConstraintForLineData = lineData.widthAnchor.constraint(equalTo: lineDataScrollView.widthAnchor)
        widthConstraintForLineData.priority = .defaultLow
        let centerXConstraintForLineData = lineData.centerXAnchor.constraint(equalTo: lineDataScrollView.centerXAnchor)
        centerXConstraintForLineData.priority = .defaultLow
        let centerYConstraintForLineData = lineData.centerYAnchor.constraint(equalTo: lineDataScrollView.centerYAnchor)
        centerYConstraintForLineData.priority = .defaultLow
        let lineDataConstraints = [lineData.leadingAnchor.constraint(equalTo: lineDataScrollView.leadingAnchor), lineData.trailingAnchor.constraint(equalTo: lineDataScrollView.trailingAnchor), lineData.topAnchor.constraint(equalTo: lineDataScrollView.topAnchor), lineData.bottomAnchor.constraint(equalTo: lineDataScrollView.bottomAnchor), lineData.heightAnchor.constraint(equalTo: lineDataScrollView.heightAnchor), widthConstraintForLineData, centerXConstraintForLineData, centerYConstraintForLineData]
        NSLayoutConstraint.activate(lineDataConstraints)
        product.addArrangedSubview(lineDataScrollView)
        return self
    }
    
    func addSwitch(with currentState: Bool, and selector: Selector) -> Self {
        let switcher = UISwitch()
        switcher.defaultSettings(with: selector, isOn: currentState)
        //better for animations
        let switcherView = UIView()
        switcherView.translatesAutoresizingMaskIntoConstraints = false
        switcherView.addSubview(switcher)
        let switchConstraints = [switcher.trailingAnchor.constraint(equalTo: switcherView.trailingAnchor), switcher.centerYAnchor.constraint(equalTo: switcherView.centerYAnchor)]
        NSLayoutConstraint.activate(switchConstraints)
        product.addArrangedSubview(switcherView)
        return self
    }
    
    //returns product at current state and resets it
    func build() -> UPDataLine {
        let result = self.product
        reset()
        return result
    }
    
}
