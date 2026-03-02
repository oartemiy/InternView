//
//  CVDetailViewModel.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import Foundation
import Combine

@MainActor
class CVDetailViewModel: ObservableObject {
    @Published var cv: CV
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = APIService.shared
    
    init(cv: CV) {
        self.cv = cv
    }
    
    func updatePDF(pdfData: Data, fileName: String) async {
        isLoading = true
        defer { isLoading = false }
        let parameters: [String: String] = [:]
        do {
            let updated: CV = try await api.uploadMultipart(
                endpoint: "/cvs/\(cv.id)",
                method: "PUT",
                parameters: parameters,
                fileData: pdfData,
                fileKey: "pdfFile",
                fileName: fileName,
                mimeType: "application/pdf"
            )
            self.cv = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
