//
//  SwiftUIView.swift
//
//
//  Created by Shibo Lyu on 2023/8/15.
//

import SwiftUI

struct DefaultCutHoleView: View {
    var targetSize: CGSize
    var showStroke = true

    var background: some View {
        DefaultCutHoleShape(size: targetSize)
            .fill(style: FillStyle(eoFill: true))
            .foregroundColor(.black.opacity(0.6))
    }

    var stroke: some View {
        Rectangle()
            .strokeBorder(style: .init(lineWidth: 1))
            .frame(width: targetSize.width + 2, height: targetSize.height + 2)
            .foregroundColor(.white)
    }

    var body: some View {
        background
            .allowsHitTesting(false)
            .overlay(showStroke ? stroke : nil)
            .animation(.default, value: targetSize)
    }
}

struct DefaultCutHoleView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultCutHoleView(targetSize: .init(width: 100, height: 100))
    }
}
