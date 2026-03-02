//
//  CVListView.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI

struct CVListView: View {
    @StateObject private var viewModel = CVViewModel()
    @State private var showingCreateSheet = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Загрузка...")
                } else if viewModel.cvs.isEmpty {
                    ContentUnavailableView(
                        "У вас ещё нет резюме",
                        systemImage: "doc.text",
                        description: Text("Создайте первое резюме")
                    )
                } else {
                    List(viewModel.cvs) { cv in
                        NavigationLink(destination: CVDetailView(cv: cv, viewModel: viewModel)) {
                            VStack(alignment: .leading) {
                                Text(cv.title)
                                    .font(.headline)
                                Text(cv.description)
                                    .font(.subheadline)
                                    .lineLimit(2)
                                if let createdAt = cv.createdAt {
                                    Text("Создано: \(createdAt, formatter: dateFormatter)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { try? await viewModel.deleteCV(cv) }
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Мои резюме")
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
                CreateCVSheet(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.loadMyCVs()
            }
            .task {
                await viewModel.loadMyCVs()
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

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()
