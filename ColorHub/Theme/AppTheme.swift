import SwiftUI
import UIKit

/// Central place for the app's colours and spacing, so the look stays consistent.
enum AppTheme {
    static let accent = Color(hex: "#6C4DF6")
    static let background = Color(light: 0xF5F3FA, dark: 0x13111A)   // adapts to Dark Mode
    static let card = Color(light: 0xFFFFFF, dark: 0x201D2C)

    static let cornerRadius: CGFloat = 20
    static let padding: CGFloat = 16
    static let spacing: CGFloat = 20
}

extension Color {
    /// Creates a colour from a hex string such as "#FF8800".
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        _ = Scanner(string: cleaned).scanHexInt64(&value)
        self.init(.sRGB,
                  red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255,
                  opacity: 1)
    }

    /// Creates a colour that automatically switches between light and dark mode.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hexValue: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hexValue: UInt32) {
        self.init(red: CGFloat((hexValue >> 16) & 0xFF) / 255,
                  green: CGFloat((hexValue >> 8) & 0xFF) / 255,
                  blue: CGFloat(hexValue & 0xFF) / 255,
                  alpha: 1)
    }

    /// The colour as a hex string like "#FF8800".
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
    }
}