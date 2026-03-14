//
//  VacancyListViewModel.swift
//  InternView
//
//  Created by Артемий Образцов on 02.03.2026.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class VacancyListViewModel: ObservableObject {
    @Published var vacancies: [Vacancy.Simple] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var searchText = ""
    @Published var workModeFilter = ""
    @Published var levelFilter = ""
    @Published var showActiveOnly = true
    
    // Кэш имён рекрутеров (id -> имя)
    @Published var recruiterNames: [UUID: String] = [:]
    
    private let api = APIService.shared
    private var allVacancies: [Vacancy.Simple] = []
    
    func loadVacancies() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let endpoint = "/vacancies" + (showActiveOnly ? "" : "?active=false")
            let fetched: [Vacancy.Simple] = try await api.request(endpoint: endpoint)
            self.allVacancies = fetched
            applyFilters()
            
            // Загружаем имена рекрутеров для всех вакансий
            await loadRecruiterNames(for: fetched)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func applyFilters() {
        var filtered = allVacancies
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        if !workModeFilter.isEmpty {
            filtered = filtered.filter { $0.workMode == workModeFilter }
        }
        if !levelFilter.isEmpty {
            filtered = filtered.filter { $0.experienceLevel == levelFilter }
        }
        vacancies = filtered
    }
    
    // Загрузка имени рекрутера по ID
    func loadRecruiterName(for userId: UUID) async {
        // Если уже есть в кэше – пропускаем
        guard recruiterNames[userId] == nil else { return }
        
        do {
            let user: User = try await api.request(endpoint: "/users/\(userId)")
            recruiterNames[userId] = user.name
        } catch {
            print("Ошибка загрузки рекрутера \(userId): \(error)")
            recruiterNames[userId] = "Неизвестно"
        }
    }
    
    // Загрузка всех имён рекрутеров для списка вакансий
    func loadRecruiterNames(for vacancies: [Vacancy.Simple]) async {
        await withTaskGroup(of: Void.self) { group in
            for vacancy in vacancies {
                group.addTask {
                    await self.loadRecruiterName(for: vacancy.recruiterId)
                }
            }
        }
    }
}
