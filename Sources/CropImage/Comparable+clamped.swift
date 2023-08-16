//
//  Comparable+clamped.swift
//  
//
//  Created by Shibo Lyu on 2023/8/16.
//

import Foundation

// https://stackoverflow.com/a/40868784
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
