import SwiftUI
import PhotosUI

/// Wraps the chosen photo so it can be used as a navigation value.
struct PickedPhoto: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage

    static func == (lhs: PickedPhoto, rhs: PickedPhoto) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Screen 1: choose a photo and optionally tap it to pick one colour.
struct CaptureView: View {
    @State private var pickerItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var pickedColor: UIColor?
    @State private var selectedPhoto: PickedPhoto?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacing) {
                    if let image {
                        photoCard(for: image)
                        eyedropperCard
                        extractButton(for: image)
                    } else {
                        emptyState
                    }
                    pickerButton
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Capture")
            .overlay { if isLoading { ProgressView() } }
            .navigationDestination(item: $selectedPhoto) { photo in
                ResultView(image: photo.image, pickedHex: pickedColor?.hexString)
            }
            .onChange(of: pickerItem) { _, newItem in loadImage(from: newItem) }
            .alert("Couldn't load photo",
                   isPresented: Binding(get: { errorMessage != nil },
                                        set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Pieces of the screen

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "paintpalette")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent)
                .accessibilityHidden(true)
            Text("Turn any photo into a palette")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("Pick a photo and ColorHub will find its main colours and tell you what's in the picture.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private func photoCard(for image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(image.size, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay {
                // Tap anywhere on the photo to pick that exact colour.
                GeometryReader { proxy in
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture().onEnded { value in
                                let x = value.location.x / proxy.size.width
                                let y = value.location.y / proxy.size.height
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    pickedColor = ColorExtractor.color(atX: x, y: y, in: image)
                                }
                            }
                        )
                }
            }
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
            .accessibilityLabel("Selected photo. Tap to pick a colour.")
    }

    private var eyedropperCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(pickedColor.map { Color(uiColor: $0) } ?? Color.secondary.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                Text(pickedColor?.hexString ?? "No colour picked")
                    .font(.headline.monospaced())
                Text("Tap the photo to pick a colour. It will be added to your palette.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    private func extractButton(for image: UIImage) -> some View {
        Button {
            selectedPhoto = PickedPhoto(image: image)
        } label: {
            Label("Extract palette", systemImage: "wand.and.stars")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(AppTheme.accent)
    }

    private var pickerButton: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            Label(image == nil ? "Choose a photo" : "Choose a different photo",
                  systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(AppTheme.accent)
    }

    // MARK: - Loading

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        isLoading = true
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    image = uiImage.normalized()
                    pickedColor = nil
                } else {
                    errorMessage = "That photo couldn't be read. Please try another one."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}