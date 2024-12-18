//
//  DefaultCutHoleShape.swift
//
//
//  Created by Shibo Lyu on 2023/7/21.
//

import SwiftUI

struct DefaultCutHoleShape: Shape {
    var size: CGSize
    var isCircular = false

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(size.width, size.height) }
        set { size = .init(width: newValue.first, height: newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let path = CGMutablePath()
        path.move(to: rect.origin)
        path.addLine(to: .init(x: rect.maxX, y: rect.minY))
        path.addLine(to: .init(x: rect.maxX, y: rect.maxY))
        path.addLine(to: .init(x: rect.minX, y: rect.maxY))
        path.addLine(to: rect.origin)
        path.closeSubpath()

        let newRect = CGRect(origin: .init(
            x: rect.midX - size.width / 2.0,
            y: rect.midY - size.height / 2.0
        ), size: size)

        path.move(to: newRect.origin)
        if isCircular {
            path.addEllipse(in: newRect)
        } else {
            path.addLine(to: .init(x: newRect.maxX, y: newRect.minY))
            path.addLine(to: .init(x: newRect.maxX, y: newRect.maxY))
            path.addLine(to: .init(x: newRect.minX, y: newRect.maxY))
            path.addLine(to: newRect.origin)
        }
        path.closeSubpath()
        return Path(path)
    }
}

#Preview("Default") {
    VStack {
        DefaultCutHoleShape(size: .init(width: 100, height: 100))
            .fill(style: FillStyle(eoFill: true))
            .foregroundColor(.black.opacity(0.6))
    }
}

#Preview("Circular") {
    VStack {
        DefaultCutHoleShape(size: .init(width: 100, height: 100), isCircular: true)
            .fill(style: FillStyle(eoFill: true))
            .foregroundColor(.black.opacity(0.6))
    }
}
