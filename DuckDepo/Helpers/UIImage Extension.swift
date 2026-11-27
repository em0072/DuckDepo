//
//  UIImage Extension.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 28/10/2021.
//

import UIKit

extension UIImage {

    /// Ready to store as a JPEG: scaled down to `DocumentPhoto.storedScale` (never up), and on white
    /// where it's transparent, which JPEG would turn black.
    func preparedForStorage() -> UIImage {
        let pixels = CGSize(width: size.width * scale, height: size.height * scale)
        let factor = DocumentPhoto.storedScale(for: pixels)
        let target = CGSize(width: max(1, (pixels.width * factor).rounded()),
                            height: max(1, (pixels.height * factor).rounded()))
        guard target != pixels.rounded || hasTransparency else { return self }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        // 8 bits per channel: a wide-colour canvas takes twice the memory, and the JPEG doesn't keep it.
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: target, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: target))
            draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private var hasTransparency: Bool {
        switch cgImage?.alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly: true
        default: false
        }
    }
}

private extension CGSize {
    var rounded: CGSize {
        CGSize(width: width.rounded(), height: height.rounded())
    }
}
