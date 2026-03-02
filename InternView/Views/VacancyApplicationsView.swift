//
//  VacancyApplicationsView.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI

struct VacancyApplicationsView: View {
    let vacancyId: UUID
    @StateObject private var viewModel = ApplicationViewModel()
    @State private var selectedApplication: Application?
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.applications.isEmpty {
                ContentUnavailableView("Нет откликов", systemImage: "person.crop.circle.badge.exclamationmark")
            } else {
                List(viewModel.applications) { application in
                    NavigationLink(destination: RecruiterApplicationDetailView(application: application)) {
                        VStack(alignment: .leading) {
                            Text(application.intern?.name ?? "Кандидат")
                                .font(.headline)
                            StatusBadge(status: application.status)
                        }
                    }
                }
            }
        }
        .navigationTitle("Отклики")
        .task {
            await viewModel.loadApplications(for: vacancyId)
        }
    }
}
