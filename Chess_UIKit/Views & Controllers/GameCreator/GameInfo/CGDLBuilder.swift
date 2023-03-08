//
//  CGDLBuilder.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 06.03.2023.
//

import UIKit

//class that represents builder for DataLine for GameInfoView
class CGDLBuilder: CGDataLineBuilder {

    // MARK: - Properties
    
    private typealias constants = CGDLBuilder_Constants
    
    private var product = DataLine()
    
    // MARK: - Methods
    
    func reset() {
        product = DataLine()
    }
    
    func addLabel(with font: UIFont, and text: String, isData: Bool = false) -> Self {
        let label = UILabel()
        label.setup(text: text, alignment: .center, font: font)
        product.addArrangedSubview(label)
        if isData {
            product.updateData(with: label)
            label.labelWithBorderAndCornerRadius()
        }
        return self
    }
    
    func addPicker<T>(with placeholder: String, font: UIFont, data: [T]) -> Self where T: RawRepresentable, T.RawValue == String {
        let picker = Picker(placeholder: placeholder, font: font, data: data)
        product.addArrangedSubview(picker)
        product.updateData(with: picker)
        return self
    }
    
    func addSwitch(with currentState: Bool, and selector: Selector?) -> Self {
        let switcher = UISwitch()
        switcher.defaultSettings(with: selector, isOn: currentState)
        let switchView = makeSpecialViewForSwitch(switcher)
        product.addArrangedSubview(switchView)
        product.updateData(with: switcher)
        return self
    }
    
    func addStepper(with minValue: Double, maxValue: Double, stepValue: Double, and selector: Selector) -> Self {
        let stepper = UIStepper()
        stepper.stepperWith(minValue: minValue, maxValue: maxValue, stepValue: stepValue, and: selector)
        let stepperView = makeSpecialViewForStepper(stepper)
        product.addArrangedSubview(stepperView)
        return self
    }
    
    //returns product at current state and resets it
    func build() -> DataLine {
        let result = product
        reset()
        return result
    }
    
    //stepper is not well animatable
    //by putting it in another view and making layer.masksToBounds = true, we are fixing this problem
    private func makeSpecialViewForStepper(_ stepper: UIStepper) -> UIView {
        let specialView = UIView()
        specialView.translatesAutoresizingMaskIntoConstraints = false
        specialView.layer.masksToBounds = true
        specialView.addSubview(stepper)
        let specialViewConstraints = [stepper.centerXAnchor.constraint(equalTo: specialView.centerXAnchor), stepper.centerYAnchor.constraint(equalTo: specialView.centerYAnchor)]
        NSLayoutConstraint.activate(specialViewConstraints)
        return specialView
    }
    
    //same with switch
    private func makeSpecialViewForSwitch(_ switcher: UISwitch) -> UIView {
        let specialView = UIView()
        specialView.translatesAutoresizingMaskIntoConstraints = false
        specialView.layer.masksToBounds = true
        specialView.addSubview(switcher)
        let specialViewConstraints = [switcher.trailingAnchor.constraint(equalTo: specialView.trailingAnchor, constant: -constants.distanceForSwitchInSpecialView), switcher.centerYAnchor.constraint(equalTo: specialView.centerYAnchor)]
        NSLayoutConstraint.activate(specialViewConstraints)
        return specialView
    }
    
}

// MARK: - Constants

private struct CGDLBuilder_Constants {
    static let optimalSpacing = 5.0
    static let distanceForSwitchInSpecialView = 3.0
}

