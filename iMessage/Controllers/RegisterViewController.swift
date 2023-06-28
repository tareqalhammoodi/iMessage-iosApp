//
//  RegisterViewController.swift
//  iMessage
//
//  Created by Tareq Alhammoodi on 17.06.2023.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create a new account"
        label.textAlignment = .left
        label.textColor = UIColor(named: "black_and_white")
        label.font = UIFont(name:"Avenir-Medium", size: 24.0)
        return label
    }()
    
    private let tLabel: UILabel = {
        let label = UILabel()
        label.text = "Create an account to enjoy using iMessage."
        label.textAlignment = .left
        label.textColor = UIColor(named: "black_and_white")
        label.font = UIFont(name:"Avenir-Light", size: 16.0)
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.crop.circle")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.tintColor = .gray
        return imageView
    }()

    private let NameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.attributedPlaceholder = NSAttributedString(string: "Name and Surname", attributes: [NSAttributedString.Key.font: UIFont(name:"Avenir-Light", size: 16.0) as Any])
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .clear
        return field
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

    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Create an account", for: .normal)
        button.backgroundColor = UIColor(named: "black_and_gray")
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont(name:"Avenir-Black", size: 18.0)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        registerButton.addTarget(self,
                              action: #selector(registerButtonTapped),
                              for: .touchUpInside)

        emailField.delegate = self
        passwordField.delegate = self

        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(titleLabel)
        scrollView.addSubview(tLabel)
        scrollView.addSubview(imageView)
        scrollView.addSubview(NameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)

        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true

        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(didTapChangeProfilePic))
        imageView.addGestureRecognizer(gesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds

        let size = scrollView.width/3
        titleLabel.frame = CGRect(x: 30,
                                    y: scrollView.top+50,
                                    width: scrollView.width-60,
                                    height: 35)
        tLabel.frame = CGRect(x: 30,
                                    y: titleLabel.bottom-10,
                                    width: scrollView.width-60,
                                    height: 35)
        
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: tLabel.bottom+10,
                                 width: size,
                                 height: size)

        imageView.layer.cornerRadius = imageView.width/2.0

        NameField.frame = CGRect(x: 30,
                                  y: imageView.bottom+10,
                                  width: scrollView.width-60,
                                  height: 35)
        emailField.frame = CGRect(x: 30,
                                  y: NameField.bottom+20,
                                  width: scrollView.width-60,
                                  height: 35)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+20,
                                     width: scrollView.width-60,
                                     height: 35)
        registerButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom+40,
                                   width: scrollView.width-60,
                                   height: 45)
        
        NameField.addBottomBorder(color: .gray, width: 0.5)
        emailField.addBottomBorder(color: .gray, width: 0.5)
        passwordField.addBottomBorder(color: .gray, width: 0.5)

    }
    
    @objc private func registerButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        NameField.resignFirstResponder()
        
        guard let Name = NameField.text,
              let emailAddress = emailField.text,
              let password = passwordField.text,
              !emailAddress.isEmpty,
              !password.isEmpty,
              !Name.isEmpty,
              password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        // Firebase Register
        
        DatabaseManager.shared.userExists(with: emailAddress, completion: { [weak self] exists in
            guard let strongSelf = self else {
                return
            }
            
            guard !exists else {
                // user already exists
                strongSelf.alertUserLoginError(message: "Looks like a user account for that email address already exists.")
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: emailAddress, password: password, completion: { authResult, error in
                guard authResult != nil, error == nil else {
                    print("Error cureating user")
                    return
                }
                UserDefaults.standard.setValue(Name, forKey: "name")
                UserDefaults.standard.setValue(emailAddress, forKey: "email")
                let chatUser = ChatAppUser(Name: Name, emailAddress: emailAddress)
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success {
                        // upload image
                        guard let image = strongSelf.imageView.image,
                              let data = image.pngData() else {
                            return
                        }
                        let fileName = chatUser.profilePictureFileName
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                            switch result {
                            case .success(let downloadURL):
                                UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                print(downloadURL)
                            case .failure(let error):
                                print("Storage manager error: \(error)")
                            }
                        })
                    }
                })
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
    
    @objc private func didTapChangeProfilePic() {
        presentPhotoActionSheet()
    }

    func alertUserLoginError(message: String = "Please enter all information to create a new account.") {
        let alert = UIAlertController(title: "Woops",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:"Dismiss",
                                      style: .cancel, handler: nil))
        present(alert, animated: true)
    }

}

extension RegisterViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            registerButtonTapped()
        }

        return true
    }

}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How would you like to select a picture?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in

                                                self?.presentCamera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Chose Photo",
                                            style: .default,
                                            handler: { [weak self] _ in

                                                self?.presentPhotoPicker()
        }))

        present(actionSheet, animated: true)
    }

    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }

    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.imageView.image = selectedImage
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

}
