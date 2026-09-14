//
//  TripSegmentsView.swift
//  Trips
//

import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

struct TripSegmentsView: View {
    let tripDetailsId: String
    let storageManager: StorageManager
    @State var segment: TripSegment
    let onSaved: (TripSegment) -> Void

    // MARK: - Header edit state
    @State private var isHeaderEditing: Bool
    @State private var editName: String
    @FocusState private var isNameFocused: Bool

    // MARK: - Section edit state
    @State private var editingMarkdownIndex: Int?
    @State private var markdownTextBeforeEditing: String?
    @FocusState private var isMarkdownEditorFocused: Bool

    // MARK: - Media Picker
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var activeMediaSectionIndex: Int?

    init(tripDetailsId: String, storageManager: StorageManager, segment: TripSegment, onSaved: @escaping (TripSegment) -> Void) {
        self.tripDetailsId = tripDetailsId
        self.storageManager = storageManager
        self._segment = State(initialValue: segment)
        self.onSaved = onSaved
        self._editName = State(initialValue: segment.name)
        self._isHeaderEditing = State(initialValue: segment.name.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    var body: some View {
        ZStack {
            Color(hue: 0.58, saturation: 0.06, brightness: 0.09)
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            segmentHeaderSection
                                .padding(.horizontal, 16)
                                .padding(.top, 16)

                            sectionsList
                        }
                        .padding(.bottom, 100)
                    }
                    .onChange(of: editingMarkdownIndex) { _, index in
                        guard let index else { return }
                        // Wait for the inline editor to enter the view hierarchy before
                        // moving it above the keyboard.
                        DispatchQueue.main.async {
                            withAnimation {
                                proxy.scrollTo(markdownSectionAnchor(index), anchor: .top)
                            }
                            isMarkdownEditorFocused = true
                        }
                    }
                }
            }

            // Fixed bottom buttons
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    addSectionButton(label: "Add Text", icon: "text.alignleft") {
                        addNewMarkdownSection()
                    }
                    addSectionButton(label: "Add Media", icon: "photo.on.rectangle") {
                        addNewMediaSection()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [.clear, Color(hue: 0.58, saturation: 0.06, brightness: 0.09)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .ignoresSafeArea()
                )
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(editingMarkdownIndex != nil)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if editingMarkdownIndex != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelMarkdownEditing()
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveMarkdownAndFinishEditing()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                }
            }
        }
        .onChange(of: selectedPhotos) { _, items in
            if let index = activeMediaSectionIndex {
                handlePickedMedia(items, for: index)
            }
        }
        .onAppear {
            if isHeaderEditing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isNameFocused = true
                }
            }
        }
    }

    // MARK: - Header

    private var segmentHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if isHeaderEditing {
                    TextField("Segment Name", text: $editName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .focused($isNameFocused)
                } else {
                    Text(segment.name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled Segment" : segment.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button {
                    if isHeaderEditing {
                        segment.name = editName
                        isNameFocused = false
                        onSaved(segment)
                    } else {
                        isNameFocused = true
                    }
                    isHeaderEditing.toggle()
                } label: {
                    Image(systemName: isHeaderEditing ? "checkmark.circle.fill" : "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            
            if let date = segment.date {
                Text(date)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Sections List

    private var sectionsList: some View {
        VStack(spacing: 24) {
            ForEach(Array(segment.sections.enumerated()), id: \.offset) { index, section in
                switch section {
                case .markdown(let markdownSection):
                    markdownSectionView(markdownSection, index: index)
                case .media(let mediaSection):
                    mediaSectionView(mediaSection, index: index)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func markdownSectionView(_ section: MarkdownSection, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if editingMarkdownIndex == index {
                TextEditor(text: markdownBinding(for: index))
                    .font(.body)
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .focused($isMarkdownEditorFocused)
                    .frame(minHeight: 180, alignment: .topLeading)
                    .padding(16)
            } else {
                HStack {
                    Spacer()
                    Button {
                        beginMarkdownEditing(at: index)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(6)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding([.top, .trailing], 8)

                Text(section.markdown)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding([.horizontal, .bottom], 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .id(markdownSectionAnchor(index))
    }

    private func mediaSectionView(_ section: MediaSection, index: Int) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                PhotosPicker(
                    selection: mediaSelectionBinding(for: index),
                    maxSelectionCount: 20,
                    matching: .any(of: [.images, .videos]),
                    preferredItemEncoding: .current
                ) {
                    mediaAddTile
                }

                ForEach(section.media) { item in
                    MediaThumbnail(item: item)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var mediaTileSize: CGFloat {
        (UIScreen.main.bounds.width - 32 - 36) / 3.5
    }

    private var mediaAddTile: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
            .frame(width: mediaTileSize, height: mediaTileSize)
            .overlay(
                Image(systemName: "plus")
                    .foregroundStyle(.white.opacity(0.4))
            )
    }

    private func mediaSelectionBinding(for index: Int) -> Binding<[PhotosPickerItem]> {
        Binding(
            get: { selectedPhotos },
            set: { items in
                activeMediaSectionIndex = index
                selectedPhotos = items
            }
        )
    }

    // MARK: - Bottom Buttons

    private func addSectionButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Actions

    private func addNewMarkdownSection() {
        let newSection = MarkdownSection(markdown: "")
        segment.sections.append(.markdown(newSection))
        beginMarkdownEditing(at: segment.sections.count - 1)
    }

    private func markdownBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard segment.sections.indices.contains(index), case .markdown(let section) = segment.sections[index] else {
                    return ""
                }
                return section.markdown
            },
            set: { newValue in
                guard segment.sections.indices.contains(index), case .markdown(var section) = segment.sections[index] else {
                    return
                }
                section.markdown = newValue
                segment.sections[index] = .markdown(section)
            }
        )
    }

    private func beginMarkdownEditing(at index: Int) {
        markdownTextBeforeEditing = markdownBinding(for: index).wrappedValue
        editingMarkdownIndex = index
    }

    private func saveMarkdownAndFinishEditing() {
        onSaved(segment)
        isMarkdownEditorFocused = false
        editingMarkdownIndex = nil
        markdownTextBeforeEditing = nil
    }

    private func cancelMarkdownEditing() {
        guard let index = editingMarkdownIndex, let originalText = markdownTextBeforeEditing else {
            return
        }
        markdownBinding(for: index).wrappedValue = originalText
        isMarkdownEditorFocused = false
        editingMarkdownIndex = nil
        markdownTextBeforeEditing = nil
    }

    private func markdownSectionAnchor(_ index: Int) -> String {
        "markdown-section-\(index)"
    }

    private func addNewMediaSection() {
        let newSection = MediaSection(media: [])
        segment.sections.append(.media(newSection))
        onSaved(segment)
    }

    private func handlePickedMedia(_ items: [PhotosPickerItem], for index: Int) {
        guard !items.isEmpty else { return }

        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                    let contentType = item.supportedContentTypes.first
                    let isVideo = contentType?.conforms(to: .movie) == true
                    let fileExtension = contentType?.preferredFilenameExtension ?? (isVideo ? "mov" : "jpg")
                    let mediaType = isVideo ? "video" : "image"
                    let filename = "media_\(timestamp)_\(UUID().uuidString.prefix(4)).\(fileExtension)"
                    let path = "data/trips/\(tripDetailsId)/media/\(filename)"

                    do {
                        let url = try await uploadMediaData(
                            data,
                            path: path,
                            contentType: contentType?.preferredMIMEType
                        )
                        await MainActor.run {
                            guard segment.sections.indices.contains(index), case .media(var section) = segment.sections[index] else {
                                return
                            }
                            section.media.append(MediaItem(url: url.absoluteString, caption: "", type: mediaType))
                            segment.sections[index] = .media(section)
                        }
                    } catch {
                        print("Failed to upload media: \(error)")
                    }
                }
            }

            await MainActor.run {
                onSaved(segment)
                selectedPhotos = []
                activeMediaSectionIndex = nil
            }
        }
    }

    private func uploadMediaData(_ data: Data, path: String, contentType: String?) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            storageManager.upload(data: data, path: path, contentType: contentType) { result in
                continuation.resume(with: result)
            }
        }
    }

}

private struct MediaThumbnail: View {
    let item: MediaItem

    private let size = (UIScreen.main.bounds.width - 32 - 36) / 3.5

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if item.type == "video" {
                VideoThumbnail(url: URL(string: item.url))
            } else {
                AsyncImage(url: URL(string: item.url)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle().fill(Color.white.opacity(0.1))
                    }
                }
            }

            if item.type == "video" {
                Image(systemName: "play.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding(6)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct VideoThumbnail: View {
    let url: URL?
    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .overlay(ProgressView().tint(.white))
            }
        }
        .task(id: url) {
            guard let url else { return }
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            thumbnail = try? UIImage(cgImage: generator.copyCGImage(at: .zero, actualTime: nil))
        }
    }
}
