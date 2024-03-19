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
/// On macOS, it's `NSImage` and on iOS it's `UIImage`.
public typealias PlatformImage = NSImage
#else
import UIKit
/// The image object type, aliased to each platform.
///
/// On macOS, it's `NSImage` and on iOS it's `UIImage`.
public typealias PlatformImage = UIImage
#endif
