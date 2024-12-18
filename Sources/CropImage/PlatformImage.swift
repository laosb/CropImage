//
//  PlatformImage.swift
//
//
//  Created by Shibo Lyu on 2023/7/21.
//

import Foundation

#if os(macOS)
import AppKit
/// The image object type, aliased to each platform.
///
/// On macOS, it's `NSImage` and on iOS/visionOS it's `UIImage`.
public typealias PlatformImage = NSImage
extension PlatformImage {
    static let previewImage: PlatformImage = .init(contentsOf: URL(string: "file:///System/Library/Desktop%20Pictures/Hello%20Metallic%20Blue.heic")!)!
}
#else
import UIKit
/// The image object type, aliased to each platform.
///
/// On macOS, it's `NSImage` and on iOS/visionOS it's `UIImage`.
public typealias PlatformImage = UIImage
extension PlatformImage {
    // This doesn't really work, but at least passes build.
    static let previewImage: PlatformImage = .init(contentsOfFile: "/System/Library/Desktop Pictures/Hello Metallic Blue.heic")!
}
#endif
