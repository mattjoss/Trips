import Foundation
import FirebaseStorage
import Combine

class StorageManager: ObservableObject {
    let storage = Storage.storage()

    // MARK: - Generic Upload / Download

    /// Upload raw data to a Firebase Storage path and return the download URL.
    func upload(
        data: Data,
        path: String,
        contentType: String? = nil,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        storageRef.putData(data, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
        }
    }

    /// Download raw data from a Firebase Storage path.
    func download(path: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let storageRef = storage.reference().child(path)
        let maxSize: Int64 = 10 * 1024 * 1024
        storageRef.getData(maxSize: maxSize) { data, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                completion(.success(data))
            }
        }
    }

    // MARK: - Trips JSON

    /// Fetch and decode the trips list from `data/trips.json`.
    func fetchTrips() async throws -> [Trip] {
        let ref = storage.reference().child("data/trips.json")
        let maxSize: Int64 = 10 * 1024 * 1024
        let data = try await ref.data(maxSize: maxSize)
        return try JSONDecoder().decode([Trip].self, from: data)
    }

    /// Encode and upload the trips list to `data/trips.json`.
    func saveTrips(_ trips: [Trip]) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(trips)
        let ref = storage.reference().child("data/trips.json")
        let metadata = StorageMetadata()
        metadata.contentType = "application/json"
        metadata.cacheControl = "no-cache, no-store, must-revalidate"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        _ = try await ref.updateMetadata(metadata)
    }

    // MARK: - Cover Image Upload

    /// Upload a JPEG cover image for a trip and return the download URL string.
    /// - Parameter tripDetails: e.g. "2025/costa_rica"
    func uploadCoverImage(_ imageData: Data, tripDetails: String) async throws -> String {
        let path = "data/trips/\(tripDetails)/cover.jpg"
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    // MARK: - Trip Details JSON

    /// Fetch and decode trip details from `data/trips/{tripDetailsId}/trip.json`.
    func fetchTripDetails(tripDetailsId: String) async throws -> TripDetails {
        let ref = storage.reference().child("data/trips/\(tripDetailsId)/trip.json")
        let maxSize: Int64 = 10 * 1024 * 1024
        let data = try await ref.data(maxSize: maxSize)
        return try JSONDecoder().decode(TripDetails.self, from: data)
    }

    /// Encode and upload trip details to `data/trips/{tripDetailsId}/trip.json`.
    func saveTripDetails(_ details: TripDetails, tripDetailsId: String) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(details)
        let ref = storage.reference().child("data/trips/\(tripDetailsId)/trip.json")
        let metadata = StorageMetadata()
        metadata.contentType = "application/json"
        metadata.cacheControl = "no-cache, no-store, must-revalidate"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        _ = try await ref.updateMetadata(metadata)
    }

    /// Delete all objects owned by the trip, then remove its list entry.
    func deleteTrip(tripDetailsId: String) async throws {
        let components = tripDetailsId.split(separator: "/", omittingEmptySubsequences: false)
        guard !components.isEmpty,
              components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }),
              !tripDetailsId.contains("\\") else {
            throw NSError(domain: "Trips", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "The trip storage path is invalid."
            ])
        }
        // Never treat a failed list download as an empty list.
        _ = try await fetchTrips()
        let folder = storage.reference().child("data/trips/\(tripDetailsId)")
        // Finish listing before deleting so pagination cannot skip objects.
        let objects = try await tripObjects(in: folder)
        for object in objects {
            do {
                try await object.delete()
            } catch {
                let storageError = error as NSError
                guard storageError.domain == StorageErrorDomain,
                      storageError.code == StorageErrorCode.objectNotFound.rawValue else {
                    throw error
                }
            }
        }
        // Reload to preserve unrelated changes made while files were deleted.
        var allTrips = try await fetchTrips()
        allTrips.removeAll(where: { $0.trip_details == tripDetailsId })
        try await saveTrips(allTrips)
    }

    private func tripObjects(in folder: StorageReference) async throws -> [StorageReference] {
        let contents = try await folder.listAll()
        var objects = contents.items
        for prefix in contents.prefixes {
            objects.append(contentsOf: try await tripObjects(in: prefix))
        }
        return objects
    }

}
