//
//  LoginView.swift
//  InternView
//
//  Created by Артемий Образцов on 21.02.2026.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var login = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRegister = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Логин", text: $login)
                        .autocapitalization(.none)
                    SecureField("Пароль", text: $password)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Войти") {
                        Task { await performLogin() }
                    }
                    .disabled(login.isEmpty || password.isEmpty || isLoading)
                    
                    if isLoading {
                        ProgressView()
                    }
                }
                
                Section {
                    Button("Нет аккаунта? Зарегистрироваться") {
                        showRegister = true
                    }
                }
            }
            .navigationTitle("Вход")
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
    
    private func performLogin() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.login(username: login, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
