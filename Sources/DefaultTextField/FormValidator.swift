//
//  FormValidator.swift
//  DefaultTextField
//
//  Created by Ademola Fadumo on 21/06/2025.
//

import Foundation

public typealias ValidationRule = (String?) -> Bool

public struct FormValidator {
    public let message: String
    public let validate: ValidationRule

    public init(message: String, validate: @escaping ValidationRule) {
        self.message = message
        self.validate = validate
    }
}
