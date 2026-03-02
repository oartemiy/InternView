//
//  RecruiterApplicationDetailView.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI

struct RecruiterApplicationDetailView: View {
    let application: Application
    @StateObject private var viewModel = ApplicationViewModel()
    @State private var selectedStatus = ""
    @State private var isUpdating = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section("Кандидат") {
                LabeledContent("Имя", value: application.intern?.name ?? "—")
                LabeledContent("Email", value: application.intern?.login ?? "—")
                if let cv = application.cv {
                    NavigationLink("Резюме: \(cv.title)") {
                        CVDetailView(cv: cv, viewModel: CVViewModel())
                    }
                }
            }
            
            Section("Детали отклика") {
                LabeledContent("Статус", value: application.status)
                if let coverLetter = application.coverLetter, !coverLetter.isEmpty {
                    Text(coverLetter)
                }
                if let resumeUrl = application.resumeUrl, let url = URL(string: resumeUrl) {
                    Link("Ссылка на резюме", destination: url)
                }
                if let appliedAt = application.appliedAt {
                    LabeledContent("Откликнулся", value: appliedAt.formatted())
                }
            }
            
            Section("Изменить статус") {
                Picker("Статус", selection: $selectedStatus) {
                    Text("Новый").tag("pending")
                    Text("Рассмотрено").tag("reviewed")
                    Text("Одобрено").tag("approved")
                    Text("Отклонено").tag("rejected")
                }
                .pickerStyle(.segmented)
                
                Button("Обновить статус") {
                    Task { await updateStatus() }
                }
                .disabled(selectedStatus.isEmpty || selectedStatus == application.status || isUpdating)
            }
        }
        .navigationTitle("Отклик")
        .onAppear {
            selectedStatus = application.status
        }
    }
    
    private func updateStatus() async {
        isUpdating = true
        do {
            try await viewModel.updateStatus(applicationId: application.id, status: selectedStatus)
            dismiss()
        } catch {
            // показать ошибку
        }
        isUpdating = false
    }
}
