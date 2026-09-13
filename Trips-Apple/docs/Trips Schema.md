# Trips Schema

All trip data is stored in Google Cloud Storage with the root at firebase path `/data`.

## Main List (`/trips.json`)
Array of objects with:
- `title`: String - Display title
- `year`: String - Display year
- `image`: String - URL to cover image
- `trip_details`: String - ID used for routing and fetching details (e.g. "2025/costa_rica")
- `timestamp`: The timestamp for when this trip was added

## Trip Details (e.g., `/2025/costa_rica/trip.json`)
Object with:
- `id`: String - Matching the trip_details ID
- `title`: String - Full title
- `date`: String - Date for this trip
- `segments`: Array<TripSegment> - List of trip segments
- `timestamp`: The timestamp for when this trip was added

## Trip Segments 
Object with:
- `name`: String - a name for this segment of the trip
- `sections`: Array<MediaSection | MarkdownSection> A list of sections that contain either media elements or Markdown elements
- `date`: Optional String - date for this segment of the trip

## Markdown Section
Object with:
- `type`: String - "markdown"
- `title`: Optional String - title for this section
- `markdown`: String - markdown content for this section

## Media Section
Object with:
- `type`: String - "media"
- `media`: Array<MediaItem> - List of Media Item objects

### Media Item
Object with:
- `url`: String - URL to the media item
- `caption`: String - Caption for the media item
- `type`: String - Type of media item (image or video)