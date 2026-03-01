//
//  User.swift
//  InternView
//
//  Created by Артемий Образцов on 21.02.2026.
//

import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let login: String
    let role: String
    let profilePic: String?
    let description: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, login, role
        case profilePic = "profile_pic"
        case description
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        login = try container.decode(String.self, forKey: .login)
        role = try container.decode(String.self, forKey: .role)
        profilePic = try container.decodeIfPresent(String.self, forKey: .profilePic)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)

        print("🔍 Decoded: profilePic=\(profilePic ?? "nil"), createdAt=\(createdAt?.description ?? "nil")")
    }
}
