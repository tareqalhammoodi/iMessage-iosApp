//
//  ChatViewController.swift
//  iMessage
//
//  Created by Tareq Alhammoodi on 21.06.2023.
//

import UIKit
import AVKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import CoreLocation

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}

class ChatViewController: MessagesViewController {
    
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = Locale.init(identifier: "en_US")
        return formatter
    }()
    
    public let otherUserEmail: String
    private var conversationID: String?
    public var isNewConversation = false
    private var messages = [Message]()

    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.conversationID = id
        super.init(nibName: nil, bundle: nil)
        if let conversationid = conversationID {
            updateMessages(id: conversationid, shouldScrollToBottom: true)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 50, height: 50), animated: false)
        button.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        button.tintColor = UIColor(named: "black_and_white")
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        // camera
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                picker.allowsEditing = true
                self?.present(picker, animated: true)
            } else {
                print("camera is not available!")
            }
        }
        cameraAction.setValue(UIImage(systemName: "camera"), forKey: "image")
        actionSheet.addAction(cameraAction)
        // photo gallery
        let photoAction = UIAlertAction(title: "Photo Gallery", style: .default) { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }
        photoAction.setValue(UIImage(systemName: "photo.stack"), forKey: "image")
        actionSheet.addAction(photoAction)
        // video
        let videoAction = UIAlertAction(title: "Video", style: .default) { [weak self] _ in
            self?.presentVideoInputActionsheet()
        }
        videoAction.setValue(UIImage(systemName: "video"), forKey: "image")
        actionSheet.addAction(videoAction)
        // audio
        let audioAction = UIAlertAction(title: "Audio", style: .default) { [weak self] _ in
            print("Audio....")
        }
        audioAction.setValue(UIImage(systemName: "waveform"), forKey: "image")
        actionSheet.addAction(audioAction)
        // location
        let locationAction = UIAlertAction(title: "Location", style: .default) { [weak self] _ in
            self?.presentLocationPicker()
        }
        locationAction.setValue(UIImage(systemName: "location"), forKey: "image")
        actionSheet.addAction(locationAction)
        // cancel
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionsheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Where would you like to attach a video from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            self?.present(picker, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoorindates in
            
            guard let strongSelf = self else {
                return
            }
            
            guard let messageId = strongSelf.createMessageID(),
                  let conversationId = strongSelf.conversationID,
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender else {
                return
            }
            
            let longitude: Double = selectedCoorindates.longitude
            let latitude: Double = selectedCoorindates.latitude
            
            print("long=\(longitude) | lat= \(latitude)")
            
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            let message = Message(sender: selfSender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                if success {
                    print("sent location message")
                }
                else {
                    print("failed to send location message")
                }
            })
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
    }
    
    private func updateMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversations(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    print("there are no messages!")
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        })
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let selfSender = self.selfSender,
        let messageID = createMessageID() else {
            return
        }
        print("Sending: \(text)")
        // Send Message
        let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .text(text))
        if isNewConversation {
            // create conversation in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                    let newConversationID = "conversation_\(message.messageId)"
                    self?.conversationID = newConversationID
                    self?.updateMessages(id: newConversationID, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = nil
                } else {
                    print("failed to send")
                }
            })
        } else {
            // append to existing conversation data
            guard let conversationID = conversationID, let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: otherUserEmail, name: name, newMessage: message, completion: { [weak self] success in
                if success {
                    print("message sent")
                    self?.messageInputBar.inputTextView.text = nil
                } else {
                    print("failed to send")
                }
            })
        }
    }
    
    private func createMessageID() -> String? {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newID = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        return newID
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageID(),
              let conversationId = conversationID,
              let name = self.title,
              let selfSender = selfSender else {
            return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData =  image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            // Upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    // Ready to send message
                    print("Uploaded Message Photo: \(urlString)")
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "square.slash") else {
                        return
                    }
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                        if success {
                            print("sent photo message")
                        } else {
                            print("failed to send photo message")
                        }
                    })
                case .failure(let error):
                    print("message photo upload error: \(error)")
                }
            })
        } else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            // Upload Video
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    // Ready to send message
                    print("Uploaded Message Video: \(urlString)")
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "square.slash") else {
                        return
                    }
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                        if success {
                            print("sent video message")
                        } else {
                            print("failed to send video message")
                        }
                    })
                case .failure(let error):
                    print("message video upload error: \(error)")
                }
            })
        }
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil, email should be cached.")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            imageView.sd_setImage(with: imageURL, completed: nil)
        default:
            break
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            // our message that we've sent
            return .link
        }
        return .secondarySystemBackground
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            // show our image
            if let currentUserImageURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserImageURL, completed: nil)
            } else {
                // images/safeemail_profile_picture.png
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                // fetch url
                StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.senderPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            }
        } else {
            // other user image
            if let otherUsrePHotoURL = self.otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUsrePHotoURL, completed: nil)
            } else {
                // fetch url
                let email = self.otherUserEmail
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                // fetch url
                StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.otherUserPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            }
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageURL)
            let navVC = UINavigationController(rootViewController: vc)
            present(navVC, animated: true)
        case .video(let media):
            guard let videoURL = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoURL)
            present(vc, animated: true)
        default:
            break
        }
    }
}
