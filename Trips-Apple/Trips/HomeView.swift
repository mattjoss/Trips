//
//  HomeView.swift
//  Trips
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var storageManager = StorageManager()

    @State private var trips: [Trip] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var navigateToNewTrip = false
    @State private var selectedTrip: Trip?
    @State private var navigateToTrip = false
    @State private var tripToDelete: Trip?
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        ZStack {
            // Background
            Color(hue: 0.58, saturation: 0.06, brightness: 0.09)
                .ignoresSafeArea()

            if isLoading {
                ProgressView("Loading trips…")
                    .tint(.white)
                    .foregroundStyle(.white)
            } else if let error = loadError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.yellow)
                    Text(error)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    Button("Retry") { loadTrips() }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if trips.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "suitcase.rolling")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No trips yet")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Tap + to add your first trip")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.35))
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(trips) { trip in
                            Button {
                                selectedTrip = trip
                                navigateToTrip = true
                            } label: {
                                TripCell(trip: trip)
                                    .contentShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    tripToDelete = trip
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete Trip", systemImage: "trash")
                                }
                                .disabled(isDeleting)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .disabled(isDeleting)
        .overlay {
            if isDeleting {
                ProgressView("Deleting trip…")
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .navigationTitle("Trips")
        .tripsNavigationTitleStyle(.large)
        .toolbar {
            // Sign out
            ToolbarItem(placement: .cancellationAction) {
                Button("Sign Out") {
                    try? authManager.signOut()
                }
                .foregroundStyle(.white.opacity(0.7))
            }
            // Add trip — uses NavigationLink via navigationDestination
            ToolbarItem(placement: .primaryAction) {
                Button {
                    navigateToNewTrip = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(.white)
            }
        }
        .tripsDarkToolbar()
        .navigationDestination(isPresented: $navigateToTrip) {
            if let trip = selectedTrip {
                TripDetailsView(
                    existingTrip: trip,
                    storageManager: storageManager,
                    onSaved: { updated in
                        if let index = trips.firstIndex(where: { $0.trip_details == trip.trip_details }) {
                            trips[index] = updated
                        }
                    },
                    onDeleted: {
                        trips.removeAll { $0.trip_details == trip.trip_details }
                    }
                )
            } else {
                EmptyView()
            }
        }
        .navigationDestination(isPresented: $navigateToNewTrip) {
            TripDetailsView(
                existingTrip: nil,
                storageManager: storageManager,
                onSaved: { newTrip in
                    trips.insert(newTrip, at: 0)
                }
            )
        }
        .task { loadTrips() }
        .alert("Delete Trip?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { tripToDelete = nil }
            Button("Delete Trip", role: .destructive) {
                if let trip = tripToDelete { deleteTrip(trip) }
            }
        } message: {
            Text("Delete '\(tripToDelete?.title ?? "this trip")' and all its segments, photos, and videos? This cannot be undone.")
        }
        .alert("Unable to Delete Trip", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
    }

    private func deleteTrip(_ trip: Trip) {
        guard !isDeleting else { return }
        isDeleting = true
        Task {
            defer {
                isDeleting = false
                tripToDelete = nil
            }
            do {
                try await storageManager.deleteTrip(tripDetailsId: trip.trip_details)
                trips.removeAll { $0.trip_details == trip.trip_details }
            } catch {
                deleteError = "Deletion could not be completed. Some files may already have been removed. Please try again. \(error.localizedDescription)"
            }
        }
    }

    private func loadTrips() {
        isLoading = true
        loadError = nil
        Task {
            do {
                trips = try await storageManager.fetchTrips()
            } catch {
                loadError = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthManager.shared)
    }
}
