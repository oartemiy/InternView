//
//  VacancyListView.swift
//  InternView
//
//  Created by Артемий Образцов on 02.03.2026.
//

import Foundation
import SwiftUI

struct VacancyListView: View {
    @StateObject private var viewModel = VacancyListViewModel()
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Загрузка вакансий...")
                } else if viewModel.vacancies.isEmpty {
                    ContentUnavailableView(
                        "Нет вакансий",
                        systemImage: "briefcase.slash",
                        description: Text("Попробуйте позже или измените фильтры")
                    )
                } else {
                    List(viewModel.vacancies) { vacancy in
                        NavigationLink(destination: VacancyDetailView(vacancy: vacancy)) {
                            VacancyRowView(vacancy: vacancy, viewModel: viewModel)
                        }
                    }
                    .refreshable {
                        await viewModel.loadVacancies()
                    }
                }
            }
            .navigationTitle("Вакансии")
            .searchable(text: $viewModel.searchText, prompt: "Поиск")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Формат работы", selection: $viewModel.workModeFilter) {
                            Text("Все").tag("")
                            Text("Удалённо").tag("remote")
                            Text("Офис").tag("office")
                            Text("Гибрид").tag("hybrid")
                        }
                        
                        Picker("Уровень", selection: $viewModel.levelFilter) {
                            Text("Все").tag("")
                            Text("Junior").tag("junior")
                            Text("Middle").tag("middle")
                            Text("Senior").tag("senior")
                        }
                        
                        Toggle("Только активные", isOn: $viewModel.showActiveOnly)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .task {
                await viewModel.loadVacancies()
            }
            .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }.onChange(of: viewModel.searchText) { _ in
                viewModel.applyFilters()
            }
            .onChange(of: viewModel.workModeFilter) { _ in
                viewModel.applyFilters()
            }
            .onChange(of: viewModel.levelFilter) { _ in
                viewModel.applyFilters()
            }
            .onChange(of: viewModel.showActiveOnly) { _ in
                Task { await viewModel.loadVacancies() }
            }
        }
    }
}

struct VacancyRowView: View {
    let vacancy: Vacancy.Simple
    @ObservedObject var viewModel: VacancyListViewModel  // добавлено
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vacancy.title)
                .font(.headline)
            
            HStack {
                Label(vacancy.location, systemImage: "location")
                    .font(.caption)
                Spacer()
                if let salary = vacancy.salaryRange {
                    Label(salary, systemImage: "rublesign.circle")
                        .font(.caption)
                }
            }
            
            HStack {
                Text(vacancy.workMode)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Text(vacancy.experienceLevel)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                // Отображаем имя рекрутера из кэша
                if let recruiterName = viewModel.recruiterNames[vacancy.recruiterId] {
                    Text("от \(recruiterName)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Загрузка...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .onAppear {
                            // Если имени ещё нет, запускаем загрузку (на случай, если она не была вызвана)
                            Task {
                                await viewModel.loadRecruiterName(for: vacancy.recruiterId)
                            }
                        }
                }
            }
            
            if vacancy.applicationCount > 0 {
                Text("\(vacancy.applicationCount) откликов")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
