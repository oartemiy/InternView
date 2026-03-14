//
//  ContentView.swift
//  InternView
//
//  Created by Артемий Образцов on 21.02.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            authService.setupModelContext(modelContext)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        TabView {
//            Text("Вакансии")
//                .tabItem {
//                    Label("Поиск", systemImage: "magnifyingglass")
//                }
            
            
            
            if authService.currentUser?.role == "intern" {
                VacancyListView()
                    .tabItem {
                        Label("Вакансии", systemImage: "magnifyingglass")
                    }
                CVListView()
                    .tabItem {
                        Label("Мои CV", systemImage: "doc")
                    }
                MyApplicationsView()
                    .tabItem {
                        Label("Отклики", systemImage: "envelope")
                    }
            }
            
            if authService.currentUser?.role == "recruiter" {
                MyVacanciesView()
                    .tabItem {
                        Label("Мои вакансии", systemImage: "briefcase")
                    }

            }
            
            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person")
                }
        }
    }
}

