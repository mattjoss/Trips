"""Check the actual deletion methods against in-memory storage; never contacts Firebase.

Run with: python3 Trips-Apple/tests/test_trip_deletion.py
Requires the Swift compiler from Xcode.
"""
from pathlib import Path
import subprocess
import tempfile
source = (Path(__file__).resolve().parents[1] / 'Trips/StorageManager.swift').read_text()
methods = source[source.index('    func deleteTrip(tripDetailsId:'):source.rfind('\n}')]
harness = r'''
import Foundation
let StorageErrorDomain = "Storage"
enum StorageErrorCode: Int { case objectNotFound = -13010 }
struct Trip { let trip_details: String }
final class FakeStore {
    var paths: Set<String> = ["data/trips/2025/test/trip.json", "data/trips/2025/test/cover.jpg", "data/trips/2025/test/media/a.jpg", "data/trips/2025/test/media/nested/b.mov", "data/trips/2025/other/trip.json"]
    var events: [String] = []
    var failDelete: String?
    var failList = false
    var missingObject: String?
    func reference() -> StorageReference { StorageReference(store: self, path: "") }
}
struct StorageListResult { var items: [StorageReference]; var prefixes: [StorageReference] }
final class StorageReference {
    let store: FakeStore
    let path: String
    init(store: FakeStore, path: String) { self.store = store; self.path = path }
    func child(_ value: String) -> StorageReference { StorageReference(store: store, path: value) }
    func listAll() async throws -> StorageListResult {
        store.events.append("list:" + path)
        if store.failList { throw NSError(domain: "test", code: 1) }
        let prefix = path + "/"
        var items: [StorageReference] = []
        var directories = Set<String>()
        for item in store.paths.sorted() where item.hasPrefix(prefix) {
            let suffix = String(item.dropFirst(prefix.count))
            if let slash = suffix.firstIndex(of: "/") {
                directories.insert(prefix + suffix[..<slash])
            } else { items.append(StorageReference(store: store, path: item)) }
        }
        return StorageListResult(items: items, prefixes: directories.sorted().map { StorageReference(store: store, path: $0) })
    }
    func delete() async throws {
        store.events.append("delete:" + path)
        if store.failDelete == path { throw NSError(domain: "test", code: 2) }
        store.paths.remove(path)
        if store.missingObject == path { throw NSError(domain: StorageErrorDomain, code: StorageErrorCode.objectNotFound.rawValue) }
    }
}
final class StorageManager {
    let storage = FakeStore()
    var trips = [Trip(trip_details: "2025/test"), Trip(trip_details: "2025/other")]
    var failFetch = false
    var failSave = false
    var saves = 0
    func fetchTrips() async throws -> [Trip] {
        if failFetch { throw NSError(domain: "test", code: 3) }
        return trips
    }
    func saveTrips(_ trips: [Trip]) async throws {
        if failSave { throw NSError(domain: "test", code: 4) }
        saves += 1
        self.trips = trips
    }
'''
harness += methods + '\n}\n'
harness += r'''
func expectFailure(_ manager: StorageManager, id: String = "2025/test") async {
    do { try await manager.deleteTrip(tripDetailsId: id); fatalError("Expected failure") }
    catch { }
}
@main struct Checks {
    static func main() async throws {
        let success = StorageManager()
        try await success.deleteTrip(tripDetailsId: "2025/test")
        assert(success.storage.paths == ["data/trips/2025/other/trip.json"])
        assert(success.trips.map(\.trip_details) == ["2025/other"])
        let firstDelete = success.storage.events.firstIndex { $0.hasPrefix("delete:") }!
        assert(!success.storage.events[firstDelete...].contains { $0.hasPrefix("list:") })
        let fetchFailure = StorageManager(); fetchFailure.failFetch = true
        await expectFailure(fetchFailure)
        assert(fetchFailure.storage.events.isEmpty && fetchFailure.saves == 0)
        let listFailure = StorageManager(); listFailure.storage.failList = true
        await expectFailure(listFailure)
        assert(!listFailure.storage.events.contains { $0.hasPrefix("delete:") } && listFailure.saves == 0)
        let partial = StorageManager(); partial.storage.failDelete = "data/trips/2025/test/media/a.jpg"
        await expectFailure(partial)
        assert(partial.saves == 0 && partial.trips.count == 2)
        partial.storage.failDelete = nil
        try await partial.deleteTrip(tripDetailsId: "2025/test")
        assert(partial.storage.paths == ["data/trips/2025/other/trip.json"] && partial.trips.count == 1)
        let missing = StorageManager(); missing.storage.missingObject = "data/trips/2025/test/cover.jpg"
        try await missing.deleteTrip(tripDetailsId: "2025/test")
        assert(missing.saves == 1)
        let saveFailure = StorageManager(); saveFailure.failSave = true
        await expectFailure(saveFailure)
        assert(saveFailure.trips.count == 2)
        saveFailure.failSave = false
        try await saveFailure.deleteTrip(tripDetailsId: "2025/test")
        assert(saveFailure.trips.count == 1)
        for id in ["", "/", "..", "2025/../other", "2025//test", "2025/test/", "2025\\test"] {
            let invalid = StorageManager()
            await expectFailure(invalid, id: id)
            assert(invalid.storage.events.isEmpty && invalid.saves == 0)
        }
        print("PASS: whole-trip deletion, isolation, list-before-delete, read/list/delete/save failures, retries, missing files, and invalid paths")
    }
}
'''
harness = harness.replace('\\.trip_details', '\\.trip_details')
with tempfile.TemporaryDirectory(prefix="trips-deletion-checks-") as temporary:
    directory = Path(temporary)
    swift_source = directory / "TripDeletionChecks.swift"
    executable = directory / "TripDeletionChecks"
    swift_source.write_text(harness)
    subprocess.run([
        "swiftc", "-module-cache-path", str(directory / "ModuleCache"),
        "-parse-as-library", str(swift_source), "-o", str(executable)
    ], check=True)
    subprocess.run([str(executable)], check=True)
