//
//  AuthService.swift
//  InternView
//
//  Created by Артемий Образцов on 21.02.2026.
//

import Combine
import Combine
import Foundation
import SwiftUI
import SwiftData

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private let api = APIService.shared
    private let keychain = KeychainManager.shared
    private var modelContext: ModelContext?

    private init() {}

    func setupModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            await restoreSession()
        }
    }

    // Восстановление сессии при запуске
    private func restoreSession() async {
        // Проверяем, есть ли сохранённый пользователь в SwiftData
        guard (try? modelContext?.fetch(FetchDescriptor<PersistentUser>()).first) != nil else {
            return
        }

        // Если есть логин/пароль в Keychain, пробуем залогиниться
        if let login = keychain.get(Constants.KeychainKeys.login),
           let password = keychain.get(Constants.KeychainKeys.password) {
            do {
                // Исправлено: явно указываем тип для статического свойства
                try await AuthService.shared.login(username: login, password: password)
            } catch {
                // Если логин не удался, очищаем всё
                clearLocalData()
            }
        } else {
            // Если нет логина в Keychain, но есть сохранённый пользователь – чистим
            clearLocalData()
        }
    }

    private func saveUserToSwiftData(_ user: User) {
        guard let modelContext = modelContext else { return }
        // Удаляем старого пользователя
        try? modelContext.delete(model: PersistentUser.self)
        let persistent = PersistentUser(
            id: user.id,
            name: user.name,
            login: user.login,
            role: user.role,
            profilePic: user.profilePic,
            description: user.description
        )
        modelContext.insert(persistent)
        try? modelContext.save()
    }

    private func clearLocalData() {
        try? modelContext?.delete(model: PersistentUser.self)
        keychain.clear()
        currentUser = nil
        isAuthenticated = false
    }

    // Исправленный метод login: параметр username используется внутри
    func login(username: String, password: String) async throws {
        let body: [String: String] = ["login": username, "password": password]
        let user: User = try await api.request(endpoint: "/users/login", method: "POST", body: body)

        api.setAuth(login: username, password: password)
        keychain.save(username, for: Constants.KeychainKeys.login)
        keychain.save(password, for: Constants.KeychainKeys.password)

        saveUserToSwiftData(user)

        self.currentUser = user
        self.isAuthenticated = true
    }

    func register(name: String, login: String, password: String, role: String, description: String?, imageData: Data?) async throws {
        var parameters: [String: String] = [
            "name": name,
            "login": login,
            "password": password,
            "role": role
        ]
        if let description = description {
            parameters["description"] = description
        }

        let user: User = try await api.uploadMultipart(
            endpoint: "/users",
            method: "POST",
            parameters: parameters,
            fileData: imageData,
            fileKey: "profilePicFile",
            fileName: "avatar.jpg",
            mimeType: "image/jpeg"
        )

        api.setAuth(login: login, password: password)
        keychain.save(login, for: Constants.KeychainKeys.login)
        keychain.save(password, for: Constants.KeychainKeys.password)

        saveUserToSwiftData(user)

        self.currentUser = user
        self.isAuthenticated = true
    }

    func updateProfile(name: String, description: String?, imageData: Data?) async throws {
        guard let userId = currentUser?.id else { throw APIError.unauthorized }

        var parameters: [String: String] = ["name": name]
        if let description = description {
            parameters["description"] = description
        }

        let updatedUser: User
        if let imageData = imageData {
            updatedUser = try await api.uploadMultipart(
                endpoint: "/users/\(userId)",
                method: "PUT",
                parameters: parameters,
                fileData: imageData,
                fileKey: "profilePicFile",
                fileName: "avatar.jpg",
                mimeType: "image/jpeg"
            )
        } else {
            struct UpdateBody: Encodable {
                let name: String
                let description: String?
            }
            let body = UpdateBody(name: name, description: description)
            updatedUser = try await api.request(
                endpoint: "/users/\(userId)",
                method: "PUT",
                body: body
            )
        }

        saveUserToSwiftData(updatedUser)
        self.currentUser = updatedUser
    }

    func deleteAccount() async throws {
        guard let userId = currentUser?.id else { throw APIError.unauthorized }

        let _: EmptyResponse = try await api.request(
            endpoint: "/users/\(userId)",
            method: "DELETE"
        )

        clearLocalData()
    }

    func logout() {
        clearLocalData()
    }
}
