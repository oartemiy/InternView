//
//  VacancyViewModel.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class VacancyViewModel: ObservableObject {
    @Published var myVacancies: [Vacancy.Simple] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = APIService.shared
    private let auth = AuthService.shared
    
    // MARK: - Загрузить мои вакансии (для рекрутера)
    func loadMyVacancies() async {
        isLoading = true
        errorMessage = nil
        do {
            let vacancies: [Vacancy.Simple] = try await api.request(endpoint: "/vacancies/my")
            self.myVacancies = vacancies
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Создать вакансию
    func createVacancy(_ data: Vacancy.CreateUpdate) async throws -> Vacancy.Simple {
        let vacancy: Vacancy.Simple = try await api.request(
            endpoint: "/vacancies",
            method: "POST",
            body: data
        )
        // Обновляем список, если нужно
        await loadMyVacancies()
        return vacancy
    }
    
    // MARK: - Обновить вакансию
    func updateVacancy(id: UUID, data: Vacancy.CreateUpdate) async throws -> Vacancy.Simple {
        let updated: Vacancy.Simple = try await api.request(
            endpoint: "/vacancies/\(id)",
            method: "PUT",
            body: data
        )
        if let index = myVacancies.firstIndex(where: { $0.id == id }) {
            myVacancies[index] = updated
        }
        return updated
    }
    
    // MARK: - Удалить вакансию
    func deleteVacancy(id: UUID) async throws {
        _ = try await api.request(endpoint: "/vacancies/\(id)", method: "DELETE") as EmptyResponse?
        myVacancies.removeAll { $0.id == id }
    }
    
    // MARK: - Переключить активность
    func toggleActive(id: UUID) async throws -> Vacancy.Simple {
        let updated: Vacancy.Simple = try await api.request(
            endpoint: "/vacancies/\(id)/toggle",
            method: "PATCH",
            body: nil
        )
        if let index = myVacancies.firstIndex(where: { $0.id == id }) {
            myVacancies[index] = updated
        }
        return updated
    }
}
