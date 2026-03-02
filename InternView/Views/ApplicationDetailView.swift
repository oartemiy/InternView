//
//  ApplicationDetailView.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI

struct ApplicationDetailView: View {
    let application: Application
    @ObservedObject var viewModel: ApplicationViewModel
    @State private var showCancelAlert = false
    
    var body: some View {
        Form {
            Section("Вакансия") {
                LabeledContent("Название", value: application.vacancy?.title ?? "—")
                LabeledContent("Компания", value: application.vacancy?.recruiter?.name ?? "—")
            }
            
            Section("Статус") {
                HStack {
                    StatusBadge(status: application.status)
                    Spacer()
                    if application.status == "pending" && AuthService.shared.currentUser?.role == "intern" {
                        Button("Отменить") {
                            showCancelAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            
            if let coverLetter = application.coverLetter, !coverLetter.isEmpty {
                Section("Сопроводительное письмо") {
                    Text(coverLetter)
                }
            }
            
            if let resumeUrl = application.resumeUrl, !resumeUrl.isEmpty {
                Section("Резюме") {
                    Link(destination: URL(string: resumeUrl)!) {
                        Label("Открыть резюме", systemImage: "link")
                    }
                }
            }
            
            if let cv = application.cv {
                Section("CV") {
                    VStack(alignment: .leading) {
                        Text(cv.title).font(.headline)
                        Text(cv.description).font(.caption)
                        if !cv.pdf.isEmpty {
                            Link("PDF", destination: URL(string: Constants.baseURL + cv.pdf)!)
                                .font(.caption)
                        }
                    }
                }
            }
            
            if let appliedAt = application.appliedAt {
                Section("Дата отклика") {
                    Text(appliedAt, style: .date)
                }
            }
        }
        .navigationTitle("Детали отклика")
        .alert("Отменить отклик?", isPresented: $showCancelAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Отменить", role: .destructive) {
                Task {
                    try? await viewModel.cancelApplication(applicationId: application.id)
                }
            }
        }
    }
}
