import SwiftUI
import UIKit

/// Custom modifier: puts content on a rounded, shadowed card.
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.padding)
            .background(AppTheme.card,
                        in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}

/// Custom modifier: shows a small "Copied #HEX" message at the bottom of the screen.
struct CopyToast: ViewModifier {
    @Binding var copiedHex: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let hex = copiedHex {
                    Text("Copied \(hex)")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sensoryFeedback(.selection, trigger: copiedHex)
    }
}

extension View {
    func copyToast(_ copiedHex: Binding<String?>) -> some View {
        modifier(CopyToast(copiedHex: copiedHex))
    }
}

/// Copies a hex code to the clipboard and shows the toast for 1.5 seconds.
@MainActor
func copyHex(_ hex: String, showing copiedHex: Binding<String?>) {
    UIPasteboard.general.string = hex
    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
        copiedHex.wrappedValue = hex
    }
    Task {
        try? await Task.sleep(for: .seconds(1.5))
        withAnimation { copiedHex.wrappedValue = nil }
    }
}