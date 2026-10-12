import SwiftUI
import SwiftData

/// Screen 3: all saved palettes in an adaptive grid, with search.
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedPalette.createdAt, order: .reverse) private var palettes: [SavedPalette]
    @State private var searchText = ""

    // Adaptive: more columns on bigger screens and in landscape.
    private let columns = [GridItem(.adaptive(minimum: 170), spacing: 16)]

    private var filteredPalettes: [SavedPalette] {
        guard !searchText.isEmpty else { return palettes }
        return palettes.filter { palette in
            palette.name.localizedCaseInsensitiveContains(searchText)
            || palette.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if palettes.isEmpty {
                    ContentUnavailableView("No palettes yet",
                                           systemImage: "paintpalette",
                                           description: Text("Capture a photo and save a palette to see it here."))
                } else if filteredPalettes.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredPalettes) { palette in
                                card(for: palette)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Library")
            .navigationDestination(for: SavedPalette.self) { palette in
                PaletteDetailView(palette: palette)
            }
            .searchable(text: $searchText, prompt: "Search by name or tag")
        }
    }

    private func card(for palette: SavedPalette) -> some View {
        NavigationLink(value: palette) {
            VStack(alignment: .leading, spacing: 8) {
                PaletteStrip(hexColors: palette.hexColors, height: 56)
                Text(palette.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(palette.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation { modelContext.delete(palette) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

/// Opens when a palette card is tapped.
struct PaletteDetailView: View {
    let palette: SavedPalette
    @State private var copiedHex: String?

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing) {
                if let data = palette.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                        .accessibilityLabel("Photo for \(palette.name)")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Palette").font(.headline)
                    PaletteStrip(hexColors: palette.hexColors,
                                 height: 80,
                                 showLabels: true,
                                 onCopy: { hex in copyHex(hex, showing: $copiedHex) })
                    Text("Long-press a swatch to copy its hex code.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                if !palette.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags").font(.headline)
                        TagChips(tags: palette.tags)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                }

                Text("Saved \(palette.createdAt.formatted(date: .long, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(palette.name)
        .navigationBarTitleDisplayMode(.inline)
        .copyToast($copiedHex)
    }
}