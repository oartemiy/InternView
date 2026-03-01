import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var profileImage: UIImage?
    @State private var isLoadingImage = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false

    var body: some View {
        NavigationView {
            Form {
                if let user = authService.currentUser {
                    Section {
                        HStack(spacing: 15) {
                            // Аватарка
                            if isLoadingImage {
                                ProgressView()
                                    .frame(width: 60, height: 60)
                            } else if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.login)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(
                                    user.role == "intern"
                                        ? "Интерн" : "Рекрутер"
                                )
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    user.role == "intern"
                                        ? Color.blue.opacity(0.2)
                                        : Color.green.opacity(0.2)
                                )
                                .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 5)
                    }

                    if let description = user.description, !description.isEmpty
                    {
                        Section("О себе") {
                            Text(description)
                        }
                    }

                    Section("Информация") {
                        if let createdAt = user.createdAt {
                            LabeledContent(
                                "Зарегистрирован",
                                value: createdAt.formatted(
                                    date: .abbreviated,
                                    time: .omitted
                                )
                            )
                        } else {
                            LabeledContent(
                                "Зарегистрирован",
                                value: "неизвестно"
                            )
                        }
                    }
                }

                Section {
                    Button("Выйти", role: .destructive) {
                        authService.logout()
                    }
                }

                Section {
                    Button("Удалить аккаунт", role: .destructive) {
                        showingDeleteAlert = true
                    }
                    .disabled(isDeleting)
                }
            }
            .navigationTitle("Профиль")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Редактировать") {
                        EditProfileView()
                            .environmentObject(authService)
                    }
                }
            }
            .onAppear {
                loadProfileImage()
            }.alert("Удаление аккаунта", isPresented: $showingDeleteAlert) {
                Button("Удалить", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text(
                    "Вы уверены? Это действие необратимо. Все ваши данные будут удалены."
                )
            }
            .onChange(of: authService.currentUser) { _ in
                loadProfileImage()
            }
        }
    }

    private func loadProfileImage() {
        guard let user = authService.currentUser,
            let profilePic = user.profilePic,
            !profilePic.isEmpty
        else {
            profileImage = nil
            return
        }

        let fullURLString: String
        if profilePic.hasPrefix("http") {
            fullURLString = profilePic
        } else {
            fullURLString = Constants.baseURL + profilePic
        }

        guard let url = URL(string: fullURLString) else { return }

        // Сбрасываем текущее изображение, чтобы не показывать старое
        profileImage = nil
        isLoadingImage = true

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoadingImage = false
                if let data = data, let image = UIImage(data: data) {
                    profileImage = image
                } else {
                    // Если не удалось загрузить, оставляем nil
                    profileImage = nil
                }
            }
        }.resume()
    }

    private func deleteAccount() async {
        isDeleting = true
        do {
            try await authService.deleteAccount()
            // logout уже внутри deleteAccount
        } catch {
            print("Delete error: \(error)")
            isDeleting = false
        }
    }
}
