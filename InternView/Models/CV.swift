//
//  CV.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation

struct CV: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let userId: UUID
    let pdf: String
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case userId = "user_id"
        case pdf
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
