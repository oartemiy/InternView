//
//  InternViewApp.swift
//  InternView
//
//  Created by Артемий Образцов on 21.02.2026.
//

import SwiftUI
import SwiftData

@main
struct InternViewApp: App {
    let container: ModelContainer
    @State private var isReady = false

    init() {
        do {
            container = try ModelContainer(for: PersistentUser.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if isReady {
                ContentView()
                    .environmentObject(AuthService.shared)
                    .modelContainer(container)
            } else {
                SplashScreen()
                    .onAppear {
                        Task {
                            // Инициализируем AuthService с контекстом (восстановление сессии)
                            AuthService.shared.setupModelContext(container.mainContext)
                            // Даем сплеш-экрану показаться минимум 1 секунду
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            isReady = true
                        }
                    }
            }
        }
    }
}

