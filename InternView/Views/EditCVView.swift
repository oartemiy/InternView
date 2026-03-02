//
//  EditCVView.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine

struct EditCVView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: CVViewModel
    let cv: CV
    
    @State private var title: String
    @State private var description: String
    @State private var selectedPDFData: Data?
    @State private var selectedPDFName: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingDocumentPicker = false
    
    init(viewModel: CVViewModel, cv: CV) {
        self.viewModel = viewModel
        self.cv = cv
        _title = State(initialValue: cv.title)
        _description = State(initialValue: cv.description)
        if !cv.pdf.isEmpty {
            _selectedPDFName = State(initialValue: "Текущий PDF")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Основная информация") {
                    TextField("Название резюме", text: $title)
                    TextField("Описание", text: $description, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                Section("PDF-файл") {
                    Button("Выбрать новый PDF") {
                        showingDocumentPicker = true
                    }
                    
                    if let pdfName = selectedPDFName {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            Text(pdfName)
                                .font(.caption)
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Сохранить") {
                        Task { await save() }
                    }
                    .disabled(title.isEmpty || description.isEmpty || isLoading)
                    
                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Редактировать резюме")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        do {
                            let data = try Data(contentsOf: url)
                            selectedPDFData = data
                            selectedPDFName = url.lastPathComponent
                        } catch {
                            errorMessage = "Не удалось прочитать файл"
                        }
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func save() async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await viewModel.updateCV(
                cv,
                title: title,
                description: description,
                pdfData: selectedPDFData
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
