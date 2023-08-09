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

    private static func defaultControlsView(crop: @escaping () async -> ()) -> AnyView { AnyView(
        VStack {
            Spacer()
            HStack {
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
    ) }

    /// The image to crop.
    public var image: PlatformImage
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
    public var controls: (_ crop: @escaping () async -> ()) -> Controls

    /// Create a ``CropImageView`` with a custom ``controls`` view.
    public init(
        image: PlatformImage,
        targetSize: CGSize,
        targetScale: CGFloat = 1,
        onCrop: @escaping (Result<PlatformImage, Error>) -> Void,
        @ViewBuilder controls: @escaping (_ crop: () async -> ()) -> Controls
    ) {
        self.image = image
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
        targetSize: CGSize,
        targetScale: CGFloat = 1,
        onCrop: @escaping (Result<PlatformImage, Error>) -> Void
    ) where Controls == AnyView {
        self.image = image
        self.targetSize = targetSize
        self.targetScale = targetScale
        self.onCrop = onCrop
        self.controls = Self.defaultControlsView
    }

    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1

    @MainActor
    func crop() throws -> PlatformImage {
        let snapshotView = MoveAndScalableImageView(offset: $offset, scale: $scale, image: image)
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

    public var body: some View {
        ZStack {
            MoveAndScalableImageView(offset: $offset, scale: $scale, image: image)
            RectHoleShape(size: targetSize)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(.black.opacity(0.6))
                .allowsHitTesting(false)
            controls {
                do {
                    onCrop(.success(try crop()))
                } catch {
                    onCrop(.failure(error))
                }
            }
        }
    }
}

struct CropImageView_Previews: PreviewProvider {
    struct PreviewView: View {
        @State private var targetSize: CGSize = .init(width: 100, height: 100)
        @State private var result: Result<PlatformImage, Error>? = nil

        var body: some View {
            VStack {
                CropImageView(
                    image: .init(contentsOfFile: "/Users/laosb/Downloads/png.png")!,
                    targetSize: targetSize
                ) { result = $0 }
                Form {
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
            .frame(minHeight: 750)
        #endif
    }
}
