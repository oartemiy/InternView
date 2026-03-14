//
//  VacancyDetailView.swift
//  InternView
//
//  Created by Артемий Образцов on 02.03.2026.
//

import Foundation
import SwiftUI

struct VacancyDetailView: View {
    let vacancy: Vacancy.Simple
    @StateObject private var applicationVM = ApplicationViewModel()
    @State private var showApplySheet = false
    @State private var hasApplied = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Заголовок
                Text(vacancy.title)
                    .font(.largeTitle)
                    .bold()
                
                // Мета-информация
                HStack {
                    Label(vacancy.location, systemImage: "location")
                    Spacer()
                    if let salary = vacancy.salaryRange {
                        Label(salary, systemImage: "rublesign")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                HStack {
                    Text("Формат: \(vacancy.workMode)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("Уровень: \(vacancy.experienceLevel)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Divider()
                
                // Описание
                Text("Описание")
                    .font(.headline)
                Text(vacancy.description)
                    .font(.body)
                
                // Требования
                Text("Требования")
                    .font(.headline)
                ForEach(vacancy.requirements, id: \.self) { req in
                    Label(req, systemImage: "checkmark.circle")
                        .font(.body)
                }
                
                // Дополнительно
                if let expiresAt = vacancy.expiresAt {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Вакансия действительна до \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                // Кнопка отклика
                if vacancy.isActive {
                    Button {
                        // Проверяем, есть ли у пользователя CV
                        // Пока просто показываем лист
                        showApplySheet = true
                    } label: {
                        if hasApplied {
                            Label("Вы уже откликнулись", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Откликнуться")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(hasApplied)
                    .padding(.top)
                } else {
                    Text("Вакансия неактивна")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Детали вакансии")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showApplySheet) {
            ApplyVacancySheet(vacancyId: vacancy.id, onApplied: {
                hasApplied = true
            })
        }
        .task {
            // Проверить, откликался ли пользователь на эту вакансию
            await checkIfApplied()
        }
    }
    
    private func checkIfApplied() async {
        // Можно запросить мои отклики и проверить, есть ли с этой vacancyId
        await applicationVM.loadMyApplications()
        if applicationVM.applications.contains(where: { $0.vacancyId == vacancy.id }) {
            hasApplied = true
        }
    }
}
