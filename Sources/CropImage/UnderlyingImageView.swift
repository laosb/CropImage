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
    var viewSize: CGSize
    var targetSize: CGSize
    var fulfillTargetFrame: Bool

    @State private var tempOffset: CGSize = .zero
    @State private var tempScale: CGFloat = 1
    @State private var tempRotation: Angle = .zero
    @State private var scrolling: Bool = false
#if os(macOS)
    @State private var hovering: Bool = false
    @State private var scrollMonitor: Any?
#endif

    // When rotated odd multiples of 90 degrees, we need to switch width and height of the image in calculations.
    var isRotatedOddMultiplesOf90Deg: Bool {
        rotation != .zero
        && rotation.degrees.truncatingRemainder(dividingBy: 90) == 0
        && rotation.degrees.truncatingRemainder(dividingBy: 180) != 0
    }

    var imageWidth: CGFloat {
        isRotatedOddMultiplesOf90Deg ? image.size.height : image.size.width
    }
    var imageHeight: CGFloat {
        isRotatedOddMultiplesOf90Deg ? image.size.width : image.size.height
    }

    var minimumScale: CGFloat {
        let widthScale = targetSize.width / imageWidth
        let heightScale = targetSize.height / imageHeight
        return max(widthScale, heightScale)
    }

    func xOffsetBounds(at scale: CGFloat) -> ClosedRange<CGFloat> {
        let width = imageWidth * scale
        let range = (targetSize.width - width) / 2
        return range > 0 ? -range ... range : range ... -range
    }
    func yOffsetBounds(at scale: CGFloat) -> ClosedRange<CGFloat> {
        let height = imageHeight * scale
        let range = (targetSize.height - height) / 2
        return range > 0 ? -range ... range : range ... -range
    }

    func adjustToFulfillTargetFrame() {
        guard fulfillTargetFrame else { return }

        let clampedScale = max(minimumScale, scale)
        var clampedOffset = offset
        clampedOffset.width = clampedOffset.width.clamped(to: xOffsetBounds(at: clampedScale))
        clampedOffset.height = clampedOffset.height.clamped(to: yOffsetBounds(at: clampedScale))

        if clampedScale != scale || clampedOffset != offset {
            if scrolling {
                scale = clampedScale
                offset = clampedOffset
                scrolling = false
            } else {
                withAnimation(.interactiveSpring()) {
                    scale = clampedScale
                    offset = clampedOffset
                }
            }
        }
    }

    func setInitialScale(basedOn viewSize: CGSize) {
        guard viewSize != .zero else { return }
        let widthScale = viewSize.width / imageWidth
        let heightScale = viewSize.height / imageHeight
        print("setInitialScale: widthScale: \(widthScale), heightScale: \(heightScale)")
        scale = min(widthScale, heightScale)
    }

#if os(macOS)
    private func setupScrollMonitor() {
      scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            if hovering {
                scrolling = true
                scale = scale + event.scrollingDeltaY / 1000
            }
            return event
        }
    }
  
    private func removeScrollMonitor() {
        if let scrollMonitor {
            NSEvent.removeMonitor(scrollMonitor)
        }
    }
#endif

    var imageView: Image {
#if os(macOS)
        Image(nsImage: image)
#else
        Image(uiImage: image)
#endif
    }

    var interactionView: some View {
        Color.white.opacity(0.0001)
            .gesture(dragGesture)
            .gesture(magnificationgesture)
            .gesture(rotationGesture)
#if os(macOS)
            .onAppear {
                setupScrollMonitor()
            }
            .onDisappear {
                removeScrollMonitor()
            }
#endif
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                tempOffset = value.translation
            }
            .onEnded { value in
                offset = offset + tempOffset
                tempOffset = .zero
            }
    }

    var magnificationgesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                tempScale = value
            }
            .onEnded { value in
                scale = scale * tempScale
                tempScale = 1
            }
    }

    var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                tempRotation = value
            }
            .onEnded { value in
                rotation = rotation + tempRotation
                tempRotation = .zero
            }
    }

    var body: some View {
        imageView
            .rotationEffect(rotation + tempRotation)
            .scaleEffect(scale * tempScale)
            .offset(offset + tempOffset)
            .overlay(interactionView)
            .clipped()
            .onChange(of: viewSize) { newValue in
                setInitialScale(basedOn: newValue)
            }
            .onChange(of: scale) { _ in
                adjustToFulfillTargetFrame()
            }
            .onChange(of: offset) { _ in
                adjustToFulfillTargetFrame()
            }
            .onChange(of: rotation) { _ in
                adjustToFulfillTargetFrame()
            }
#if os(macOS)
            .onHover { hovering = $0 }
#endif
    }
}

#Preview {
    struct PreviewView: View {
        @State private var offset: CGSize = .zero
        @State private var scale: CGFloat = 1
        @State private var rotation: Angle = .zero
        
        var body: some View {
            UnderlyingImageView(
                offset: $offset,
                scale: $scale,
                rotation: $rotation,
                image: .init(contentsOf: URL(string: "file:///System/Library/Desktop%20Pictures/Hello%20Metallic%20Blue.heic")!)!,
                viewSize: .init(width: 200, height: 100),
                targetSize: .init(width: 100, height: 100),
                fulfillTargetFrame: true
            )
            .frame(width: 200, height: 100)
        }
    }
    
    return PreviewView()
}
