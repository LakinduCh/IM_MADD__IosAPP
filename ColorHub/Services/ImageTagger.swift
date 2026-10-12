import Vision
import UIKit

/// Uses Apple's Vision framework to describe what is in a photo (e.g. "sunset", "plant").
enum ImageTagger {

    /// Returns up to `limit` labels. Returns an empty list if Vision can't run,
    /// so the rest of the app keeps working.
    static func tags(for image: UIImage, limit: Int = 5, minimumConfidence: Float = 0.2) async -> [String] {
        let upright = image.normalized(maxSide: 1024)
        guard let cgImage = upright.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            // Run on a background queue so the UI stays smooth.
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNClassifyImageRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    let labels = (request.results ?? [])
                        .filter { $0.confidence >= minimumConfidence }
                        .sorted { $0.confidence > $1.confidence }
                        .prefix(limit)
                        .map { $0.identifier.replacingOccurrences(of: "_", with: " ") }
                    continuation.resume(returning: Array(labels))
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }
}