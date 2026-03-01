//
//  RegisterView.swift
//  InternView
//
//  Created by Артемий Образцов on 21.02.2026.
//

import PhotosUI
import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var login = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var role = "intern"
    @State private var description = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var croppedImageData: Data?
    @State private var showCropView = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Основное") {
                    TextField("Имя", text: $name)
                    TextField("Email", text: $login)
                        .autocapitalization(.none)
                    SecureField("Пароль", text: $password)
                    SecureField("Повторите пароль", text: $confirmPassword)
                }

                Section("Роль") {
                    Picker("Роль", selection: $role) {
                        Text("Интерн").tag("intern")
                        Text("Рекрутер").tag("recruiter")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Фото профиля") {
                    if croppedImageData == nil {
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images
                        ) {
                            Label("Выбрать фото", systemImage: "photo")
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?
                                    .loadTransferable(type: Data.self),
                                    let image = UIImage(data: data)
                                {
                                    selectedImage = image
                                    showCropView = true
                                }
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Фото готово")
                                .foregroundColor(.green)
                            Spacer()
                            Button(role: .destructive) {
                                croppedImageData = nil
                                selectedItem = nil
                                selectedImage = nil
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                Section("О себе") {
                    TextField(
                        "Краткое описание",
                        text: $description,
                        axis: .vertical
                    )
                    .lineLimit(3...5)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button("Зарегистрироваться") {
                        Task { await performRegister() }
                    }
                    .disabled(!isFormValid || isLoading)

                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Регистрация")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .sheet(isPresented: $showCropView) {
                if let image = selectedImage {
                    ImageCropView(
                        image: image,
                        onCrop: { croppedImage in
                            croppedImageData = croppedImage.jpegData(
                                compressionQuality: 0.8
                            )
                            showCropView = false
                            selectedImage = nil
                        },
                        onCancel: {
                            showCropView = false
                            selectedImage = nil
                            selectedItem = nil
                        }

                    )
                }
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && !login.isEmpty && !password.isEmpty
            && password == confirmPassword && password.count >= 6
    }

    private func performRegister() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.register(
                name: name,
                login: login,
                password: password,
                role: role,
                description: description.isEmpty ? nil : description,
                imageData: croppedImageData
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
