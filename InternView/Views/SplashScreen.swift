//
//  SplashScreen.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import SwiftUI

struct SplashScreen: View {
    @State private var scale = 0.7
    @State private var opacity = 0.0
    @State private var rotation = -30.0
    @State private var textOffset: CGFloat = 50

    var body: some View {
        ZStack {
            // Анимированный градиентный фон
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.8),
                    Color.pink.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            // Декоративные круги для глубины
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .scaleEffect(scale)
                    .offset(x: -50, y: -100)
                    .blur(radius: 50)
            )
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .scaleEffect(1.5 - scale)
                    .offset(x: 80, y: 150)
                    .blur(radius: 60)
            )

            VStack(spacing: 20) {
                // Логотип
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .opacity(opacity)

                // Название
                Text("InternView")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)
                    .offset(y: textOffset)
            }
        }
        .onAppear {
            // Последовательные анимации появления
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                scale = 1.0
                rotation = 0
                opacity = 1.0
            }

            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                textOffset = 0
            }

            // Бесконечная пульсация после появления
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
                scale = 1.1
            }
        }
    }
}
