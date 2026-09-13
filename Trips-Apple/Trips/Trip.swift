//
//  Trip.swift
//  Trips
//

import Foundation

// MARK: - Trip (home list entry)

struct Trip: Codable, Identifiable {
    var id: String { trip_details }

    var title: String
    var year: String
    var image: String          // Download URL string
    var trip_details: String   // e.g. "2025/costa_rica"
    var timestamp: Double      // Unix timestamp (seconds since epoch)
}

// MARK: - Trip Details (data/trips/{trip_details}/trip.json)

struct TripDetails: Codable {
    var id: String
    var title: String
    var date: String?
    var segments: [TripSegment]
    var timestamp: Double
}

// MARK: - Trip Segment

struct TripSegment: Codable, Identifiable {
    var id: String { name + (date ?? "") }
    var name: String
    var sections: [TripSection]
    var date: String?

    enum CodingKeys: String, CodingKey {
        case name, sections, date
    }

    init(name: String, sections: [TripSection], date: String?) {
        self.name = name
        self.sections = sections
        self.date = date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        sections = (try? container.decode([TripSection].self, forKey: .sections)) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encode(sections, forKey: .sections)
    }
}

// MARK: - Trip Sections

enum TripSection: Codable, Identifiable {
    case markdown(MarkdownSection)
    case media(MediaSection)

    var id: String {
        switch self {
        case .markdown(let section): return section.id
        case .media(let section): return section.id
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "markdown":
            let section = try MarkdownSection(from: decoder)
            self = .markdown(section)
        case "media":
            let section = try MediaSection(from: decoder)
            self = .media(section)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown section type: \(type)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .markdown(let section):
            try container.encode("markdown", forKey: .type)
            try section.encode(to: encoder)
        case .media(let section):
            try container.encode("media", forKey: .type)
            try section.encode(to: encoder)
        }
    }
}

struct MarkdownSection: Codable, Identifiable {
    var id = UUID().uuidString
    var title: String?
    var markdown: String

    init(title: String? = nil, markdown: String) {
        self.title = title
        self.markdown = markdown
    }

    enum CodingKeys: String, CodingKey {
        case title, markdown
    }
}

struct MediaSection: Codable, Identifiable {
    var id = UUID().uuidString
    var media: [MediaItem]

    init(media: [MediaItem]) {
        self.media = media
    }

    enum CodingKeys: String, CodingKey {
        case media
    }
}

struct MediaItem: Codable, Identifiable {
    var id = UUID().uuidString
    var url: String
    var caption: String
    var type: String // "image" or "video"

    init(url: String, caption: String, type: String) {
        self.url = url
        self.caption = caption
        self.type = type
    }

    enum CodingKeys: String, CodingKey {
        case url, caption, type
    }
}
