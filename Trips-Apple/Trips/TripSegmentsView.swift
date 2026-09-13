//
//  TripSegmentsView.swift
//  Trips
//

import SwiftUI
import PhotosUI

struct TripSegmentsView: View {
    let tripDetailsId: String
    let storageManager: StorageManager
    @State var segment: TripSegment
    let onSaved: (TripSegment) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Header edit state
    @State private var isHeaderEditing = false
    @State private var editName: String

    // MARK: - Section edit state
    @State private var editingMarkdownIndex: Int?
    @State private var isShowingTextEditor = false

    // MARK: - Media Picker
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var activeMediaSectionIndex: Int?

    init(tripDetailsId: String, storageManager: StorageManager, segment: TripSegment, onSaved: @escaping (TripSegment) -> Void) {
        self.tripDetailsId = tripDetailsId
        self.storageManager = storageManager
        self._segment = State(initialValue: segment)
        self.onSaved = onSaved
        self._editName = State(initialValue: segment.name)
    }

    var body: some View {
        ZStack {
            Color(hue: 0.58, saturation: 0.06, brightness: 0.09)
                .ignoresSafeArea()

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
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    saveAndDismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
            }
        }
        .fullScreenCover(isPresented: $isShowingTextEditor) {
            if let index = editingMarkdownIndex {
                let binding = Binding(
                    get: {
                        if case .markdown(let s) = segment.sections[index] {
                            return s.markdown
                        }
                        return ""
                    },
                    set: { newValue in
                        if case .markdown(var s) = segment.sections[index] {
                            s.markdown = newValue
                            segment.sections[index] = .markdown(s)
                        }
                    }
                )
                TextEditorView(text: binding) {
                    isShowingTextEditor = false
                    editingMarkdownIndex = nil
                } onCancel: {
                    isShowingTextEditor = false
                    editingMarkdownIndex = nil
                    // If it was a new empty section, maybe remove it? 
                    // For now keeping it simple.
                }
            }
        }
        .photosPicker(isPresented: .init(get: { activeMediaSectionIndex != nil }, set: { if !$0 { activeMediaSectionIndex = nil } }), selection: $selectedPhotos, matching: .images)
        .onChange(of: selectedPhotos) { _, items in
            if let index = activeMediaSectionIndex {
                handlePickedMedia(items, for: index)
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
                } else {
                    Text(segment.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button {
                    if isHeaderEditing {
                        segment.name = editName
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
            HStack {
                Spacer()
                Button {
                    editingMarkdownIndex = index
                    isShowingTextEditor = true
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
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func mediaSectionView(_ section: MediaSection, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(section.media) { item in
                        AsyncImage(url: URL(string: item.url)) { phase in
                            if let image = phase.image {
                                image.resizable()
                                    .scaledToFill()
                            } else {
                                Rectangle().fill(Color.white.opacity(0.1))
                            }
                        }
                        .frame(width: (UIScreen.main.bounds.width - 32 - 36) / 3.5, height: (UIScreen.main.bounds.width - 32 - 36) / 3.5)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Button {
                        activeMediaSectionIndex = index
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .frame(width: (UIScreen.main.bounds.width - 32 - 36) / 3.5, height: (UIScreen.main.bounds.width - 32 - 36) / 3.5)
                            .overlay(
                                Image(systemName: "plus")
                                    .foregroundStyle(.white.opacity(0.4))
                            )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
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
        editingMarkdownIndex = segment.sections.count - 1
        isShowingTextEditor = true
    }

    private func addNewMediaSection() {
        let newSection = MediaSection(media: [])
        segment.sections.append(.media(newSection))
    }

    private func handlePickedMedia(_ items: [PhotosPickerItem], for index: Int) {
        Task {
            var newMediaItems: [MediaItem] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    // Upload to Firebase
                    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                    let filename = "media_\(timestamp)_\(UUID().uuidString.prefix(4)).jpg"
                    let path = "data/trips/\(tripDetailsId)/media/\(filename)"
                    
                    do {
                        let url = try await uploadMediaData(data, path: path)
                        newMediaItems.append(MediaItem(url: url.absoluteString, caption: "", type: "image"))
                    } catch {
                        print("Failed to upload media: \(error)")
                    }
                }
            }
            
            await MainActor.run {
                if case .media(var section) = segment.sections[index] {
                    section.media.append(contentsOf: newMediaItems)
                    segment.sections[index] = .media(section)
                }
                selectedPhotos = []
                activeMediaSectionIndex = nil
            }
        }
    }

    private func uploadMediaData(_ data: Data, path: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            storageManager.upload(data: data, path: path) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func saveAndDismiss() {
        if isHeaderEditing {
            segment.name = editName
        }
        onSaved(segment)
        dismiss()
    }
}
