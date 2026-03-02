//
//  CreateCVSheetView.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct CreateCVSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: CVViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedPDFData: Data?
    @State private var selectedPDFName: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingDocumentPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Основная информация") {
                    TextField("Название резюме", text: $title)
                    TextField("Описание", text: $description, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                Section("PDF файл") {
                    Button("Выбрать PDF") {
                        showingDocumentPicker = true
                    }
                    .sheet(isPresented: $showingDocumentPicker) {
                        DocumentPicker(
                            selectedFileData: $selectedPDFData,
                            selectedFileName: $selectedPDFName,
                            allowedContentTypes: [.pdf]
                        )
                    }
                    
                    if let fileName = selectedPDFName {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text(fileName)
                                .lineLimit(1)
                            Spacer()
                            Button {
                                selectedPDFData = nil
                                selectedPDFName = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
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
                    Button("Создать") {
                        Task { await create() }
                    }
                    .disabled(title.isEmpty || description.isEmpty || isLoading)
                    
                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Новое резюме")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
    
    private func create() async {
        isLoading = true
        errorMessage = nil
        do {
            if let pdfData = selectedPDFData {
                _ = try await viewModel.createCVWithPDF(title: title, description: description, pdfData: pdfData, fileName: selectedPDFName ?? "document.pdf")
            } else {
                _ = try await viewModel.createCV(title: title, description: description)
            }
            await viewModel.loadMyCVs()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
