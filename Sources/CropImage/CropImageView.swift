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

public struct CropImageView: View {
    public enum RenderError: Error {
        case imageRendererReturnedNil
    }

    var image: PlatformImage
    var targetSize: CGSize
    var targetScale: CGFloat = 1
    var onCrop: (Result<PlatformImage, Error>) -> Void

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
                throw RenderError.imageRendererReturnedNil
            }
#elseif os(macOS)
            if let image = renderer.nsImage {
                return image
            } else {
                throw RenderError.imageRendererReturnedNil
            }
#endif
        } else {
#if os(macOS)
            fatalError("Cropping is not supported on macOS versions before Ventrura 13.0.")
#elseif os(iOS)
            let window = UIWindow(frame: CGRect(origin: .zero, size: targetSize))
            let hosting = UIHostingController(rootView: snapshotView)
            hosting.view.frame = window.frame
            window.addSubview(hosting.view)
            window.makeKeyAndVisible()
            UIGraphicsBeginImageContextWithOptions(hosting.view.bounds.size, false, targetScale)
            let context = UIGraphicsGetCurrentContext()!
            hosting.view.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()!
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
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button { Task {
                        do {
                            onCrop(.success(try crop()))
                        } catch {
                            onCrop(.failure(error))
                        }
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
