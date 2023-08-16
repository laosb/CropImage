# ``CropImage``

A simple SwiftUI view where user can move and resize an image to a pre-defined size.

Supports iOS 14.0 and above, or macOS Ventura 13.0 and above.

- Supports both iOS and macOS
- Use `ImageRenderer` to render the cropped image, when possible
- Very lightweight
- (Optionally) bring your own crop UI

Configure and present ``CropImageView`` to the user, optionally specifying a ``CropImageView/ControlClosure`` to use your own UI controls to transform the image in the canvas, and cancel or finish the crop process, and receive cropped image from ``CropImageView/onCrop``.

![Preview on macOS](macos)

## Topics

### Views

- ``CropImageView``

### Supporting Types

- ``PlatformImage``
