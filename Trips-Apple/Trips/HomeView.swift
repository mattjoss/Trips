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
                            NavigationLink {
                                TripDetailsView(
                                    existingTrip: trip,
                                    storageManager: storageManager,
                                    onSaved: { updated in
                                        if let idx = trips.firstIndex(where: { $0.trip_details == trip.trip_details }) {
                                            trips[idx] = updated
                                        }
                                    }
                                )
                            } label: {
                                TripCell(trip: trip)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationTitle("Trips")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            // Sign out
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Sign Out") {
                    try? authManager.signOut()
                }
                .foregroundStyle(.white.opacity(0.7))
            }
            // Add trip — uses NavigationLink via navigationDestination
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    navigateToNewTrip = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(.white)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
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
