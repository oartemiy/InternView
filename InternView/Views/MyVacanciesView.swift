//
//  MyVacanciesView.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI

struct MyVacanciesView: View {
    @StateObject private var viewModel = VacancyViewModel()
    @State private var showingCreateSheet = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Загрузка...")
                } else if viewModel.myVacancies.isEmpty {
                    ContentUnavailableView(
                        "У вас ещё нет вакансий",
                        systemImage: "briefcase",
                        description: Text("Создайте первую вакансию")
                    )
                } else {
                    List(viewModel.myVacancies) { vacancy in
                        NavigationLink(destination: RecruiterVacancyDetailView(vacancy: vacancy)) {
                            VStack(alignment: .leading) {
                                Text(vacancy.title)
                                    .font(.headline)
                                HStack {
                                    Text(vacancy.location)
                                        .font(.caption)
                                    Spacer()
                                    StatusBadge(status: vacancy.isActive ? "active" : "inactive")
                                }
                                Text("Откликов: \(vacancy.applicationCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { try? await viewModel.deleteVacancy(id: vacancy.id) }
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Мои вакансии")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateVacancySheet(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.loadMyVacancies()
            }
            .task {
                await viewModel.loadMyVacancies()
            }
            .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
