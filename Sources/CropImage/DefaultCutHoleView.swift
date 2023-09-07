//
//  SwiftUIView.swift
//
//
//  Created by Shibo Lyu on 2023/8/15.
//

import SwiftUI

/// The default cut hole view. Stroke and mask color can be adjusted.
public struct DefaultCutHoleView: View {
    var targetSize: CGSize
    var strokeWidth: CGFloat
    var maskColor: Color
    var isCircular: Bool

    /// Initialize a default rectangular or circular cut hole view with specified target size, stroke width and mask color.
    public init(
        targetSize: CGSize,
        isCircular: Bool = false,
        strokeWidth: CGFloat = 1,
        maskColor: Color = .black.opacity(0.6)
    ) {
        self.targetSize = targetSize
        self.strokeWidth = strokeWidth
        self.maskColor = maskColor
        self.isCircular = isCircular
    }

    var background: some View {
        DefaultCutHoleShape(size: targetSize, isCircular: isCircular)
            .fill(style: FillStyle(eoFill: true))
            .foregroundColor(maskColor)
    }

    @ViewBuilder
    var strokeShape: some View {
        if isCircular {
            Circle()
                .strokeBorder(style: .init(lineWidth: strokeWidth))
        } else {
            Rectangle()
                .strokeBorder(style: .init(lineWidth: strokeWidth))
        }
    }

    var stroke: some View {
        strokeShape
            .frame(
                width: targetSize.width + strokeWidth * 2,
                height: targetSize.height + strokeWidth * 2
            )
            .foregroundColor(.white)
    }

    public var body: some View {
        background
            .allowsHitTesting(false)
            .overlay(strokeWidth > 0 ? stroke : nil)
            .animation(.default, value: targetSize)
    }
}

struct DefaultCutHoleView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultCutHoleView(targetSize: .init(width: 100, height: 100))
            .previewDisplayName("Default")
        DefaultCutHoleView(targetSize: .init(width: 100, height: 100), isCircular: true)
            .previewDisplayName("Circular")
    }
}
