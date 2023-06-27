//
//  StorageManager.swift
//  iMessage
//
//  Created by Tareq Alhammoodi on 22.06.2023.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    // uploading profile picture....
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                print("failed to upload profile picture to firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self?.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    // uploading picture message....
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                print("failed to upload picture message to firebase ")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    // uploading video message....
    public func uploadMessageVideo(with fileURL: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"
        if let videoData = NSData(contentsOf: fileURL) as Data? {
            storage.child("message_videos/\(fileName)").putData(videoData, metadata: metadata, completion: { [weak self] metadata, error in
                guard error == nil else {
                    print("failed to upload video to firebase")
                    completion(.failure(StorageErrors.failedToUpload))
                    return
                }
                self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                    guard let url = url else {
                        print("failed to get download url")
                        completion(.failure(StorageErrors.failedToGetDownloadUrl))
                        return
                    }
                    let urlString = url.absoluteString
                    print("download url returned: \(urlString)")
                    completion(.success(urlString))
                })
            })
        }
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        })
    }
}
