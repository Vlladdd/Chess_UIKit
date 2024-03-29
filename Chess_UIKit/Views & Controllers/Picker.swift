//
//  Picker.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 15.09.2022.
//

import UIKit

// MARK: - PickerDelegate

protocol PickerDelegate: AnyObject {
    func pickerDidTriggerDoneAction<T>(_ picker: Picker<T>) -> Void where T: RawRepresentable, T.RawValue == String
    func pickerDidTriggerCancelAction<T>(_ picker: Picker<T>) -> Void where T: RawRepresentable, T.RawValue == String
}

extension PickerDelegate {
    
    func pickerDidTriggerCancelAction<T>(_ picker: Picker<T>) where T: RawRepresentable, T.RawValue == String {
        print("picker of type \(type(of: picker)) has been closed")
    }
    
}

// MARK: - Picker

//class that represents picker for string enums
class Picker<T>: UITextField, UIPickerViewDataSource, UIPickerViewDelegate where T: RawRepresentable, T.RawValue == String {
    
    // MARK: - Properties
    
    weak var pickerDelegate: PickerDelegate?
    
    var pickedData: T?
    
    //textField have some problems with animations
    //by making this 2 labels to represent placeholder and actual text, we are fixing this problem
    private let textView = UILabel()
    private let placeHolderView = UILabel()
    private let data: [T]
    //size is random, without it, it will make unsatisfied constraints errors
    private let toolbar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 44.0)))
    
    private typealias constants = Picker_Constants
    
    // MARK: - Button Methods
    
    @objc private func donePicker(_ sender: UIBarButtonItem? = nil) {
        resignFirstResponder()
        pickedData = pickedData == nil ? data.first : pickedData
        textView.text = pickedData?.asString
        placeHolderView.text = ""
        pickerDelegate?.pickerDidTriggerDoneAction(self)
    }
    
    @objc private func cancelPicker(_ sender: UIBarButtonItem? = nil) {
        resignFirstResponder()
        pickerDelegate?.pickerDidTriggerCancelAction(self)
    }
    
    // MARK: - Inits
    
    init(placeholder: String, font: UIFont, data: [T]) {
        self.data = data
        super.init(frame: .zero)
        self.font = font
        setup(placeholder: placeholder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    //don't allows user to paste any data, only pick from prepared
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
         if action == #selector(UIResponderStandardEditActions.paste(_:)) {
             return false
         }
         return super.canPerformAction(action, withSender: sender)
    }
    
    private func setup(placeholder: String) {
        setup(placeholder: "", font: font!)
        textView.setup(text: "", alignment: .center, font: font!)
        placeHolderView.setup(text: placeholder, alignment: .center, font: font!)
        placeHolderView.textColor = constants.placeholderColor
        addSubview(placeHolderView)
        addSubview(textView)
        let toolbarBackgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        let toolbarBackground = toolbarBackgroundColor.image()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.setBackgroundImage(toolbarBackground, forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(toolbarBackground, forToolbarPosition: .any)
        tintColor = .clear
        textAlignment = .center
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancelPicker))
        toolbar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        inputView = picker
        inputAccessoryView = toolbar
        let textViewConstraints = [textView.centerXAnchor.constraint(equalTo: centerXAnchor), textView.centerYAnchor.constraint(equalTo: centerYAnchor), placeHolderView.centerXAnchor.constraint(equalTo: centerXAnchor), placeHolderView.centerYAnchor.constraint(equalTo: centerYAnchor), textView.heightAnchor.constraint(equalTo: heightAnchor), textView.widthAnchor.constraint(equalTo: widthAnchor), placeHolderView.heightAnchor.constraint(equalTo: heightAnchor), placeHolderView.widthAnchor.constraint(equalTo: widthAnchor)]
        NSLayoutConstraint.activate(textViewConstraints)
        if data.count == 1 {
            pickedData = data.first
            textView.text = pickedData?.asString
            placeHolderView.text = ""
            isEnabled = false
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data[row].asString
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickedData = data[row]
    }
    
}

// MARK: - Constants

private struct Picker_Constants {
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let placeholderColor = UIColor.red.withAlphaComponent(optimalAlpha)
}
