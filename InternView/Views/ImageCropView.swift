//
//  ImageCropView.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation
import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    var onCrop: (UIImage) -> Void
    var onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    let cropSize: CGFloat = 300
    @State private var minScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            let viewSize = geometry.size
            let imageSize = image.size

            // Масштаб для вписывания изображения в экран
            let fitScale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
            let scaledImageSize = CGSize(width: imageSize.width * fitScale, height: imageSize.height * fitScale)

            // Минимальный масштаб, чтобы изображение всегда закрывало квадрат
            let computedMinScale = max(cropSize / scaledImageSize.width, cropSize / scaledImageSize.height)

            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = max(computedMinScale, scale * (value / lastScale))
                                scale = newScale
                                lastScale = value
                                // Корректируем offset после изменения масштаба
                                offset = clampedOffset(offset, in: viewSize, scale: scale, fitScale: fitScale)
                                lastOffset = offset
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                let proposed = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                offset = clampedOffset(proposed, in: viewSize, scale: scale, fitScale: fitScale)
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .frame(width: viewSize.width, height: viewSize.height)
                    .onAppear {
                        scale = computedMinScale
                        offset = .zero
                        lastOffset = .zero
                    }

                // Затемняющий слой с отверстием
                Color.black.opacity(0.5)
                    .mask(
                        Rectangle()
                            .overlay(
                                Rectangle()
                                    .frame(width: cropSize, height: cropSize)
                                    .position(x: viewSize.width / 2, y: viewSize.height / 2)
                                    .blendMode(.destinationOut)
                            )
                    )
                    .allowsHitTesting(false)

                // Рамка квадрата
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropSize, height: cropSize)
                    .position(x: viewSize.width / 2, y: viewSize.height / 2)
                    .allowsHitTesting(false)

                // Кнопки
                VStack {
                    HStack {
                        Button("Отмена") {
                            onCancel()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)

                        Spacer()

                        Button("Готово") {
                            if let cropped = cropImage(in: viewSize, fitScale: fitScale) {
                                onCrop(cropped)
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    Text("Масштабируйте двумя пальцами, перемещайте")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .padding(.bottom, 30)
                }
                .padding(.top, 50)
            }
        }
    }

    private func clampedOffset(_ proposed: CGSize, in viewSize: CGSize, scale: CGFloat, fitScale: CGFloat) -> CGSize {
        let scaledImageWidth = image.size.width * fitScale * scale
        let scaledImageHeight = image.size.height * fitScale * scale

        let maxOffsetX = max(0, (scaledImageWidth - cropSize) / 2)
        let maxOffsetY = max(0, (scaledImageHeight - cropSize) / 2)

        return CGSize(
            width: min(max(proposed.width, -maxOffsetX), maxOffsetX),
            height: min(max(proposed.height, -maxOffsetY), maxOffsetY)
        )
    }

    private func cropImage(in viewSize: CGSize, fitScale: CGFloat) -> UIImage? {
        let imageSize = image.size

        // Экранные координаты центра квадрата и изображения
        let imageCenter = CGPoint(
            x: viewSize.width / 2 + offset.width,
            y: viewSize.height / 2 + offset.height
        )

        let imageOrigin = CGPoint(
            x: imageCenter.x - (imageSize.width * fitScale * scale) / 2,
            y: imageCenter.y - (imageSize.height * fitScale * scale) / 2
        )

        let cropRectOnScreen = CGRect(
            x: (viewSize.width - cropSize) / 2,
            y: (viewSize.height - cropSize) / 2,
            width: cropSize,
            height: cropSize
        )

        // Переводим в координаты исходного изображения (пиксели)
        let cropXInImage = (cropRectOnScreen.minX - imageOrigin.x) / (fitScale * scale)
        let cropYInImage = (cropRectOnScreen.minY - imageOrigin.y) / (fitScale * scale)
        let cropWidthInImage = cropSize / (fitScale * scale)
        let cropHeightInImage = cropSize / (fitScale * scale)

        let cropRect = CGRect(
            x: max(0, min(cropXInImage, imageSize.width - cropWidthInImage)),
            y: max(0, min(cropYInImage, imageSize.height - cropHeightInImage)),
            width: min(cropWidthInImage, imageSize.width),
            height: min(cropHeightInImage, imageSize.height)
        )

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return nil }
        let cropped = UIImage(cgImage: cgImage)

        // Ресайз до 300×300
        let targetSize = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            cropped.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized
    }
}
