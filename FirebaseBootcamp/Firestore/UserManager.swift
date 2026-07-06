//
//  UserManager.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 06/07/2026.
//
import Foundation
import FirebaseFirestore
import FirebaseSharedSwift

struct DbUser: Codable {
    let userId: String
    let email : String?
    let photoUrl : String?
    let date_created : Date?
    let isPremium: Bool?
    
    init(auth: AuthDataResultModel) {
        self.userId = auth.uid
        self.email = auth.email
        self.photoUrl = auth.photoUrl
        self.date_created = Date()
        self.isPremium = false
    }
    
    init(userId: String, email : String? = nil, photoUrl : String? = nil, date_created : Date? = nil , isPremium: Bool? = nil) {
        self.userId = userId
        self.email = email
        self.photoUrl = photoUrl
        self.date_created = date_created
        self.isPremium = isPremium
    }
    
//    mutating func togglePremiumStatus() {
//        let currentPremiumStatus = isPremium ?? false
//        isPremium = !currentPremiumStatus
//    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email = "email"
        case photoUrl = "photo_url"
        case date_created = "date_created"
        case isPremium = "is_premium"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        self.date_created = try container.decodeIfPresent(Date.self, forKey: .date_created)
        self.isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.photoUrl, forKey: .photoUrl)
        try container.encodeIfPresent(self.date_created, forKey: .date_created)
        try container.encodeIfPresent(self.isPremium, forKey: .isPremium)
    }
    
    
    
}

final class UserManager {
    
    static let shared = UserManager()
    private init() {}
    
    private let userCollection = Firestore.firestore().collection("users")
    private func userDocument(userId : String) -> DocumentReference{
        userCollection.document(userId)
    }
    
    
    func createNewUser(user: DbUser) async throws {
        // Prevent overwriting if the user already exists
        let userExists = try await checkUserExists(userId: user.userId)
        guard !userExists else { return }
        
        try userDocument(userId: user.userId).setData(from: user, merge: false)
    }
    
    func getUser(userId: String) async throws -> DbUser {
        try await userDocument(userId: userId).getDocument(as: DbUser.self)
    }
    
    func checkUserExists(userId: String) async throws -> Bool {
        let snapshot = try await Firestore.firestore().collection("users").document(userId).getDocument()
        return snapshot.exists
    }
    
    
    func updateUserPremiumStatus(userId: String, isPremium: Bool) async throws {
        let data: [String:Any] = [
            DbUser.CodingKeys.isPremium.rawValue : isPremium
        ]
        
        try await userDocument(userId: userId).updateData(data)
    }
    
}
