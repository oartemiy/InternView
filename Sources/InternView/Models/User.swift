//
//  User.swift
//  InternView
//
//  Created by Артемий Образцов on 02.02.2026.
//

import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id) var id: UUID?

    @Field(key: "name") var name: String
    @Field(key: "login") var login: String
    @Field(key: "password") var password: String
    @Field(key: "role") var role: String
    @Field(key: "profile_pic") var profilePic: String?
    @Field(key: "description") var description: String?
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, name: String, login: String, password: String, role: String, profilePic: String? = nil, description: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.name = name
        self.login = login
        self.password = password
        self.role = role
        self.profilePic = profilePic
        self.description = description
        self.createdAt = createdAt
    }
}

extension User: ModelAuthenticatable {
    static var usernameKey: KeyPath<User, FluentKit.FieldProperty<User, String>> {
        \User.$login
    }
    
    static var passwordHashKey: KeyPath<User, FluentKit.FieldProperty<User, String>> {
        \User.$password
    }
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

enum UserRole: String {
    case intern = "intern"
    case recruiter = "recruiter"
}
