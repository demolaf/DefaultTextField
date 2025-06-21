// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit
import RxSwift
import RxRelay
import RxCocoa

public class DefaultTextField: UIView {
    private var contentVStack: UIStackView!
    private(set) var label: UILabel!
    private(set) var textField: UITextField!
    private var obscureButton: UIButton!
    private var validationsVStack: UIStackView!
    
    private(set) var textFieldComponent: TextFieldComponent
    
    public let textEditingValue = BehaviorRelay<String>(value: "")
    public let textFieldValidValue = PublishRelay<Bool>()
    
    let bag = DisposeBag()
    
    public init(textFieldComponent: TextFieldComponent) {
        self.textFieldComponent = textFieldComponent
        super.init(frame: .zero)
        setupContentVStack()
        setupLabel()
        setupTextField()
        setupObscureButton()
        setupValidationsVStack()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupContentVStack() {
        contentVStack = UIStackView()
        contentVStack.axis = .vertical
        contentVStack.spacing = 8
        contentVStack.alignment = .fill
        contentVStack.distribution = .fill
        contentVStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(contentVStack)
        
        NSLayoutConstraint.activate([
            contentVStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentVStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentVStack.topAnchor.constraint(equalTo: topAnchor),
            contentVStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    private func setupLabel() {
        label = UILabel()
        label.text = textFieldComponent.title
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.isHidden = textFieldComponent.islabelHidden
        
        contentVStack.addArrangedSubview(label)
    }
    
    private func setupTextField() {
        textField = UITextField()
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = textFieldComponent.keyboardType
        textField.textContentType = textFieldComponent.textContentType
        textField.defaultTextAttributes = [
            .font: UIFont.systemFont(ofSize: 14)
        ]
        textField.leftViewMode = .always
        textField.rightViewMode = .always
        textField.leftView = UIView(frame: .init(x: 0, y: 0, width: 16, height: 0))
        textField.layer.borderColor = UIColor.systemGray3.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 10
        textField.attributedPlaceholder = NSAttributedString(
            string: textFieldComponent.hint,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14)
            ])
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        contentVStack.addArrangedSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        textField.rx.text.orEmpty
            .bind(to: textEditingValue)
            .disposed(by: bag)
        
        textField.isSecureTextEntry = textFieldComponent.obscured
    }
    
    private func setupObscureButton() {
        let button = UIButton(type: .custom)
        button.tintColor = .label
        button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.addTarget(self, action: #selector(obscureButtonTapped), for: .primaryActionTriggered)
        
        let padding: CGFloat = 32
        let container = UIView(frame: CGRect(x: 0, y: 0, width: button.intrinsicContentSize.width + padding, height: button.intrinsicContentSize.height))
        button.frame = CGRect(x: padding / 2, y: 0, width: button.intrinsicContentSize.width, height: button.intrinsicContentSize.height)
        container.addSubview(button)
        
        textField.rightView = container
        textField.rightViewMode = .always
        
        obscureButton = button
        obscureButton.isHidden = !textFieldComponent.obscured
    }
    
    private func setupValidationsVStack() {
        validationsVStack = UIStackView()
        validationsVStack.axis = .vertical
        validationsVStack.spacing = 4
        validationsVStack.alignment = .fill
        validationsVStack.distribution = .fill
        
        contentVStack.addArrangedSubview(validationsVStack)
        
        // Validate Form
        textEditingValue
            .subscribe(onNext: { [weak self] text in
                self?.validateForm(input: text)
            })
            .disposed(by: bag)
    }
    
    private func validateForm(input: String) {
        validationsVStack.arrangedSubviews.forEach {
            validationsVStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        textFieldComponent.validations.forEach { item in
            if let item = createItem(item: item, input: input) {
                validationsVStack.addArrangedSubview(item)
            }
        }
        
        let isValid = textFieldComponent.validations.allSatisfy { $0.validate(input) }
        textFieldValidValue.accept(isValid)
        
        if input.isEmpty {
            textField.textColor = .label
            obscureButton.tintColor = .label
            textField.layer.borderColor = UIColor.systemGray3.cgColor
        } else if isValid {
            textField.textColor = .label
            obscureButton.tintColor = .label
            textField.layer.borderColor = UIColor.green.cgColor
        } else {
            textField.textColor = .red
            obscureButton.tintColor = .red
            textField.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    private func createItem(item: FormValidator, input: String?) -> UIStackView? {
        guard let input, !input.isEmpty else {
            // Input is empty — do not show validation message
            return nil
        }

        let isValid = item.validate(input)

        // If valid and we're not meant to keep messages for valid cases, return nil
        if isValid && !textFieldComponent.maintainsValidationMessages {
            return nil
        }

        // Proceed to build the validation message
        let titleHStack = UIStackView()
        titleHStack.axis = .horizontal
        titleHStack.spacing = 4
        titleHStack.alignment = .center

        if textFieldComponent.showsIconValidationMessage {
            let iconName = isValid ? "checkmark.circle.fill" : "info.circle"
            let iconColor = isValid ? UIColor.systemGreen : UIColor.red
            
            let iconImage = UIImage(systemName: iconName)
            let iconView = UIImageView(image: iconImage)
            iconView.tintColor = iconColor
            iconView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: 16),
                iconView.heightAnchor.constraint(equalToConstant: 16),
            ])
            
            titleHStack.addArrangedSubview(iconView)
        }
        
        let label = UILabel()
        label.text = item.message
        label.font = .systemFont(ofSize: 14)
        let textColor = isValid ? UIColor.systemGreen : UIColor.red
        label.textColor = textColor
        
        titleHStack.addArrangedSubview(label)

        return titleHStack
    }
    
    @objc private func obscureButtonTapped() {
        debugPrint("Obscure button tapped")
        toggleObscure()
    }
    
    func toggleObscure() {
        textFieldComponent.obscured.toggle()
        debugPrint("Obscured - \(textFieldComponent.obscured)")
        obscureButton.setImage(!textFieldComponent.obscured ? UIImage(systemName: "eye.slash") : UIImage(systemName: "eye"), for: .normal)
        textField.isSecureTextEntry = textFieldComponent.obscured
    }
}

//class DefaultTextField: UIView {
//    struct TextFieldComponent {
//        let title: String
//        let hint: String
//        var islabelHidden: Bool = false
//        var enabled: Bool = true
//        var obscured: Bool = false
//        var maintainsValidationMessages: Bool = true
//        var showsIconValidationMessage: Bool = false
//        let validations: [FormValidators.FormValidator]
//    }
//
//    private var contentVStack: UIStackView!
//    private(set) var label: UILabel!
//    private(set) var textField: UITextField!
//    private var obscureButton: UIButton!
//    private var validationsVStack: UIStackView!
//
//    // Cache validation views to avoid recreation
//    private var validationViews: [UIStackView] = []
//
//    private(set) var textFieldComponent: TextFieldComponent
//
//    let textEditingValue = BehaviorRelay<String>(value: "")
//    let textFieldValidValue = PublishRelay<Bool>()
//
//    let bag = DisposeBag()
//
//    init(textFieldComponent: TextFieldComponent) {
//        self.textFieldComponent = textFieldComponent
//        super.init(frame: .zero)
//        setupContentVStack()
//        setupLabel()
//        setupTextField()
//        setupObscureButton()
//        setupValidationsVStack()
//        createValidationViews() // Pre-create validation views
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError()
//    }
//
//    private func setupContentVStack() {
//        contentVStack = UIStackView()
//        contentVStack.axis = .vertical
//        contentVStack.spacing = 8
//        contentVStack.alignment = .fill
//        contentVStack.distribution = .fill
//        contentVStack.translatesAutoresizingMaskIntoConstraints = false
//
//        addSubview(contentVStack)
//
//        NSLayoutConstraint.activate([
//            contentVStack.leadingAnchor.constraint(equalTo: leadingAnchor),
//            contentVStack.trailingAnchor.constraint(equalTo: trailingAnchor),
//            contentVStack.topAnchor.constraint(equalTo: topAnchor),
//            contentVStack.bottomAnchor.constraint(equalTo: bottomAnchor),
//        ])
//    }
//
//    private func setupLabel() {
//        label = UILabel()
//        label.text = textFieldComponent.title
//        label.font = .systemFont(ofSize: 14, weight: .regular)
//        label.textColor = .label
//        label.isHidden = textFieldComponent.islabelHidden
//
//        contentVStack.addArrangedSubview(label)
//    }
//
//    private func setupTextField() {
//        textField = UITextField()
//        textField.defaultTextAttributes = [
//            .font: UIFont.systemFont(ofSize: 14)
//        ]
//        textField.leftViewMode = .always
//        textField.rightViewMode = .always
//        textField.leftView = UIView(frame: .init(x: 0, y: 0, width: 16, height: 0))
//        textField.layer.borderColor = UIColor.systemGray3.cgColor
//        textField.layer.borderWidth = 1
//        textField.layer.cornerRadius = 10
//        textField.attributedPlaceholder = NSAttributedString(
//            string: textFieldComponent.hint,
//            attributes: [
//                .font: UIFont.systemFont(ofSize: 14)
//            ])
//        textField.autocapitalizationType = .none
//        textField.translatesAutoresizingMaskIntoConstraints = false
//
//        contentVStack.addArrangedSubview(textField)
//
//        NSLayoutConstraint.activate([
//            textField.heightAnchor.constraint(equalToConstant: 44),
//        ])
//
//        textField.rx.text.orEmpty
//            .bind(to: textEditingValue)
//            .disposed(by: bag)
//
//        textField.isSecureTextEntry = textFieldComponent.obscured
//    }
//
//    private func setupObscureButton() {
//        let button = UIButton(type: .custom)
//        button.tintColor = .label
//        button.setImage(UIImage(systemName: "eye"), for: .normal)
//        button.addTarget(self, action: #selector(obscureButtonTapped), for: .primaryActionTriggered)
//
//        let padding: CGFloat = 32
//        let container = UIView(frame: CGRect(x: 0, y: 0, width: button.intrinsicContentSize.width + padding, height: button.intrinsicContentSize.height))
//        button.frame = CGRect(x: padding / 2, y: 0, width: button.intrinsicContentSize.width, height: button.intrinsicContentSize.height)
//        container.addSubview(button)
//
//        textField.rightView = container
//        textField.rightViewMode = .always
//
//        obscureButton = button
//        obscureButton.isHidden = !textFieldComponent.obscured
//    }
//
//    private func setupValidationsVStack() {
//        validationsVStack = UIStackView()
//        validationsVStack.axis = .vertical
//        validationsVStack.spacing = 4
//        validationsVStack.alignment = .fill
//        validationsVStack.distribution = .fill
//
//        contentVStack.addArrangedSubview(validationsVStack)
//
//        // Validate Form with debouncing to reduce flashing
//        textEditingValue
//            .subscribe(onNext: { [weak self] text in
//                self?.validateForm(input: text)
//            })
//            .disposed(by: bag)
//    }
//
//    // Pre-create validation views to avoid recreation
//    private func createValidationViews() {
//        validationViews = textFieldComponent.validations.map { validator in
//            let titleHStack = UIStackView()
//            titleHStack.axis = .horizontal
//            titleHStack.spacing = 4
//            titleHStack.alignment = .center
//            titleHStack.isHidden = true // Initially hidden
//
//            if textFieldComponent.showsIconValidationMessage {
//                let iconView = UIImageView()
//                iconView.translatesAutoresizingMaskIntoConstraints = false
//                NSLayoutConstraint.activate([
//                    iconView.widthAnchor.constraint(equalToConstant: 16),
//                    iconView.heightAnchor.constraint(equalToConstant: 16),
//                ])
//                titleHStack.addArrangedSubview(iconView)
//            }
//
//            let label = UILabel()
//            label.text = validator.message
//            label.font = .systemFont(ofSize: 14)
//            titleHStack.addArrangedSubview(label)
//
//            // Add to stack view but keep hidden initially
//            validationsVStack.addArrangedSubview(titleHStack)
//
//            return titleHStack
//        }
//    }
//
//    private func validateForm(input: String) {
//        let isValid = textFieldComponent.validations.allSatisfy { $0.validate(input) }
//        textFieldValidValue.accept(isValid)
//
//        // Animate validation view changes
//        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
//            // Update validation views without recreating them
//            for (index, validator) in self.textFieldComponent.validations.enumerated() {
//                guard index < self.validationViews.count else { continue }
//
//                let validationView = self.validationViews[index]
//                let validatorIsValid = validator.validate(input)
//
//                // Determine if this validation should be shown
//                let shouldShow = !input.isEmpty && (!validatorIsValid || self.textFieldComponent.maintainsValidationMessages)
//
//                if shouldShow {
//                    // Update icon if present
//                    if self.textFieldComponent.showsIconValidationMessage,
//                       let iconView = validationView.arrangedSubviews.first as? UIImageView {
//                        let iconName = validatorIsValid ? "checkmark.circle.fill" : "info.circle"
//                        let iconColor = validatorIsValid ? UIColor.systemGreen : UIColor.red
//                        iconView.image = UIImage(systemName: iconName)
//                        iconView.tintColor = iconColor
//                    }
//
//                    // Update label color
//                    if let label = validationView.arrangedSubviews.last as? UILabel {
//                        let textColor = validatorIsValid ? UIColor.systemGreen : UIColor.red
//                        label.textColor = textColor
//                    }
//
//                    // Animate fade in if currently hidden
//                    if validationView.isHidden {
//                        validationView.alpha = 0
//                        validationView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
//                        validationView.isHidden = false
//                        validationView.alpha = 1
//                        validationView.transform = .identity
//                    }
//                } else {
//                    // Animate fade out with scale
//                    validationView.alpha = 0
//                    validationView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
//                }
//            }
//
//            // Animate text field styling changes
//            self.animateTextFieldStyling(input: input, isValid: isValid)
//
//            // Force layout update for smooth animation
//            self.layoutIfNeeded()
//        } completion: { _ in
//            // Hide views that should be hidden after animation completes
//            for (index, validator) in self.textFieldComponent.validations.enumerated() {
//                guard index < self.validationViews.count else { continue }
//
//                let validationView = self.validationViews[index]
//                let validatorIsValid = validator.validate(input)
//                let shouldShow = !input.isEmpty && (!validatorIsValid || self.textFieldComponent.maintainsValidationMessages)
//
//                if !shouldShow {
//                    validationView.isHidden = true
//                    validationView.alpha = 1 // Reset alpha for next show
//                    validationView.transform = .identity // Reset transform for next show
//                }
//            }
//        }
//    }
//
//    private func animateTextFieldStyling(input: String, isValid: Bool) {
//        let targetBorderColor: UIColor
//        let targetTextColor: UIColor
//        let targetButtonTintColor: UIColor
//
//        if input.isEmpty {
//            targetBorderColor = .systemGray3
//            targetTextColor = .label
//            targetButtonTintColor = .label
//        } else if isValid {
//            targetBorderColor = .green
//            targetTextColor = .label
//            targetButtonTintColor = .label
//        } else {
//            targetBorderColor = .red
//            targetTextColor = .red
//            targetButtonTintColor = .red
//        }
//
//        // Animate border color change
//        let borderColorAnimation = CABasicAnimation(keyPath: "borderColor")
//        borderColorAnimation.fromValue = textField.layer.borderColor
//        borderColorAnimation.toValue = targetBorderColor.cgColor
//        borderColorAnimation.duration = 0.2
//        borderColorAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//        textField.layer.add(borderColorAnimation, forKey: "borderColorAnimation")
//        textField.layer.borderColor = targetBorderColor.cgColor
//
//        // Animate text color and button tint
//        textField.textColor = targetTextColor
//        obscureButton.tintColor = targetButtonTintColor
//    }
//
//    @objc private func obscureButtonTapped() {
//        debugPrint("Obscure button tapped")
//        toggleObscure()
//    }
//
//    func toggleObscure() {
//        textFieldComponent.obscured.toggle()
//        obscureButton.setImage(textFieldComponent.obscured ? UIImage(systemName: "eye.slash") : UIImage(systemName: "eye"), for: .normal)
//        textField.isSecureTextEntry = textFieldComponent.obscured
//    }
//}
