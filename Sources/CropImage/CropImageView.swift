//
//  CropImageView.swift
//
//
//  Created by Shibo Lyu on 2023/7/21.
//

import SwiftUI

public struct CropImageView: View {
    var image: PlatformImage
    var targetSize: CGSize
    var onCrop: (PlatformImage) -> Void

    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1

    public var body: some View {
        ZStack {
            MoveAndScalableImageView(offset: $offset, scale: $scale, image: image)
            RectHoleShape(size: targetSize)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(.black.opacity(0.6))
                .allowsHitTesting(false)
        }
    }
}

struct CropImageView_Previews: PreviewProvider {
    struct PreviewView: View {
        @State private var croppedImage: PlatformImage? = nil

        var body: some View {
            VStack {
                CropImageView(
                    image: .init(contentsOfFile: "/Users/laosb/Downloads/png.png")!,
                    targetSize: .init(width: 100, height: 100)
                ) { _ in

                }
                if let croppedImage {
                    #if os(macOS)
                    Image(nsImage: croppedImage)
                    #elseif os(iOS)
                    Image(uiImage: croppedImage)
                    #endif
                } else {
                    Text("Press \(Image(systemName: "checkmark.circle.fill")) to crop.")
                }
            }
        }
    }

    static var previews: some View {
        PreviewView()
    }
}
