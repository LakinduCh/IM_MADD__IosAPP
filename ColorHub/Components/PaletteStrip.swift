import SwiftUI

/// Custom component: a horizontal strip of colour swatches.
/// - animated: swatches pop in one after another
/// - showLabels: shows the hex code under each swatch
/// - onCopy: called when a swatch is long-pressed
struct PaletteStrip: View {
    let hexColors: [String]
    var height: CGFloat = 72
    var animated = false
    var showLabels = false
    var onCopy: ((String) -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(Array(hexColors.enumerated()), id: \.offset) { index, hex in
                    Swatch(hex: hex, index: index, animated: animated)
                        .onLongPressGesture { onCopy?(hex) }
                        .accessibilityElement()
                        .accessibilityLabel("Colour \(hex)")
                        .accessibilityHint(onCopy == nil ? "" : "Long press to copy the hex code")
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if showLabels {
                HStack(spacing: 0) {
                    ForEach(Array(hexColors.enumerated()), id: \.offset) { _, hex in
                        Text(hex)
                            .font(.caption2.monospaced())   // scales with Dynamic Type
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

/// One colour block that animates in when it first appears.
private struct Swatch: View {
    let hex: String
    let index: Int
    let animated: Bool
    @State private var appeared = false

    var body: some View {
        Color(hex: hex)
            .frame(maxWidth: .infinity)
            .scaleEffect(y: (appeared || !animated) ? 1 : 0.2, anchor: .bottom)
            .opacity((appeared || !animated) ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1)) {
                    appeared = true
                }
            }
    }
}

/// A scrolling row of tag "chips" (the Vision labels).
struct TagChips: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag.capitalized)
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.accent.opacity(0.15), in: Capsule())
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }
}