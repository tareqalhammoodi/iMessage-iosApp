//
//  DatabaseManager.swift
//  iMessage
//
//  Created by Tareq Alhammoodi on 19.06.2023.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
}

// Account Management
extension DatabaseManager {
    
    /// Checks if user exists for given email
       /// Parameters
       /// - `email`:              Target email to be checked
       /// - `completion`:   Async closure to return with result
       public func userExists(with email: String,
                              completion: @escaping ((Bool) -> Void)) {
           
           var safeEmail = email.replacingOccurrences(of: ".", with: "_")
           safeEmail = safeEmail.replacingOccurrences(of: "@", with: "_")

           //let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
           database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
               guard snapshot.value as? [String: Any] != nil else {
                   completion(false)
                   return
               }

               completion(true)
           })

       }
    
    /// Inserts new user to database
    public func insertUser(with user: ChatAppUser) {
        database.child(user.safeEmail).setValue([
            "Name": user.Name,
        ])
    }
}

struct ChatAppUser {
    let Name: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    // let profilePictureURL: String
}
