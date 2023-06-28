//
//  ProfileViewController.swift
//  iMessage
//
//  Created by Tareq Alhammoodi on 17.06.2023.
//

import UIKit
import FirebaseAuth
import SDWebImage

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}

class ProfileViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "\(UserDefaults.standard.value(forKey: "name") as? String ?? "Unknown User")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Logout", handler: { [weak self] in
            let actionSheet = UIAlertController(title: "Logout", message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }
                UserDefaults.standard.setValue(nil, forKey: "name")
                UserDefaults.standard.setValue(nil, forKey: "email")
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    let vc = LoginViewController()
                    let nav = UINavigationController (rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav, animated: true)
                }  catch {
                    print("Failed to log out.")
                }
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self?.present(actionSheet, animated: true)
        }))
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        tableView.separatorColor = UIColor(named: "black_and_gray")
    }
    
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/"+fileName
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 200))
        headerView.backgroundColor = .systemBackground
        let imageView = UIImageView(frame: CGRect(x: (headerView.width-150)/2, y: 45, width: 150, height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .gray
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        headerView.addSubview(imageView)
        StorageManager.shared.downloadURL(for: path, completion: { result in
            switch result {
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        })
        return headerView
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
}

class ProfileTableViewCell: UITableViewCell {
    static let identifier = "ProfileTableViewCell"
    public func setUp(with viewModel: ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .center
            textLabel?.font = UIFont(name:"Avenir-Heavy", size: 20.0)
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
            textLabel?.font = UIFont(name:"Avenir-Heavy", size: 20.0)
        }
    }
}
