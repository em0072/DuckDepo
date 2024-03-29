//
//  UIImage Extension.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 28/10/2021.
//

import UIKit

extension UIImage {
    func resized(withPercentage percentage: CGFloat, isOpaque: Bool = true) -> UIImage? {
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        let format = imageRendererFormat
        format.opaque = isOpaque
        return UIGraphicsImageRenderer(size: canvas, format: format).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
    
    func resized(toWidth width: CGFloat, isOpaque: Bool = true) -> UIImage? {
        let canvas = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        let format = imageRendererFormat
        format.opaque = isOpaque
        return UIGraphicsImageRenderer(size: canvas, format: format).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
    
    
        func resized(to height: CGFloat) -> UIImage {
            let scale = height / self.size.height
            let newWidth = self.size.width * scale
            let newSize = CGSize(width: newWidth, height: height)
            let renderer = UIGraphicsImageRenderer(size: newSize)

            return renderer.image { _ in
                self.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }

}
