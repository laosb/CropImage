//
//  CropImageView.swift
//
//
//  Created by Shibo Lyu on 2023/7/21.
//

import SwiftUI
#if !os(macOS)
import UIKit
#endif

/// A view that allows the user to crop an image.
public struct CropImageView<Controls: View, CutHole: View>: View {
    /// Defines a custom view overlaid on the image cropper.
    ///
    /// - Parameters:
    ///   - offset: The offset binding of the image.
    ///   - scale: The scale binding of the image.
    ///   - rotation: The rotation binding of the image.
    ///   - crop: An async function to trigger crop action. Result will be delivered via ``onCrop``.
    public typealias ControlClosure<Controls> = (
        _ offset: Binding<CGSize>,
        _ scale: Binding<CGFloat>,
        _ rotation: Binding<Angle>,
        _ crop: @escaping () async -> ()
    ) -> Controls

    /// Defines custom view that indicates the cut hole to users.
    ///
    /// - Parameters:
    ///   - targetSize: The size of the cut hole.
    public typealias CutHoleClosure<CutHole> = (_ targetSize: CGSize) -> CutHole

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
    /// The expected size of the cropped image, in points.
    public var targetSize: CGSize
    /// The expected scale of the cropped image.
    ///
    /// This defines the point to pixel ratio for the output image. Defaults to `1`.
    public var targetScale: CGFloat = 1
    /// Limit movement and scaling to make sure the image fills the target frame.
    ///
    /// Defaults to `true`.
    ///
    /// > Important: This option only works with 90-degree rotations. If the rotation is an angle other than a multiple of 90 degrees, the image will not be guaranteed to fill the target frame.
    public var fulfillTargetFrame: Bool = true
    /// A closure that will be called when the user finishes cropping.
    ///
    /// The error should be a ``CropError``.
    public var onCrop: (Result<PlatformImage, Error>) -> Void
    var controls: ControlClosure<Controls>
    var cutHole: CutHoleClosure<CutHole>
    /// Create a ``CropImageView`` with a custom controls view and a custom cut hole.
    public init(
        image: PlatformImage,
        targetSize: CGSize,
        targetScale: CGFloat = 1,
        fulfillTargetFrame: Bool = true,
        onCrop: @escaping (Result<PlatformImage, Error>) -> Void,
        @ViewBuilder controls: @escaping ControlClosure<Controls>,
        @ViewBuilder cutHole: @escaping CutHoleClosure<CutHole>
    ) {
        self.image = image
        self.targetSize = targetSize
        self.targetScale = targetScale
        self.onCrop = onCrop
        self.controls = controls
        self.cutHole = cutHole
    }
    /// Create a ``CropImageView`` with a custom controls view and default cut hole.
    public init(
        image: PlatformImage,
        targetSize: CGSize,
        targetScale: CGFloat = 1,
        fulfillTargetFrame: Bool = true,
        onCrop: @escaping (Result<PlatformImage, Error>) -> Void,
        @ViewBuilder controls: @escaping ControlClosure<Controls>
    ) where CutHole == DefaultCutHoleView {
        self.image = image
        self.targetSize = targetSize
        self.targetScale = targetScale
        self.onCrop = onCrop
        self.controls = controls
        self.cutHole = { targetSize in
            DefaultCutHoleView(targetSize: targetSize)
        }
    }
    /// Create a ``CropImageView`` with default UI elements.
    public init(
        image: PlatformImage,
        targetSize: CGSize,
        targetScale: CGFloat = 1,
        fulfillTargetFrame: Bool = true,
        onCrop: @escaping (Result<PlatformImage, Error>) -> Void
    ) where Controls == DefaultControlsView, CutHole == DefaultCutHoleView {
        self.image = image
        self.targetSize = targetSize
        self.targetScale = targetScale
        self.onCrop = onCrop
        self.controls = { $offset, $scale, $rotation, crop in
            DefaultControlsView(offset: $offset, scale: $scale, rotation: $rotation, crop: crop)
        }
        self.cutHole = { targetSize in
            DefaultCutHoleView(targetSize: targetSize)
        }
    }

    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1
    @State private var rotation: Angle = .zero

    @State private var viewSize: CGSize = .zero

    @MainActor
    func crop() throws -> PlatformImage {
        let snapshotView = UnderlyingImageView(
            offset: $offset,
            scale: $scale,
            rotation: $rotation,
            image: image,
            viewSize: viewSize,
            targetSize: targetSize,
            fulfillTargetFrame: fulfillTargetFrame
        )
        .frame(width: targetSize.width, height: targetSize.height)
        if #available(iOS 16.0, macOS 13.0, *) {
            let renderer = ImageRenderer(content: snapshotView)
            renderer.scale = targetScale
#if !os(macOS)
            if let image = renderer.uiImage {
                return image
            } else {
                throw CropError.imageRendererReturnedNil
            }
#else
            if let image = renderer.nsImage {
                return image
            } else {
                throw CropError.imageRendererReturnedNil
            }
#endif
        } else {
#if os(macOS)
            fatalError("Cropping is not supported on macOS versions before Ventura 13.0.")
#else
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
            viewSize: viewSize,
            targetSize: targetSize,
            fulfillTargetFrame: fulfillTargetFrame
        )
        .frame(width: viewSize.width, height: viewSize.height)
        .clipped()
    }

    var viewSizeReadingView: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(.white.opacity(0.0001))
                .onChange(of: geo.size) { newValue in
                    viewSize = newValue
                }
                .onAppear {
                    viewSize = geo.size
                }
        }
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
        cutHole(targetSize)
            .background(underlyingImage)
            .background(viewSizeReadingView)
            .overlay(control)
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
                ) {
                    result = $0
                }
                .frame(height: 300)
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
#else
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
            .frame(minHeight: 600)
        #endif
    }
}
