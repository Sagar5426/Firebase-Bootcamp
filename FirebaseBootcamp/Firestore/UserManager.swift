//
//  UserManager.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 06/07/2026.
//
import Foundation
import FirebaseFirestore
import FirebaseSharedSwift


struct Movie: Codable {
    let id: String
    let name: String
    let isPopular: Bool
}

struct DbUser: Codable {
    let userId: String
    let email : String?
    let photoUrl : String?
    let date_created : Date?
    let isPremium: Bool?
    let preferences: [String]?
    let favouriteMovie: Movie?
    
    init(auth: AuthDataResultModel) {
        self.userId = auth.uid
        self.email = auth.email
        self.photoUrl = auth.photoUrl
        self.date_created = Date()
        self.isPremium = false
        self.preferences = nil
        self.favouriteMovie = nil
    }
    
    init(userId: String, email : String? = nil, photoUrl : String? = nil, date_created : Date? = nil , isPremium: Bool? = nil, preferences: [String]? = nil, favouriteMovie: Movie? = nil) {
        self.userId = userId
        self.email = email
        self.photoUrl = photoUrl
        self.date_created = date_created
        self.isPremium = isPremium
        self.preferences = preferences
        self.favouriteMovie = favouriteMovie
    }
    
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email = "email"
        case photoUrl = "photo_url"
        case date_created = "date_created"
        case isPremium = "is_premium"
        case preferences = "preferences"
        case favouriteMovie = "favourite_movie"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        self.date_created = try container.decodeIfPresent(Date.self, forKey: .date_created)
        self.isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium)
        self.preferences = try container.decodeIfPresent([String].self, forKey: .preferences)
        self.favouriteMovie = try container.decodeIfPresent(Movie.self, forKey: .favouriteMovie)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.photoUrl, forKey: .photoUrl)
        try container.encodeIfPresent(self.date_created, forKey: .date_created)
        try container.encodeIfPresent(self.isPremium, forKey: .isPremium)
        try container.encodeIfPresent(self.preferences, forKey: .preferences)
        try container.encodeIfPresent(self.favouriteMovie, forKey: .favouriteMovie)
    }
    
    
    
}

final class UserManager {
    
    static let shared = UserManager()
    private init() {}
    
    private let userCollection = Firestore.firestore().collection("users")
    private func userDocument(userId : String) -> DocumentReference{
        userCollection.document(userId)
    }
    
    private func userFavouriteProductCollection(userId: String) -> CollectionReference {
        userDocument(userId: userId).collection("favourite_products")
    }
    private func userFavouriteProductDocument(userId: String, favouriteProductId: String) -> DocumentReference {
        userFavouriteProductCollection(userId: userId).document(favouriteProductId)
    }
    
    
    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        return encoder
    }()
    private let decoder: Firestore.Decoder = {
       let decoder = Firestore.Decoder()
        return decoder
    }()
    
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
    
    func addUserPreference(userId: String, preferences: String) async throws {
        let data: [String:Any] = [
            DbUser.CodingKeys.preferences.rawValue : FieldValue.arrayUnion([preferences])
        ]
        
        try await userDocument(userId: userId).updateData(data)
    }
    
    func removeUserPreference(userId: String, preferences: String) async throws {
        let data: [String:Any] = [
            DbUser.CodingKeys.preferences.rawValue : FieldValue.arrayRemove([preferences])
        ]
        
        try await userDocument(userId: userId).updateData(data)
    }
    
    func addFavMovie(userId: String, movie: Movie) async throws {
        guard let data = try? encoder.encode(movie) else {
            throw URLError(.badURL)
        }
        let dict: [String:Any] = [
            DbUser.CodingKeys.favouriteMovie.rawValue : data
        ]
        
        try await userDocument(userId: userId).updateData(dict)
    }
    
        func removeFavMovie(userId: String) async throws {
            let data: [String:Any] = [
                DbUser.CodingKeys.favouriteMovie.rawValue : FieldValue.delete()
            ]
            
            try await userDocument(userId: userId).updateData(data)
        }
    
    func addUserFavouriteProduct(userId: String, productId: Int) async throws {
        let document = userFavouriteProductCollection(userId: userId).document()
        let documentId = document.documentID
        
        let data: [String:Any] = [
            UserFavouriteProduct.CodingKeys.id.rawValue : documentId,
            UserFavouriteProduct.CodingKeys.productId.rawValue : productId,
            UserFavouriteProduct.CodingKeys.dateCreated.rawValue : Timestamp()
        ]
        
        try await document.setData(data, merge: false)
    }
    
    func removeUserFavouriteProduct(userId: String, favouriteProductId: String) async throws {
        try await userFavouriteProductDocument(userId: userId, favouriteProductId: favouriteProductId).delete()
    }
    
    func getAllUserFavouriteProducts(userId: String) async throws -> [UserFavouriteProduct] {
        try await userFavouriteProductCollection(userId: userId).getDocuments(as: UserFavouriteProduct.self)
    }
    
}

struct UserFavouriteProduct: Codable {
    let id: String
    let productId: Int
    let dateCreated : Date
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case productId = "product_id"
        case dateCreated = "date_created"
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.productId, forKey: .productId)
        try container.encode(self.dateCreated, forKey: .dateCreated)
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.productId = try container.decode(Int.self, forKey: .productId)
        self.dateCreated = try container.decode(Date.self, forKey: .dateCreated)
    }
}
