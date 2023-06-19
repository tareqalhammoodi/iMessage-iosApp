//
//  LoginViewController.swift
//  iMessage
//
//  Created by Tareq Alhammoodi on 17.06.2023.
//

import UIKit

class LoginViewController: UIViewController {
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome!"
        label.textAlignment = .left
        label.textColor = .black
        label.font = UIFont(name:"Avenir-Heavy", size: 24.0)
        return label
    }()
    
    private let tLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter your email and password to login."
        label.textAlignment = .left
        label.textColor = .black
        label.font = UIFont(name:"Avenir-Light", size: 16.0)
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.attributedPlaceholder = NSAttributedString(string: "E-Mail", attributes: [NSAttributedString.Key.font: UIFont(name:"Avenir-Light", size: 16.0) as Any])
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .clear
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.font: UIFont(name:"Avenir-Light", size: 16.0) as Any])
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .clear
        field.isSecureTextEntry = true
        return field
    }()
    
    private let forgotPasswordButton: UIButton = {
        let button = UIButton()
        button.setTitle("Forgot Password?", for: .normal)
        button.contentHorizontalAlignment = .right
        button.backgroundColor = .clear
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont(name:"Avenir-Heavy", size: 16.0)
        return button
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont(name:"Avenir-Black", size: 18.0)
        return button
    }()
    
    private let createAccountLabel: UILabel = {
        let label = UILabel()
        label.text = "Don’t have an account? Create new one."
        label.textAlignment = .center
        label.textColor = .black
        label.font = UIFont(name:"Avenir-Light", size: 16.0)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        loginButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside
        )
        
        forgotPasswordButton.addTarget(self,
                                       action: #selector(forgotPasswordButtonTapped),
                                       for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(welcomeLabel)
        scrollView.addSubview(tLabel)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(forgotPasswordButton)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(createAccountLabel)
        
        // to make UILabel clickable
        createAccountLabel.isUserInteractionEnabled = true
        let fullText = createAccountLabel.text
        let attributedString = NSMutableAttributedString(string: fullText!)
        
        // Create a clickable range for "Create new one"
        let clickableRange = (fullText! as NSString).range(of: "Create new one")
        
        // Define the attributes for the clickable range
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name:"Avenir-Heavy", size: 16.0) as Any,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        // Apply the attributes to the clickable range
        attributedString.addAttributes(attributes, range: clickableRange)
        
        // Assign the attributed string to the label's text
        createAccountLabel.attributedText = attributedString
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(createAccountLabelTapped))
        createAccountLabel.addGestureRecognizer(tapGesture)
        
    }
    
    override func viewDidLayoutSubviews () {
        super.viewDidLayoutSubviews ()
        scrollView.frame = view.bounds
                
        welcomeLabel.frame = CGRect(x: 30,
                                    y: scrollView.top+50,
                                    width: scrollView.width-60,
                                    height: 35)
        tLabel.frame = CGRect(x: 30,
                                    y: welcomeLabel.bottom-10,
                                    width: scrollView.width-60,
                                    height: 35)
        emailField.frame = CGRect(x: 30,
                                   y: tLabel.bottom+20,
                                   width: scrollView.width-60,
                                   height: 35)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+20,
                                     width: scrollView.width-60,
                                     height: 35)
        forgotPasswordButton.frame = CGRect(x: 30,
                                    y: passwordField.bottom+20,
                                    width: scrollView.width-60,
                                    height: 35)
        loginButton.frame = CGRect(x: 30,
                                   y: forgotPasswordButton.bottom+20,
                                   width: scrollView.width-60,
                                   height: 45)
        createAccountLabel.frame = CGRect(x: 30,
                                    y: loginButton.top+325,
                                    width: scrollView.width-60,
                                    height: 35)
        
        emailField.addBottomBorder(color: .gray, width: 0.5)
        passwordField.addBottomBorder(color: .gray, width: 0.5)
    }
    
    @objc private func loginButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
    }
    
    @objc private func forgotPasswordButtonTapped() {
        print("button clicked")
    }
    
    @objc private func createAccountLabelTapped() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
     }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all information to log in.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:"Dismiss",
                                      style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}
