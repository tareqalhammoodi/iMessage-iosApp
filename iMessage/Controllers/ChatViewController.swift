//
//  ChatViewController.swift
//  iMessage
//
//  Created by Tareq Alhammoodi on 21.06.2023.
//

import UIKit
import MessageKit

struct Message: MessageType {
    var sender: MessageKit.SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKit.MessageKind
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

class ChatViewController: MessagesViewController {
    
    private var messages = [Message]()
    
    private let selfSender = Sender(photoURL: "", senderId: "1", displayName: "Sarah Lusine")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Lorem ipsum dolor sit amet, sit consectetur adipiscing elit, sed do sunt eiusmod tempor")))
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Sed ut perspiciatis unde omnis  natus error sit voluptatem accusantium doloremque eaque")))

        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> MessageKit.SenderType {
        selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
