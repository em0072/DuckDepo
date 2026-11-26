//
//  UIImage Extension.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 28/10/2021.
//

import UIKit

extension UIImage {

    /// Returns the image scaled so its longest side is at most `maxPixelSize` pixels (never scaled up).
    func scaledDown(toMaxPixelSize maxPixelSize: CGFloat) -> UIImage {
        let pixelWidth = size.width * scale
        let pixelHeight = size.height * scale
        let longestSide = max(pixelWidth, pixelHeight)
        guard longestSide > maxPixelSize, longestSide > 0 else { return self }

        let factor = maxPixelSize / longestSide
        let target = CGSize(width: (pixelWidth * factor).rounded(), height: (pixelHeight * factor).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
