import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
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
                }

                Section("О себе") {
                    TextField("Краткое описание", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("Фото профиля") {
                    if croppedImageData == nil {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Выбрать новое фото", systemImage: "photo")
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    selectedImage = image
                                    showCropView = true
                                }
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Новое фото готово")
                            Spacer()
                            Button("Удалить") {
                                croppedImageData = nil
                                selectedItem = nil
                                selectedImage = nil
                            }
                            .foregroundColor(.red)
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
                        Task { await saveChanges() }
                    }
                    .disabled(name.isEmpty || isLoading)

                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Редактировать профиль")
            .navigationBarTitleDisplayMode(.inline)
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
                            croppedImageData = croppedImage.jpegData(compressionQuality: 0.8)
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
            .onAppear {
                if let user = authService.currentUser {
                    name = user.name
                    description = user.description ?? ""
                }
            }
        }
    }

    private func saveChanges() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.updateProfile(
                name: name,
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
