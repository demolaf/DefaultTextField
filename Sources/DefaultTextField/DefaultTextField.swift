// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit
import RxSwift
import RxRelay
import RxCocoa

public class DefaultTextField: UIView {
    private var contentVStack: UIStackView!
    private(set) var label: UILabel!
    public var textField: UITextField!
    private var obscureButton: UIButton!
    private var validationsVStack: UIStackView!
    
    public var textFieldComponent: TextFieldComponent
    
    private let textEditingValue = BehaviorRelay<String?>(value: nil)
    private let textFieldFormValid = BehaviorRelay<Bool>(value: false)
    
    public var textEditingState: Observable<String?> {
        textEditingValue
            .distinctUntilChanged()
            .asObservable()
    }
    
    public var textValue: String? {
        textEditingValue.value
    }
    
    public var formValidState: Observable<Bool> {
        textFieldFormValid
            .distinctUntilChanged()
            .asObservable()
    }
    
    public var formValidValue: Bool {
        textFieldFormValid.value
    }
    
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
        
        textField.rx.text
            .skip(1)
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
                if let text {
                    self?.validateForm(input: text)
                }
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
        textFieldFormValid.accept(isValid)
        
        if input.isEmpty {
            textField.tintColor = .label
            textField.textColor = .label
            obscureButton.tintColor = .label
            textField.layer.borderColor = UIColor.systemGray3.cgColor
        } else if isValid {
            textField.tintColor = .label
            textField.textColor = .label
            obscureButton.tintColor = .label
            textField.layer.borderColor = UIColor.green.cgColor
        } else {
            textField.tintColor = .red
            textField.textColor = .red
            obscureButton.tintColor = .red
            textField.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    private func createItem(item: FormValidator, input: String) -> UIStackView? {
        guard textFieldComponent.validateWhenEmpty || !input.isEmpty else {
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
    
    public func revalidateIfNeeded() {
        validateForm(input: textEditingValue.value ?? "")
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
