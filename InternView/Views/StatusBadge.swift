//
//  StatusBadge.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI

struct StatusBadge: View {
    let status: String
    
    var color: Color {
        switch status {
        case "pending": return .orange
        case "reviewed": return .blue
        case "approved": return .green
        case "rejected": return .red
        case "cancelled": return .gray
        default: return .secondary
        }
    }
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}
