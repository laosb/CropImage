//
//  MoveAndScalableImageView.swift
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

struct MoveAndScalableImageView: View {
    @Binding var offset: CGSize
    @Binding var scale: CGFloat
    var image: PlatformImage

    @State private var tempOffset: CGSize = .zero
    @State private var tempScale: CGFloat = 1

    var body: some View {
        ZStack {
            #if os(macOS)
            Image(nsImage: image)
                .scaleEffect(scale * tempScale)
                .offset(offset + tempOffset)
            #elseif os(iOS)
            Image(uiImage: image)
                .scaleEffect(scale * tempScale)
                .offset(offset + tempOffset)
            #endif
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
                            tempScale = value.magnitude
                        }
                        .onEnded { value in
                            scale = scale * tempScale
                            tempScale = 1
                        }
                )
        }
    }
}

struct MoveAndScalableImageView_Previews: PreviewProvider {
    struct PreviewView: View {
        @State private var offset: CGSize = .zero
        @State private var scale: CGFloat = 1

        var body: some View {
            MoveAndScalableImageView(offset: $offset, scale: $scale, image: .init(contentsOfFile: "/Users/laosb/Downloads/png.png")!)
        }
    }

    static var previews: some View {
        PreviewView()
    }
}
