//
//  CVDetailView.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct CVDetailView: View {
    let cv: CV
    @StateObject var viewModel: CVViewModel
    @State private var showingEditSheet = false
    
    init(cv: CV, viewModel: CVViewModel) {
        self.cv = cv
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(cv.title)
                    .font(.largeTitle)
                    .bold()
                
                Divider()
                
                Text("Описание")
                    .font(.headline)
                Text(cv.description)
                    .font(.body)
                
                if let createdAt = cv.createdAt {
                    Text("Создано: \(createdAt, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let updatedAt = cv.updatedAt {
                    Text("Обновлено: \(updatedAt, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !cv.pdf.isEmpty {
                    Link(destination: URL(string: Constants.baseURL + cv.pdf)!) {
                        Label("Открыть PDF", systemImage: "doc.richtext")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Резюме")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Редактировать") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditCVView(viewModel: viewModel, cv: cv)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
