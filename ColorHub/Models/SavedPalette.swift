import Foundation
import SwiftData

/// A palette saved by the user. Stored on-device with SwiftData.
@Model
final class SavedPalette {
    var id: UUID
    var name: String
    var hexColors: [String]          // e.g. ["#FF8800", "#112233"]
    var tags: [String]               // labels from the Vision framework
    var createdAt: Date
    @Attribute(.externalStorage) var imageData: Data?   // small JPEG of the source photo

    init(name: String, hexColors: [String], tags: [String], imageData: Data?, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.hexColors = hexColors
        self.tags = tags
        self.imageData = imageData
        self.createdAt = createdAt
    }
}