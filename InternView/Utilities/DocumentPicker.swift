//
//  DocumentPicker.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFileData: Data?
    @Binding var selectedFileName: String?
    let allowedContentTypes: [UTType]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            // Получаем доступ к файлу
            let shouldStopAccessing = url.startAccessingSecurityScopedResource()
            defer { if shouldStopAccessing { url.stopAccessingSecurityScopedResource() } }
            
            do {
                let data = try Data(contentsOf: url)
                parent.selectedFileData = data
                parent.selectedFileName = url.lastPathComponent
            } catch {
                print("Error reading file: \(error)")
            }
        }
    }
}
