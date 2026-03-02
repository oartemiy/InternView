//
//  CVViewModel.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class CVViewModel: ObservableObject {
    @Published var cvs: [CV] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = APIService.shared
    private let auth = AuthService.shared
    
    // Загрузить все CV текущего пользователя
    func loadMyCVs() async {
        isLoading = true
        errorMessage = nil
        do {
            // Получаем список всех CV (сервер может отдавать все, фильтруем на клиенте)
            let allCVs: [CV] = try await api.request(endpoint: "/cvs")
            // Фильтруем по текущему пользователю
            if let userId = auth.currentUser?.id {
                self.cvs = allCVs.filter { $0.userId == userId }
            } else {
                self.cvs = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // Создать новое CV (без PDF, потом можно добавить)
    func createCV(title: String, description: String) async throws -> CV {
        struct CreateCVBody: Encodable {
            let title: String
            let description: String
        }
        let body = CreateCVBody(title: title, description: description)
        let cv: CV = try await api.request(endpoint: "/cvs", method: "POST", body: body)
        return cv
    }
    
    // Удалить CV
    func deleteCV(_ cv: CV) async throws {
        _ = try await api.request(endpoint: "/cvs/\(cv.id)", method: "DELETE") as EmptyResponse?
        // Удаляем из локального списка
        if let index = cvs.firstIndex(where: { $0.id == cv.id }) {
            cvs.remove(at: index)
        }
    }
    
    func createCVWithPDF(title: String, description: String, pdfData: Data, fileName: String) async throws -> CV {
        let parameters = [
            "title": title,
            "description": description
        ]
        let cv: CV = try await api.uploadMultipart(
            endpoint: "/cvs",
            method: "POST",
            parameters: parameters,
            fileData: pdfData,
            fileKey: "pdfFile",   // имя поля, которое ждёт сервер
            fileName: fileName,
            mimeType: "application/pdf"
        )
        return cv
    }
    
    func updateCV(_ cv: CV, title: String, description: String, pdfData: Data?) async throws -> CV {
        let parameters: [String: String] = [
            "title": title,
            "description": description
        ]
        
        let updatedCV: CV = try await api.uploadMultipart(
            endpoint: "/cvs/\(cv.id)",
            method: "PUT",
            parameters: parameters,
            fileData: pdfData,
            fileKey: "pdfFile",
            fileName: "document.pdf",
            mimeType: "application/pdf"
        )
        
        // Обновляем локальный список
        if let index = cvs.firstIndex(where: { $0.id == cv.id }) {
            cvs[index] = updatedCV
        }
        return updatedCV
    }
}

