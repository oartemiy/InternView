//
//  RecruiterVacancyDetailView.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI

struct RecruiterVacancyDetailView: View {
    let vacancy: Vacancy.Simple
    @StateObject private var applicationVM = ApplicationViewModel()
    @StateObject private var vacancyVM = VacancyViewModel()
    @State private var showingEditSheet = false
    @State private var isProcessing = false
    
    var body: some View {
        List {
            Section("Информация о вакансии") {
                LabeledContent("Название", value: vacancy.title)
                LabeledContent("Локация", value: vacancy.location)
                LabeledContent("Формат", value: vacancy.workMode)
                LabeledContent("Уровень", value: vacancy.experienceLevel)
                if let salary = vacancy.salaryRange {
                    LabeledContent("Зарплата", value: salary)
                }
                LabeledContent("Статус", value: vacancy.isActive ? "Активна" : "Неактивна")
                if let expires = vacancy.expiresAt {
                    LabeledContent("Действует до", value: expires.formatted(date: .abbreviated, time: .omitted))
                }
            }
            
            Section("Описание") {
                Text(vacancy.description)
            }
            
            Section("Требования") {
                ForEach(vacancy.requirements, id: \.self) { req in
                    Text("• \(req)")
                }
            }
            
            Section("Отклики (\(applicationVM.applications.count))") {
                if applicationVM.isLoading {
                    ProgressView()
                } else if applicationVM.applications.isEmpty {
                    Text("Пока нет откликов")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(applicationVM.applications) { application in
                        NavigationLink(destination: RecruiterApplicationDetailView(application: application)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(application.intern?.name ?? "Неизвестно")
                                        .font(.headline)
                                    Text(application.cv?.title ?? "Без CV")
                                        .font(.caption)
                                }
                                Spacer()
                                StatusBadge(status: application.status)
                            }
                        }
                    }
                }
            }
            
            Section("Управление") {
                Button(vacancy.isActive ? "Деактивировать" : "Активировать") {
                    Task {
                        isProcessing = true
                        try? await vacancyVM.toggleActive(id: vacancy.id)
                        isProcessing = false
                    }
                }
                .disabled(isProcessing)
                
                Button("Редактировать") {
                    showingEditSheet = true
                }
                
                Button("Удалить", role: .destructive) {
                    Task {
                        isProcessing = true
                        try? await vacancyVM.deleteVacancy(id: vacancy.id)
                        isProcessing = false
                    }
                }
                .disabled(isProcessing)
            }
        }
        .navigationTitle(vacancy.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            CreateVacancySheet(viewModel: vacancyVM, vacancy: vacancy)
        }
        .task {
            await applicationVM.loadApplications(for: vacancy.id)
        }
        .refreshable {
            await applicationVM.loadApplications(for: vacancy.id)
        }
    }
}
