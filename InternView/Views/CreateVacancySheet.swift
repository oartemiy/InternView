//
//  CreateVacancySheet.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI

struct CreateVacancySheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: VacancyViewModel
    var editingVacancy: Vacancy.Simple? // если nil – создание, иначе редактирование
    
    @State private var title = ""
    @State private var description = ""
    @State private var requirementsText = ""
    @State private var salaryRange = ""
    @State private var location = ""
    @State private var workMode = "remote"
    @State private var experienceLevel = "junior"
    @State private var expiresAt = Date().addingTimeInterval(30*24*3600)
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(viewModel: VacancyViewModel, vacancy: Vacancy.Simple? = nil) {
        self.viewModel = viewModel
        self.editingVacancy = vacancy
        _title = State(initialValue: vacancy?.title ?? "")
        _description = State(initialValue: vacancy?.description ?? "")
        _requirementsText = State(initialValue: vacancy?.requirements.joined(separator: "\n") ?? "")
        _salaryRange = State(initialValue: vacancy?.salaryRange ?? "")
        _location = State(initialValue: vacancy?.location ?? "")
        _workMode = State(initialValue: vacancy?.workMode ?? "remote")
        _experienceLevel = State(initialValue: vacancy?.experienceLevel ?? "junior")
        if let expires = vacancy?.expiresAt {
            _expiresAt = State(initialValue: expires)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Основное") {
                    TextField("Название вакансии", text: $title)
                    TextField("Описание", text: $description, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                Section("Требования (каждое с новой строки)") {
                    TextEditor(text: $requirementsText)
                        .frame(minHeight: 100)
                }
                
                Section("Детали") {
                    TextField("Зарплата (например, 1000-2000$)", text: $salaryRange)
                    TextField("Локация", text: $location)
                    
                    Picker("Формат работы", selection: $workMode) {
                        Text("Удалённо").tag("remote")
                        Text("Офис").tag("office")
                        Text("Гибрид").tag("hybrid")
                    }
                    
                    Picker("Уровень", selection: $experienceLevel) {
                        Text("Junior").tag("junior")
                        Text("Middle").tag("middle")
                        Text("Senior").tag("senior")
                    }
                }
                
                Section("Срок действия") {
                    DatePicker("Действует до", selection: $expiresAt, displayedComponents: .date)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(editingVacancy == nil ? "Создать" : "Сохранить") {
                        Task { await save() }
                    }
                    .disabled(title.isEmpty || description.isEmpty || requirementsText.isEmpty || location.isEmpty || isLoading)
                    
                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle(editingVacancy == nil ? "Новая вакансия" : "Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
    
    private func save() async {
        isLoading = true
        errorMessage = nil
        
        let requirements = requirementsText
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
        
        let data = Vacancy.CreateUpdate(
            title: title,
            description: description,
            requirements: requirements,
            salaryRange: salaryRange.isEmpty ? nil : salaryRange,
            location: location,
            workMode: workMode,
            experienceLevel: experienceLevel,
            expiresAt: expiresAt
        )
        
        do {
            if let vacancy = editingVacancy {
                _ = try await viewModel.updateVacancy(id: vacancy.id, data: data)
            } else {
                _ = try await viewModel.createVacancy(data)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
