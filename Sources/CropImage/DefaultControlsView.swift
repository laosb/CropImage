//
//  DefaultControlsView.swift
//
//
//  Created by Shibo Lyu on 2023/8/10.
//

import SwiftUI

/// The default controls view used when creating ``CropImageView`` using ``CropImageView/init(image:targetSize:targetScale:fulfillTargetFrame:onCrop:)``.
///
/// It provides basic controls to crop, reset to default cropping & rotation, and rotate the image.
public struct DefaultControlsView: View {
    @Binding var offset: CGSize
    @Binding var scale: CGFloat
    @Binding var rotation: Angle
    var crop: () async -> Void

    var rotateButton: some View {
        Button {
            let roundedAngle = Angle.degrees((rotation.degrees / 90).rounded() * 90)
            withAnimation(.interactiveSpring()) {
                rotation = roundedAngle + .degrees(90)
            }
        } label: {
            Label("Rotate", systemImage: "rotate.right")
                .font(.title2)
                .foregroundColor(.accentColor)
                .labelStyle(.iconOnly)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(.background)
                )
        }
        .buttonStyle(.plain)
        .padding()
    }

    var resetButton: some View {
        Button("Reset") {
            withAnimation {
                offset = .zero
                scale = 1
                rotation = .zero
            }
        }
    }

    var cropButton: some View {
        Button { Task {
            await crop()
        } } label: {
            Label("Crop", systemImage: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
                .labelStyle(.iconOnly)
                .padding(1)
                .background(
                    Circle().fill(.background)
                )
        }
        .buttonStyle(.plain)
        .padding()
    }

    public var body: some View {
        VStack {
            Spacer()
            HStack {
                rotateButton
                Spacer()
                if #available(iOS 15.0, macOS 13.0, *) {
                    resetButton
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle)
                } else {
                    resetButton
                }
                Spacer()
                cropButton
            }
        }
    }
}
