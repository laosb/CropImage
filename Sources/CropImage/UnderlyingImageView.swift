//
//  UnderlyingImageView.swift
//
//
//  Created by Shibo Lyu on 2023/7/21.
//

import SwiftUI

private extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        .init(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
}

struct UnderlyingImageView: View {
    @Binding var offset: CGSize
    @Binding var scale: CGFloat
    @Binding var rotation: Angle
    var image: PlatformImage
    var initialImageSize: CGSize

    @State private var tempOffset: CGSize = .zero
    @State private var tempScale: CGFloat = 1
    @State private var tempRotation: Angle = .zero

    var imageView: Image {
#if os(macOS)
        Image(nsImage: image)
#elseif os(iOS)
        Image(uiImage: image)
#endif
    }

    var body: some View {
        ZStack {
            imageView
                .resizable()
                .scaledToFit()
                .frame(width: initialImageSize.width, height: initialImageSize.height)
                .animation(.default, value: initialImageSize)
                .scaleEffect(scale * tempScale)
                .offset(offset + tempOffset)
                .rotationEffect(rotation + tempRotation)
            Color.white.opacity(0.0001)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            tempOffset = value.translation
                        }
                        .onEnded { value in
                            offset = offset + tempOffset
                            tempOffset = .zero
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            tempScale = value
                        }
                        .onEnded { value in
                            scale = max(scale * tempScale, 0.01)
                            tempScale = 1
                        }
                )
                .gesture(
                    RotationGesture()
                        .onChanged { value in
                            tempRotation = value
                        }
                        .onEnded { value in
                            rotation = rotation + tempRotation
                            tempRotation = .zero
                        }
                )
        }
    }
}

struct MoveAndScalableImageView_Previews: PreviewProvider {
    struct PreviewView: View {
        @State private var offset: CGSize = .zero
        @State private var scale: CGFloat = 1
        @State private var rotation: Angle = .zero

        var body: some View {
            UnderlyingImageView(
                offset: $offset,
                scale: $scale,
                rotation: $rotation,
                image: .init(contentsOfFile: "/Users/laosb/Downloads/png.png")!,
                initialImageSize: .init(width: 200, height: 200)
            )
        }
    }

    static var previews: some View {
        PreviewView()
    }
}
