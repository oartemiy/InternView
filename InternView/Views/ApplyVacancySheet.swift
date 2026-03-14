//
//  ApplyVacancySheet.swift
//  InternView
//
//  Created by Артемий Образцов on 02.03.2026.
//

import Foundation
import SwiftUI

struct ApplyVacancySheet: View {
    let vacancyId: UUID
    var onApplied: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var cvVM = CVViewModel()
    @StateObject private var applicationVM = ApplicationViewModel()
    @State private var selectedCVId: UUID?
    @State private var coverLetter = ""
    @State private var resumeUrl = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                if cvVM.isLoading {
                    ProgressView()
                } else if cvVM.cvs.isEmpty {
                    Section {
                        Text("У вас нет резюме. Сначала создайте резюме.")
                            .foregroundColor(.secondary)
                        NavigationLink("Создать резюме") {
                            // Переход к созданию резюме
                            CreateCVSheet(viewModel: cvVM)
                        }
                    }
                } else {
                    Section("Выберите резюме") {
                        Picker("Резюме", selection: $selectedCVId) {
                            ForEach(cvVM.cvs) { cv in
                                Text(cv.title).tag(cv.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section("Сопроводительное письмо (необязательно)") {
                        TextEditor(text: $coverLetter)
                            .frame(minHeight: 100)
                    }
                    
                    Section("Ссылка на резюме (необязательно)") {
                        TextField("https://...", text: $resumeUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                    
                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Section {
                        Button("Отправить отклик") {
                            Task { await apply() }
                        }
                        .disabled(selectedCVId == nil || isLoading)
                        
                        if isLoading {
                            ProgressView()
                        }
                    }
                }
            }
            .navigationTitle("Отклик на вакансию")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .task {
                await cvVM.loadMyCVs()
            }
        }
    }
    
    private func apply() async {
        guard let cvId = selectedCVId else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            try await applicationVM.createApplication(
                vacancyId: vacancyId,
                cvId: cvId,
                coverLetter: coverLetter.isEmpty ? nil : coverLetter,
                resumeUrl: resumeUrl.isEmpty ? nil : resumeUrl
            )
            onApplied()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
