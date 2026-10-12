import UIKit

/// Finds the main colours in a photo using k-means clustering (written for this app).
enum ColorExtractor {

    /// Returns the `count` most dominant colours, biggest group first.
    static func dominantColors(from image: UIImage, count: Int = 5) -> [UIColor] {
        let side = 48                                  // shrink the photo so it's fast
        guard let bytes = rgbaBytes(from: image, side: side) else { return [] }

        var pixels: [SIMD3<Double>] = []
        pixels.reserveCapacity(side * side)
        for i in stride(from: 0, to: bytes.count, by: 4) where bytes[i + 3] > 127 {
            pixels.append(SIMD3<Double>(Double(bytes[i]), Double(bytes[i + 1]), Double(bytes[i + 2])))
        }
        guard !pixels.isEmpty else { return [] }

        return cluster(pixels, into: count).map {
            UIColor(red: CGFloat($0.x / 255), green: CGFloat($0.y / 255), blue: CGFloat($0.z / 255), alpha: 1)
        }
    }

    /// The colour at a point on the photo. x and y are between 0 and 1 (fractions of width/height).
    static func color(atX x: CGFloat, y: CGFloat, in image: UIImage) -> UIColor? {
        let side = 200
        guard let bytes = rgbaBytes(from: image, side: side) else { return nil }
        let px = min(max(Int(x * CGFloat(side)), 0), side - 1)
        let py = min(max(Int(y * CGFloat(side)), 0), side - 1)
        let i = (py * side + px) * 4
        guard bytes[i + 3] > 0 else { return nil }
        return UIColor(red: CGFloat(bytes[i]) / 255,
                       green: CGFloat(bytes[i + 1]) / 255,
                       blue: CGFloat(bytes[i + 2]) / 255,
                       alpha: 1)
    }

    // MARK: - Private helpers

    /// Draws the image into a small square and returns its raw RGBA bytes.
    private static func rgbaBytes(from image: UIImage, side: Int) -> [UInt8]? {
        let size = CGSize(width: side, height: side)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let cgImage = resized.cgImage else { return nil }

        let bytesPerRow = side * 4
        guard let context = CGContext(data: nil,
                                      width: side,
                                      height: side,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let raw = context.data else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
        let buffer = raw.bindMemory(to: UInt8.self, capacity: side * bytesPerRow)
        return Array(UnsafeBufferPointer(start: buffer, count: side * bytesPerRow))
    }

    /// K-means: groups similar colours and returns the group centres, biggest group first.
    private static func cluster(_ pixels: [SIMD3<Double>], into requested: Int) -> [SIMD3<Double>] {
        let k = max(1, min(requested, pixels.count))

        // Start the centres evenly spread from dark to bright, so results are repeatable.
        let byBrightness = pixels.sorted { $0.sum() < $1.sum() }
        var centroids = (0..<k).map { byBrightness[$0 * (byBrightness.count - 1) / max(k - 1, 1)] }
        var counts = [Int](repeating: 0, count: k)

        for _ in 0..<12 {
            var sums = [SIMD3<Double>](repeating: .zero, count: k)
            counts = [Int](repeating: 0, count: k)

            for pixel in pixels {
                var nearest = 0
                var nearestDistance = Double.greatestFiniteMagnitude
                for (index, centroid) in centroids.enumerated() {
                    let diff = pixel - centroid
                    let distance = (diff * diff).sum()
                    if distance < nearestDistance {
                        nearestDistance = distance
                        nearest = index
                    }
                }
                sums[nearest] += pixel
                counts[nearest] += 1
            }

            for index in 0..<k where counts[index] > 0 {
                centroids[index] = sums[index] / Double(counts[index])
            }
        }

        return zip(centroids, counts).sorted { $0.1 > $1.1 }.map { $0.0 }
    }
}

extension UIImage {
    /// Returns an upright copy no bigger than `maxSide` (keeps memory use and load times low).
    func normalized(maxSide: CGFloat = 1024) -> UIImage {
        let longest = max(size.width, size.height)
        let scale = longest > maxSide ? maxSide / longest : 1
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}