//
//  CropImageView.swift
//
//
//  Created by Shibo Lyu on 2023/7/21.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

/// A view that allows the user to crop an image.
public struct CropImageView<Controls: View>: View {
    public typealias ControlClosure<Controls> = (
        _ offset: Binding<CGSize>,
        _ scale: Binding<CGFloat>,
        _ rotation: Binding<Angle>,
        _ crop: @escaping () async -> ()
    ) -> Controls

    /// Errors that could happen during the cropping process.
    public enum CropError: Error {
        /// SwiftUI `ImageRenderer` returned nil when calling `nsImage` or `uiImage`.
        ///
        /// See [SwiftUI - ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer) for more information.
        case imageRendererReturnedNil
        /// `UIGraphicsGetCurrentContext()` call returned `nil`.
        ///
        /// It shouldn't happen, but if it does it will only be on iOS versions prior to 16.0.
        case failedToGetCurrentUIGraphicsContext
        /// `UIGraphicsGetImageFromCurrentImageContext()` call returned `nil`.
        ///
        /// It shouldn't happen, but if it does it will only be on iOS versions prior to 16.0.
        case failedToGetImageFromCurrentUIGraphicsImageContext
    }

    /// The image to crop.
    public var image: PlatformImage
    /// The region in which the image is initially fitted in, in points.
    public var initialImageSize: CGSize
    /// The intended size of the cropped image, in points.
    public var targetSize: CGSize
    /// The intended scale of the cropped image.
    ///
    /// This defines the point to pixel ratio for the output image. Defaults to `1`.
    public var targetScale: CGFloat = 1
    /// A closure that will be called when the user finishes cropping.
    ///
    /// The error should be a ``CropError``.
    public var onCrop: (Result<PlatformImage, Error>) -> Void
    /// A custom view overlaid on the image cropper.
    ///
    /// - Parameters:
    ///   - crop: An async function to trigger crop action. Result will be delivered via ``onCrop``.
    public var controls: ControlClosure<Controls>

    /// Create a ``CropImageView`` with a custom ``controls`` view.
    public init(
        image: PlatformImage,
        initialImageSize: CGSize,
        targetSize: CGSize,
        targetScale: CGFloat = 1,
        onCrop: @escaping (Result<PlatformImage, Error>) -> Void,
        @ViewBuilder controls: @escaping ControlClosure<Controls>
    ) {
        self.image = image
        self.initialImageSize = initialImageSize
        self.targetSize = targetSize
        self.targetScale = targetScale
        self.onCrop = onCrop
        self.controls = controls
    }
    /// Create a ``CropImageView`` with the default ``controls`` view.
    ///
    /// The default ``controls`` view is a simple overlay with a checkmark icon on the bottom-trailing corner to trigger crop action.
    public init(
        image: PlatformImage,
        initialImageSize: CGSize,
        targetSize: CGSize,
        targetScale: CGFloat = 1,
        onCrop: @escaping (Result<PlatformImage, Error>) -> Void
    ) where Controls == DefaultControlsView {
        self.image = image
        self.initialImageSize = initialImageSize
        self.targetSize = targetSize
        self.targetScale = targetScale
        self.onCrop = onCrop
        self.controls = { $offset, $scale, $rotation, crop in
            DefaultControlsView(offset: $offset, scale: $scale, rotation: $rotation, crop: crop)
        }
    }

    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1
    @State private var rotation: Angle = .zero

    @MainActor
    func crop() throws -> PlatformImage {
        let snapshotView = UnderlyingImageView(
            offset: $offset,
            scale: $scale,
            rotation: $rotation,
            image: image,
            initialImageSize: initialImageSize
        )
        .frame(width: targetSize.width, height: targetSize.height)
        if #available(iOS 16.0, macOS 13.0, *) {
            let renderer = ImageRenderer(content: snapshotView)
            renderer.scale = targetScale
#if os(iOS)
            if let image = renderer.uiImage {
                return image
            } else {
                throw CropError.imageRendererReturnedNil
            }
#elseif os(macOS)
            if let image = renderer.nsImage {
                return image
            } else {
                throw CropError.imageRendererReturnedNil
            }
#endif
        } else {
#if os(macOS)
            fatalError("Cropping is not supported on macOS versions before Ventura 13.0.")
#elseif os(iOS)
            let window = UIWindow(frame: CGRect(origin: .zero, size: targetSize))
            let hosting = UIHostingController(rootView: snapshotView)
            hosting.view.frame = window.frame
            window.addSubview(hosting.view)
            window.makeKeyAndVisible()
            UIGraphicsBeginImageContextWithOptions(hosting.view.bounds.size, false, targetScale)
            guard let context = UIGraphicsGetCurrentContext() else {
                throw CropError.failedToGetCurrentUIGraphicsContext
            }
            hosting.view.layer.render(in: context)
            guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
                throw CropError.failedToGetImageFromCurrentUIGraphicsImageContext
            }
            UIGraphicsEndImageContext()
            return image
#endif
        }
    }

    var underlyingImage: some View {
        UnderlyingImageView(
            offset: $offset,
            scale: $scale,
            rotation: $rotation,
            image: image,
            initialImageSize: initialImageSize
        )
    }

    var rectHole: some View {
        RectHoleShape(size: targetSize)
            .fill(style: FillStyle(eoFill: true))
            .foregroundColor(.black.opacity(0.6))
            .animation(.default, value: targetSize)
            .allowsHitTesting(false)
    }

    @MainActor var control: some View {
        controls($offset, $scale, $rotation) {
            do {
                onCrop(.success(try crop()))
            } catch {
                onCrop(.failure(error))
            }
        }
    }

    public var body: some View {
        underlyingImage
            .clipped()
            .overlay(rectHole)
            .overlay(control)
    }
}

struct CropImageView_Previews: PreviewProvider {
    struct PreviewView: View {
        @State private var initialImageSize: CGSize = .init(width: 200, height: 200)
        @State private var targetSize: CGSize = .init(width: 100, height: 100)
        @State private var result: Result<PlatformImage, Error>? = nil

        var body: some View {
            VStack {
                CropImageView(
                    image: .init(contentsOfFile: "/Users/laosb/Downloads/png.png")!,
                    initialImageSize: initialImageSize,
                    targetSize: targetSize
                ) { result = $0 }
                Form {
                    Section {
                        TextField("Width", value: $initialImageSize.width, formatter: NumberFormatter())
                        TextField("Height", value: $initialImageSize.height, formatter: NumberFormatter())
                    } header: {
                        Text("Initial Image Size")
                        Text("The image will be fitted into this region.")
                    }
                    Section {
                        TextField("Width", value: $targetSize.width, formatter: NumberFormatter())
                        TextField("Height", value: $targetSize.height, formatter: NumberFormatter())
                    } header: { Text("Crop Target Size") }
                    Section {
                        if let result {
                            switch result {
                            case let .success(croppedImage):
#if os(macOS)
                                Image(nsImage: croppedImage)
#elseif os(iOS)
                                Image(uiImage: croppedImage)
#endif
                            case let .failure(error):
                                Text(error.localizedDescription)
                                    .foregroundColor(.red)
                            }
                        } else {
                            Text("Press \(Image(systemName: "checkmark.circle.fill")) to crop.")
                        }
                    } header: { Text("Result") }
                }
                #if os(macOS)
                .formStyle(.grouped)
                #endif
            }
        }
    }

    static var previews: some View {
        PreviewView()
        #if os(macOS)
            .frame(width: 500)
            .frame(minHeight: 770)
        #endif
    }
}
