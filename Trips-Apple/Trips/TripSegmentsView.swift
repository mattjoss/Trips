//
//  TripSegmentsView.swift
//  Trips
//

import SwiftUI
import PhotosUI
import AVFoundation
import AVKit
import UIKit
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
    @State private var mediaBrowserSelection: MediaBrowserSelection?
    @State private var pendingMediaDeletion: MediaDeletionRequest?

    init(tripDetailsId: String, storageManager: StorageManager, segment: TripSegment, onSaved: @escaping (TripSegment) -> Void) {
        self.tripDetailsId = tripDetailsId
        self.storageManager = storageManager
        self._segment = State(initialValue: segment)
        self.onSaved = onSaved
        self._editName = State(initialValue: segment.name)
        self._isHeaderEditing = State(initialValue: segment.name.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    var body: some View {
        screenContent
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(editingMarkdownIndex != nil)
            .toolbar(mediaBrowserSelection == nil ? .visible : .hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { markdownEditorToolbar }
            .onChange(of: selectedPhotos) { _, items in
                if let index = activeMediaSectionIndex {
                    handlePickedMedia(items, for: index)
                }
            }
            .onAppear { focusSegmentNameIfNeeded() }
            .alert("Delete Media?", isPresented: isPresentingMediaDeletion) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let deletion = pendingMediaDeletion {
                        deleteMediaItem(deletion.itemID, from: deletion.sectionIndex)
                    }
                }
            } message: {
                Text("Remove this item from the trip segment?")
            }
    }

    private var screenContent: some View {
        ZStack {
            Color(hue: 0.58, saturation: 0.06, brightness: 0.09)
                .ignoresSafeArea()

            segmentScrollContent
            bottomActionBar
            mediaBrowserOverlay
        }
    }

    private var segmentScrollContent: some View {
        ScrollViewReader { proxy in
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
                DispatchQueue.main.async {
                    withAnimation {
                        proxy.scrollTo(markdownSectionAnchor(index), anchor: .top)
                    }
                    isMarkdownEditorFocused = true
                }
            }
        }
    }

    private var bottomActionBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 16) {
                addSectionButton(label: "Add Text", icon: "text.alignleft", action: addNewMarkdownSection)
                addSectionButton(label: "Add Media", icon: "photo.on.rectangle", action: addNewMediaSection)
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

    @ViewBuilder
    private var mediaBrowserOverlay: some View {
        if let selection = mediaBrowserSelection {
            MediaBrowserView(
                media: mediaItems(in: selection.sectionIndex),
                selectedItemID: selection.itemID,
                onBack: dismissMediaBrowser,
                onCaptionSaved: { itemID, caption in
                    updateCaption(caption, for: itemID, in: selection.sectionIndex)
                }
            )
            .zIndex(1)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    @ToolbarContentBuilder
    private var markdownEditorToolbar: some ToolbarContent {
        if editingMarkdownIndex != nil {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel", action: cancelMarkdownEditing)
                    .foregroundStyle(.white.opacity(0.7))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done", action: saveMarkdownAndFinishEditing)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    private func focusSegmentNameIfNeeded() {
        guard isHeaderEditing else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isNameFocused = true
        }
    }

    private func dismissMediaBrowser() {
        withAnimation(.spring(duration: 0.35)) {
            mediaBrowserSelection = nil
        }
    }

    private var isPresentingMediaDeletion: Binding<Bool> {
        Binding(
            get: { pendingMediaDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    pendingMediaDeletion = nil
                }
            }
        )
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
                    Button {
                        withAnimation(.spring(duration: 0.35)) {
                            mediaBrowserSelection = MediaBrowserSelection(sectionIndex: index, itemID: item.id)
                        }
                    } label: {
                        MediaThumbnail(item: item)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.type == "video" ? "Open video" : "Open image")
                    .contextMenu {
                        Button(role: .destructive) {
                            pendingMediaDeletion = MediaDeletionRequest(sectionIndex: index, itemID: item.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
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

    private func mediaItems(in sectionIndex: Int) -> [MediaItem] {
        guard segment.sections.indices.contains(sectionIndex), case .media(let section) = segment.sections[sectionIndex] else {
            return []
        }
        return section.media
    }

    private func updateCaption(_ caption: String, for itemID: String, in sectionIndex: Int) {
        guard segment.sections.indices.contains(sectionIndex), case .media(var section) = segment.sections[sectionIndex],
              let itemIndex = section.media.firstIndex(where: { $0.id == itemID }) else {
            return
        }

        section.media[itemIndex].caption = caption
        segment.sections[sectionIndex] = .media(section)
        onSaved(segment)
    }

    private func deleteMediaItem(_ itemID: String, from sectionIndex: Int) {
        guard segment.sections.indices.contains(sectionIndex), case .media(var section) = segment.sections[sectionIndex] else {
            return
        }

        section.media.removeAll { $0.id == itemID }
        segment.sections[sectionIndex] = .media(section)
        onSaved(segment)
    }

}

private struct MediaBrowserSelection: Identifiable {
    let sectionIndex: Int
    let itemID: String

    var id: String { "\(sectionIndex)-\(itemID)" }
}

private struct MediaDeletionRequest: Identifiable {
    let sectionIndex: Int
    let itemID: String

    var id: String { "\(sectionIndex)-\(itemID)" }
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

private struct MediaBrowserView: View {
    let media: [MediaItem]
    let selectedItemID: String
    let onBack: () -> Void
    let onCaptionSaved: (String, String) -> Void

    @State private var selection: String?
    @State private var isEditingCaption = false
    @State private var caption = ""
    @State private var captionBeforeEditing = ""
    @State private var captionEditorHeight: CGFloat = 48
    @State private var captionFocused = false

    init(media: [MediaItem], selectedItemID: String, onBack: @escaping () -> Void, onCaptionSaved: @escaping (String, String) -> Void) {
        self.media = media
        self.selectedItemID = selectedItemID
        self.onBack = onBack
        self.onCaptionSaved = onCaptionSaved
        _selection = State(initialValue: selectedItemID)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(media) { item in
                    browserPage(for: item)
                        .tag(Optional(item.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .ignoresSafeArea()

            VStack {
                HStack {
                    if isEditingCaption {
                        Button("Cancel") { cancelCaptionEditing() }
                        Spacer()
                        Button("Done") { saveCaption() }
                            .fontWeight(.semibold)
                    } else {
                        Button {
                            onBack()
                        } label: {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .background(.black.opacity(0.45), in: Circle())
                        }
                        .accessibilityLabel("Back to trip segment")

                        Spacer()
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                if isEditingCaption {
                    ZStack(alignment: .topLeading) {
                        if caption.isEmpty {
                            Text("Add a Caption")
                                .foregroundStyle(.white.opacity(0.45))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }

                        GrowingCaptionTextView(text: $caption, height: $captionEditorHeight, isFocused: $captionFocused)
                    }
                    .frame(height: captionEditorHeight)
                        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                } else {
                    Button { beginCaptionEditing() } label: {
                        Text(displayedCaption)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(hasCaption ? .white : .white.opacity(0.45))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                    }
                    .accessibilityLabel(hasCaption ? "Edit caption" : "Add a caption")
                }
            }
            .padding(.bottom, 26)
        }
        .preferredColorScheme(.dark)
        .onChange(of: selection) { _, _ in
            if isEditingCaption { cancelCaptionEditing() }
        }
    }

    @ViewBuilder
    private func browserPage(for item: MediaItem) -> some View {
        if item.type == "video", let url = URL(string: item.url) {
            VideoPlayer(player: AVPlayer(url: url))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ZoomableImage(url: URL(string: item.url))
        }
    }

    private func beginCaptionEditing() {
        guard let item = currentItem else { return }
        caption = item.caption
        captionBeforeEditing = item.caption
        captionEditorHeight = 48
        isEditingCaption = true
        DispatchQueue.main.async { captionFocused = true }
    }

    private func saveCaption() {
        guard let item = currentItem else { return }
        onCaptionSaved(item.id, caption)
        captionFocused = false
        isEditingCaption = false
    }

    private func cancelCaptionEditing() {
        caption = captionBeforeEditing
        captionFocused = false
        isEditingCaption = false
    }

    private var currentItem: MediaItem? {
        media.first(where: { $0.id == selection })
    }

    private var hasCaption: Bool {
        !(currentItem?.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private var displayedCaption: String {
        hasCaption ? (currentItem?.caption ?? "") : "Add a Caption"
    }
}

private struct GrowingCaptionTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    @Binding var isFocused: Bool

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.returnKeyType = .default
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }
        resize(textView)

        if isFocused && !textView.isFirstResponder {
            DispatchQueue.main.async { textView.becomeFirstResponder() }
        } else if !isFocused && textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func resize(_ textView: UITextView) {
        guard textView.bounds.width > 0 else {
            DispatchQueue.main.async { resize(textView) }
            return
        }
        let width = textView.bounds.width
        let fittedHeight = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        let newHeight = max(48, ceil(fittedHeight))
        guard height != newHeight else { return }
        DispatchQueue.main.async {
            height = newHeight
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: GrowingCaptionTextView

        init(parent: GrowingCaptionTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.resize(textView)
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
        }
    }
}

private struct ZoomableImage: View {
    let url: URL?
    @State private var scale: CGFloat = 1
    @State private var scaleAtGestureStart: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var offsetAtGestureStart: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnificationGesture)
                        .simultaneousGesture(panGesture)
                        .onTapGesture(count: 2) { toggleZoom() }
                } else if phase.error != nil {
                    ContentUnavailableView("Unable to Load Image", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.white)
                } else {
                    ProgressView().tint(.white)
                }
            }
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(scaleAtGestureStart * value, 1), 5)
            }
            .onEnded { _ in
                scaleAtGestureStart = scale
                if scale == 1 { offset = .zero; offsetAtGestureStart = .zero }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(width: offsetAtGestureStart.width + value.translation.width,
                                height: offsetAtGestureStart.height + value.translation.height)
            }
            .onEnded { _ in
                guard scale > 1 else { return }
                offsetAtGestureStart = offset
            }
    }

    private func toggleZoom() {
        withAnimation(.spring) {
            if scale > 1 {
                scale = 1; scaleAtGestureStart = 1; offset = .zero; offsetAtGestureStart = .zero
            } else {
                scale = 2.5; scaleAtGestureStart = 2.5
            }
        }
    }
}
