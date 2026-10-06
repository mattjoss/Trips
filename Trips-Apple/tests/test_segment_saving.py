"""Regression checks for repeated saves from one segment editor; no Firebase access.

Run: python3 Trips-Apple/tests/test_segment_saving.py
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "Trips/TripDetailsView.swift").read_text()
start = source.index("    private func saveSegment(")
end = source.index("    private var segmentDeletionName:", start)
method = source[start:end].replace("private func", "func", 1)
harness = '''
import Foundation
final class Editor {
    var tripDetails: TripDetails?
    var existingTrip: Trip? = nil
    var editYear = "2026"
    var editTitle = "Test"
    var selectedSegmentIndex: Int? = nil
    var selectedSegment: TripSegment? = TripSegment(name: "", sections: [], date: nil)
    var saved: [TripDetails] = []
    func saveFullDetails(_ details: TripDetails) { saved.append(details) }
''' + method + '''
}
@main struct Checks {
    static func main() {
        for startsWithDetails in [false, true] {
            let editor = Editor()
            if startsWithDetails {
                editor.tripDetails = TripDetails(id: "2026/test", title: "Test", date: nil, segments: [], timestamp: 0)
            }
            var segment = TripSegment(name: "Paris", sections: [], date: nil)
            editor.saveSegment(segment)
            assert(editor.selectedSegmentIndex == 0)
            segment.sections.append(.markdown(MarkdownSection(markdown: "First text")))
            editor.saveSegment(segment)
            segment.name = "Paris and beyond"
            editor.saveSegment(segment)
            segment.sections.append(.media(MediaSection(media: [])))
            editor.saveSegment(segment)
            assert(editor.tripDetails?.segments.count == 1)
            assert(editor.tripDetails?.segments[0].name == "Paris and beyond")
            assert(editor.tripDetails?.segments[0].sections.count == 2)
            assert(editor.saved.count == 4)
            assert(editor.saved.allSatisfy { $0.segments.count == 1 })
            assert(editor.selectedSegment?.name == "Paris and beyond")
        }
        let editor = Editor()
        let first = TripSegment(name: "Paris", sections: [], date: nil)
        editor.tripDetails = TripDetails(id: "2026/test", title: "Test", date: nil, segments: [first], timestamp: 0)
        editor.selectedSegment = TripSegment(name: "", sections: [], date: nil)
        var second = TripSegment(name: "Paris", sections: [], date: nil)
        editor.saveSegment(second)
        second.sections.append(.markdown(MarkdownSection(markdown: "Second segment")))
        editor.saveSegment(second)
        assert(editor.tripDetails?.segments.count == 2)
        assert(editor.tripDetails?.segments[0].sections.isEmpty == true)
        assert(editor.tripDetails?.segments[1].sections.count == 1)
        print("PASS: naming, text/media additions, and renaming update one segment; separate same-name segments remain separate")
    }
}
'''
with tempfile.TemporaryDirectory(prefix="trips-segment-checks-") as temporary:
    directory = Path(temporary)
    swift_source = directory / "SegmentSavingChecks.swift"
    executable = directory / "SegmentSavingChecks"
    swift_source.write_text(harness)
    subprocess.run([
        "swiftc", "-module-cache-path", str(directory / "ModuleCache"),
        "-parse-as-library", str(root / "Trips/Trip.swift"), str(swift_source),
        "-o", str(executable)
    ], check=True)
    subprocess.run([str(executable)], check=True)
