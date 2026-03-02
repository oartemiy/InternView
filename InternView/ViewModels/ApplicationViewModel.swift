//
//  ApplicationViewModel.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class ApplicationViewModel: ObservableObject {
    @Published var applications: [Application] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = APIService.shared
    private let auth = AuthService.shared
    
    // MARK: - Для интерна: мои отклики
    func loadMyApplications() async {
        isLoading = true
        errorMessage = nil
        do {
            let apps: [Application] = try await api.request(endpoint: "/applications/my")
            self.applications = apps
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Для рекрутера: отклики на конкретную вакансию
    func loadApplications(for vacancyId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let apps: [Application] = try await api.request(endpoint: "/applications/vacancy/\(vacancyId)")
            self.applications = apps
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Создать отклик (интерн)
    func createApplication(vacancyId: UUID, cvId: UUID, coverLetter: String?, resumeUrl: String?) async throws {
        struct CreateBody: Encodable {
            let vacancyId: UUID
            let cvId: UUID
            let coverLetter: String?
            let resumeUrl: String?
        }
        let body = CreateBody(vacancyId: vacancyId, cvId: cvId, coverLetter: coverLetter, resumeUrl: resumeUrl)
        let newApp: Application = try await api.request(endpoint: "/applications", method: "POST", body: body)
        // Добавляем в начало списка, если это экран интерна
        applications.insert(newApp, at: 0)
    }
    
    // MARK: - Обновить статус (рекрутер)
    func updateStatus(applicationId: UUID, status: String) async throws {
        struct UpdateBody: Encodable {
            let status: String
        }
        let body = UpdateBody(status: status)
        let updated: Application = try await api.request(endpoint: "/applications/\(applicationId)", method: "PUT", body: body)
        if let index = applications.firstIndex(where: { $0.id == applicationId }) {
            applications[index] = updated
        }
    }
    
    // MARK: - Отменить отклик (интерн) – только статус cancelled
    func cancelApplication(applicationId: UUID) async throws {
        struct CancelBody: Encodable {
            let status: String = "cancelled"
        }
        let body = CancelBody()
        let updated: Application = try await api.request(endpoint: "/applications/\(applicationId)", method: "PUT", body: body)
        if let index = applications.firstIndex(where: { $0.id == applicationId }) {
            applications[index] = updated
        }
    }
    
    // MARK: - Удалить отклик (интерн или рекрутер)
    func deleteApplication(applicationId: UUID) async throws {
        _ = try await api.request(endpoint: "/applications/\(applicationId)", method: "DELETE") as EmptyResponse?
        applications.removeAll { $0.id == applicationId }
    }
}
