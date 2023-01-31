//
//  SmartTextField.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.12.2022.
//

import UIKit

//class that represents custom textField with max characters enabled
class SmartTextField: UITextField, UITextFieldDelegate {
    
    // MARK: - Properties
    
    private let maxCharacters: Int
    private let sendButton: UIButton
    
    private typealias constants = ChatTextField_Constants
    
    // MARK: - Inits
    
    init(maxCharacters: Int, sendButton: UIButton) {
        self.maxCharacters = maxCharacters
        self.sendButton = sendButton
        super.init(frame: .zero)
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text, let rangeOfTextToReplace = Range(range, in: textFieldText) else {
            sendButton.isEnabled = false
            return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        if count == 0 {
            sendButton.isEnabled = false
        }
        else if WSManager.getSharedInstance()?.connectedToWSServer ?? false {
            sendButton.isEnabled = true
        }
        if count == maxCharacters {
            //a little animation, to indicate to the user, that he reached limit of characters for the message
            Timer.scheduledTimer(withTimeInterval: constants.timeToRemoveLastCharacter, repeats: false, block: { _ in
                textField.deleteBackward()
            })
        }
        else if count > maxCharacters {
            let newTextFieldText = textFieldText.replacingCharacters(in: rangeOfTextToReplace, with: string).prefix(maxCharacters - 1)
            textField.text = String(newTextFieldText)
            //moves cursor to the end of the message
            //can`t modify here, so we need a little delay
            Task {
                let newPosition = textField.endOfDocument
                textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
            }
        }
        return count <= maxCharacters
    }

}

// MARK: - Constants

private struct ChatTextField_Constants {
    static let timeToRemoveLastCharacter = 0.1
}
