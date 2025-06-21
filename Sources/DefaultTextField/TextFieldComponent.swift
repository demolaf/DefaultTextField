//
//  TextFieldComponent.swift
//  DefaultTextField
//
//  Created by Ademola Fadumo on 21/06/2025.
//

import UIKit

public struct TextFieldComponent {
    public init(
        title: String,
        hint: String,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        islabelHidden: Bool = false,
        enabled: Bool = true,
        obscured: Bool = false,
        maintainsValidationMessages: Bool = true,
        showsIconValidationMessage: Bool = false,
        validations: [FormValidator]
    ) {
        self.title = title
        self.hint = hint
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.islabelHidden = islabelHidden
        self.enabled = enabled
        self.obscured = obscured
        self.maintainsValidationMessages = maintainsValidationMessages
        self.showsIconValidationMessage = showsIconValidationMessage
        self.validations = validations
    }

    let title: String
    let hint: String
    var keyboardType: UIKeyboardType
    var textContentType: UITextContentType?
    var islabelHidden: Bool
    var enabled: Bool
    var obscured: Bool
    var maintainsValidationMessages: Bool
    var showsIconValidationMessage: Bool
    let validations: [FormValidator]
}
