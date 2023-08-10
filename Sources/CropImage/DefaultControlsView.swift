//
//  DefaultControlsView.swift
//
//
//  Created by Shibo Lyu on 2023/8/10.
//

import SwiftUI

/// The default controls view used when creating ``CropImageView`` using ``CropImageView/init(image:targetSize:targetScale:onCrop:)``.
///
/// It provides basic controls to crop, reset to default cropping & rotation, and rotate the image.
public struct DefaultControlsView: View {
    @Binding var offset: CGSize
    @Binding var scale: CGFloat
    @Binding var rotation: Angle
    var crop: () async -> Void

    public var body: some View {
        VStack {
            Spacer()
            HStack {
                Button {
                    let roundedAngle = Angle.degrees((rotation.degrees / 90).rounded() * 90)
                    withAnimation {
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
                                .fill(.white)
                        )
                }
                .buttonStyle(.plain)
                .padding()
                Spacer()
                Button("Reset") {
                    withAnimation {
                        offset = .zero
                        scale = 1
                        rotation = .zero
                    }
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                Spacer()
                Button { Task {
                    await crop()
                } } label: {
                    Label("Crop", systemImage: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .labelStyle(.iconOnly)
                        .padding(1)
                        .background(
                            Circle().fill(.white)
                        )
                }
                .buttonStyle(.plain)
                .padding()
            }
        }
    }
}
