//
//  PlatformImage.swift
//
//
//  Created by Shibo Lyu on 2023/7/21.
//

import Foundation

#if os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#elseif os(iOS)
import UIKit
public typealias PlatformImage = UIImage
#endif
