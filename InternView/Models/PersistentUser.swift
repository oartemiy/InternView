//
//  PersistentUser.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftData

@Model
final class PersistentUser {
    var id: UUID
    var name: String
    var login: String
    var role: String
    var profilePic: String?
    var userDescription: String?
    var lastUpdated: Date

    init(id: UUID, name: String, login: String, role: String, profilePic: String? = nil, description: String? = nil) {
        self.id = id
        self.name = name
        self.login = login
        self.role = role
        self.profilePic = profilePic
        self.userDescription = description
        self.lastUpdated = Date()
    }
}
