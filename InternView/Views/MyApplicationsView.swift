//
//  MyApplicationsView.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI

struct MyApplicationsView: View {
    @StateObject private var viewModel = ApplicationViewModel()
    @State private var selectedApplication: Application?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Загрузка...")
                } else if viewModel.applications.isEmpty {
                    ContentUnavailableView(
                        "У вас ещё нет откликов",
                        systemImage: "envelope",
                        description: Text("Откликнитесь на вакансию")
                    )
                } else {
                    List(viewModel.applications) { application in
                        NavigationLink(destination: ApplicationDetailView(application: application, viewModel: viewModel)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(application.vacancy?.title ?? "Вакансия")
                                    .font(.headline)
                                HStack {
                                    StatusBadge(status: application.status)
                                    if let appliedAt = application.appliedAt {
                                        Text(appliedAt, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            if application.status != "cancelled" {
                                Button("Отменить", role: .destructive) {
                                    Task { try? await viewModel.cancelApplication(applicationId: application.id) }
                                }
                            }
                            Button("Удалить", role: .destructive) {
                                Task { try? await viewModel.deleteApplication(applicationId: application.id) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Мои отклики")
            .refreshable {
                await viewModel.loadMyApplications()
            }
            .task {
                await viewModel.loadMyApplications()
            }
            .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
