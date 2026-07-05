//
//  UserManager.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 06/07/2026.
//
import Foundation
import FirebaseFirestore

struct DbUser {
    let userId: String
    let email : String?
    let photoUrl : String?
    let date_created : Date?
}

final class UserManager {
    
    static let shared = UserManager()
    private init() {}
    
    func createNewUser(auth: AuthDataResultModel) async throws {
        var userData: [String:Any] = [
            "user_id" : auth.uid,
            "date_created" : Timestamp(),
        ]
        if let email = auth.email {
            userData["email"] = email
        }
        if let photoUrl = auth.photoUrl {
            userData["photo_url"] = photoUrl
        }
        
        try await Firestore.firestore().collection("users").document(auth.uid).setData(userData, merge: false)
    }
    
    func getUser(userId: String) async throws -> DbUser {
        let snapshot = try await Firestore.firestore().collection("users").document(userId).getDocument()
        
        guard let data = snapshot.data(), let userId = data["user_id"] as? String else {
            throw URLError(.badServerResponse)
        }
        
        
        let email = data["email"] as? String
        let photoUrl = data["photo_url"] as? String
        let date_created = ["date_created"] as? Date
        
        return DbUser(userId: userId, email: email, photoUrl: photoUrl, date_created: date_created)
    }
    
    
}
