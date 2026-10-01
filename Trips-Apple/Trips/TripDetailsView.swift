//
//  TripDetailsView.swift
//  Trips
//

import SwiftUI
import PhotosUI

struct TripDetailsView: View {
    let existingTrip: Trip?
    let storageManager: StorageManager
    let onSaved: (Trip) -> Void
    let onDeleted: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Header edit state
    @State private var isEditing: Bool
    @State private var editTitle: String
    @State private var editYear: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var editCoverImage: TripPlatformImage?
    @State private var editImageURL: String   // keeps the existing URL if not changed

    // MARK: - Delete state
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    // MARK: - Trip details (segments)
    @State private var tripDetails: TripDetails?
    @State private var isLoadingDetails = false
    @State private var detailsError: String?

    // MARK: - Navigation
    @State private var selectedSegment: TripSegment?
    @State private var selectedSegmentIndex: Int?
    @State private var isNavigatingToSegment = false

    // MARK: - Save state
    @State private var isSaving = false
    @State private var saveError: String?

    // MARK: - Init

    init(existingTrip: Trip?, storageManager: StorageManager, onSaved: @escaping (Trip) -> Void, onDeleted: (() -> Void)? = nil) {
        self.existingTrip = existingTrip
        self.storageManager = storageManager
        self.onSaved = onSaved
        self.onDeleted = onDeleted

        let isNew = existingTrip == nil
        _isEditing = State(initialValue: isNew)
        _editTitle = State(initialValue: existingTrip?.title ?? "")
        _editYear = State(initialValue: existingTrip?.year ?? Calendar.current.component(.year, from: Date()).description)
        _editImageURL = State(initialValue: existingTrip?.image ?? "")
        _editCoverImage = State(initialValue: nil)
    }


    // MARK: - Body

    var body: some View {
        ZStack {
            Color(hue: 0.58, saturation: 0.06, brightness: 0.09)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 32)

                        if !isEditing {
                            segmentsSection
                        }
                    }
                    .padding(.bottom, 20)
                }

                if !isEditing {
                    // Fixed bottom button
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        addSegmentButton
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                    }
                    .background(Color(hue: 0.58, saturation: 0.06, brightness: 0.09).ignoresSafeArea())
                }
            }

            NavigationLink(
                destination: segmentDestination,
                isActive: $isNavigatingToSegment,
                label: { EmptyView() }
            )
        }
        .navigationTitle(existingTrip == nil ? "New Trip" : "")
        .tripsNavigationTitleStyle(.inline)
        .tripsDarkToolbar()
        .toolbar { toolbarItems }
        .task {
            if let trip = existingTrip {
                loadDetails(for: trip.trip_details)
            }
        }
        .alert(
            "Delete Trip",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteTrip()
            }
        } message: {
            Text("Are you sure you want to delete '\(editTitle)'? This action cannot be undone.")
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        if isEditing {
            editHeader
        } else {
            viewHeader
        }
    }

    /// View-mode header — mirrors TripCell appearance
    private var viewHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Background cover image
            Group {
                if editImageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Rectangle()
                        .fill(Color(hue: 0.58, saturation: 0.3, brightness: 0.2))
                        .overlay(Text("No image").foregroundStyle(.white.opacity(0.65)))
                } else {
                    AsyncImage(url: URL(string: editImageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Rectangle()
                                .fill(Color(hue: 0.58, saturation: 0.4, brightness: 0.25))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.white.opacity(0.3))
                                )
                        default:
                            Rectangle()
                                .fill(Color(hue: 0.58, saturation: 0.3, brightness: 0.2))
                                .overlay(ProgressView().tint(.white))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Title + year
            VStack(alignment: .leading, spacing: 4) {
                Text(editTitle.isEmpty ? "Untitled" : editTitle)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(editYear)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            // Pencil edit button (top-right of cell)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(12)
                }
                Spacer()
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    /// Edit-mode header — photo picker + text fields
    private var editHeader: some View {
        VStack(spacing: 20) {
            // Cover image picker
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    if let img = editCoverImage {
                        Image(tripImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                    } else if !editImageURL.isEmpty {
                        AsyncImage(url: URL(string: editImageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                imagePlaceholder
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                    } else {
                        imagePlaceholder
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(10)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = TripPlatformImage(data: data) {
                        editCoverImage = img
                    }
                }
            }

            // Fields
            VStack(spacing: 14) {
                fieldRow(label: "Title", placeholder: "e.g. Costa Rica") {
                    TextField("", text: $editTitle)
                        .autocorrectionDisabled()
                }
                fieldRow(label: "Year", placeholder: "") {
                    TextField("", text: $editYear)
                        .tripsYearKeyboard()
                }
            }

            if existingTrip != nil {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        if isDeleting {
                            ProgressView()
                                .tint(.red)
                        } else {
                            Image(systemName: "trash")
                            Text("Delete Trip")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.25), lineWidth: 1)
                    )
                }
                .disabled(isDeleting || isSaving)
                .padding(.top, 4)
            }

            if let error = saveError ?? deleteError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.06))
            .overlay(
                VStack(spacing: 10) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Add Cover Image")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
            )
    }

    // MARK: - Segments Section

    @ViewBuilder
    private var segmentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Trip Segments")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            if isLoadingDetails {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding(.vertical, 24)
            } else if let error = detailsError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            } else if let segments = tripDetails?.segments, !segments.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        Button {
                            selectedSegment = segment
                            selectedSegmentIndex = index
                            isNavigatingToSegment = true
                        } label: {
                            HStack {
                                Text(segment.name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled Segment" : segment.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.05))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteSegment(at: index)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                        if index < segments.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, 20)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
            } else if existingTrip != nil {
                // Existing trip, no segments yet
                Text("No segments yet")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Add Segment Button

    private var addSegmentButton: some View {
        Button {
            let newSegment = TripSegment(name: "", sections: [], date: nil)
            selectedSegment = newSegment
            selectedSegmentIndex = nil
            isNavigatingToSegment = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 17))
                Text("Add Trip Segment")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .foregroundStyle(.white.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .cancellationAction) {
                if existingTrip == nil {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    Button("Cancel") {
                        // Reset edits and exit edit mode
                        resetEditState()
                        isEditing = false
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    saveHeader()
                } label: {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .disabled(editTitle.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
            }
        }
    }

    @ViewBuilder
    private var segmentDestination: some View {
        if let segment = selectedSegment {
            TripSegmentsView(
                tripDetailsId: tripDetails?.id ?? "",
                storageManager: storageManager,
                segment: segment
            ) { updatedSegment in
                saveSegment(updatedSegment)
            }
        } else {
            EmptyView()
        }
    }

    // MARK: - Field Row

    @ViewBuilder
    private func fieldRow<Content: View>(
        label: String,
        placeholder: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            content()
                .font(.body)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
    }

    // MARK: - Logic

    private func loadDetails(for tripDetailsId: String) {
        isLoadingDetails = true
        detailsError = nil
        Task {
            do {
                let details = try await storageManager.fetchTripDetails(tripDetailsId: tripDetailsId)
                await MainActor.run {
                    tripDetails = details
                    isLoadingDetails = false
                }
            } catch {
                await MainActor.run {
                    // Not a fatal error — trip detail file may not exist yet
                    isLoadingDetails = false
                }
            }
        }
    }

    private func resetEditState() {
        editTitle = existingTrip?.title ?? ""
        editYear = existingTrip?.year ?? Calendar.current.component(.year, from: Date()).description
        editImageURL = existingTrip?.image ?? ""
        editCoverImage = nil
        selectedPhoto = nil
    }

    private func saveHeader() {
        let trimmedTitle = editTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        isSaving = true
        saveError = nil

        Task {
            do {
                let slug = trimmedTitle.lowercased().replacingOccurrences(of: " ", with: "_")
                let tripDetailsId = "\(editYear)/\(slug)"

                // Upload new cover image if picked
                var imageURL = editImageURL
                if let img = editCoverImage,
                   let jpegData = img.jpegData(compressionQuality: 0.85) {
                    imageURL = try await storageManager.uploadCoverImage(jpegData, tripDetails: tripDetailsId)
                }

                // Build the updated/new Trip
                let timestamp: Double
                if let existing = existingTrip {
                    timestamp = existing.timestamp
                } else {
                    timestamp = Date().timeIntervalSince1970
                }

                let updatedTrip = Trip(
                    title: trimmedTitle,
                    year: editYear,
                    image: imageURL,
                    trip_details: tripDetailsId,
                    timestamp: timestamp
                )

                // Fetch existing trips list, upsert this trip
                var allTrips = (try? await storageManager.fetchTrips()) ?? []
                if let idx = allTrips.firstIndex(where: { $0.trip_details == existingTrip?.trip_details }) {
                    allTrips[idx] = updatedTrip
                } else {
                    allTrips.insert(updatedTrip, at: 0)
                }
                try await storageManager.saveTrips(allTrips)

                await MainActor.run {
                    editImageURL = imageURL
                    editCoverImage = nil
                    isSaving = false
                    onSaved(updatedTrip)
                    if existingTrip == nil {
                        dismiss()
                    } else {
                        isEditing = false
                    }
                }
            } catch {
                await MainActor.run {
                    saveError = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }

    private func saveSegment(_ updatedSegment: TripSegment) {
        guard var details = tripDetails else {
            // If details don't exist yet (new trip), we should probably have initialized them
            // In a real app, we'd ensure tripDetails is non-nil before segment editing
            let newDetails = TripDetails(
                id: existingTrip?.trip_details ?? "\(editYear)/\(editTitle.lowercased().replacingOccurrences(of: " ", with: "_"))",
                title: editTitle,
                date: nil,
                segments: [updatedSegment],
                timestamp: Date().timeIntervalSince1970
            )
            tripDetails = newDetails
            saveFullDetails(newDetails)
            return
        }

        if let idx = selectedSegmentIndex, idx < details.segments.count {
            details.segments[idx] = updatedSegment
        } else if let selectedSegment, let idx = details.segments.firstIndex(where: { $0.id == selectedSegment.id && !$0.id.isEmpty }) {
            details.segments[idx] = updatedSegment
        } else {
            details.segments.append(updatedSegment)
        }
        
        tripDetails = details
        saveFullDetails(details)
    }

    private func deleteSegment(at index: Int) {
        guard var details = tripDetails, details.segments.indices.contains(index) else {
            return
        }

        details.segments.remove(at: index)
        tripDetails = details
        saveFullDetails(details)
    }

    private func saveFullDetails(_ details: TripDetails) {
        Task {
            do {
                try await storageManager.saveTripDetails(details, tripDetailsId: details.id)
            } catch {
                print("Failed to save trip details: \(error)")
            }
        }
    }

    private func deleteTrip() {
        guard let existingTrip else { return }
        isDeleting = true
        deleteError = nil

        Task {
            do {
                try await storageManager.deleteTrip(tripDetailsId: existingTrip.trip_details)
                await MainActor.run {
                    isDeleting = false
                    onDeleted?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    deleteError = error.localizedDescription
                    isDeleting = false
                }
            }
        }
    }
}
