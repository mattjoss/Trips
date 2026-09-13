export interface Trip {
  title: string
  year: string
  image: string
  trip_details: string
}

export type Section = MarkdownSection | MediaSection;

export interface MarkdownSection {
  type: 'markdown'
  title?: string
  markdown: string
}

export interface MediaSection {
  type: 'media'
  media: MediaItem[]
}

export interface MediaItem {
  type: 'image' | 'video'
  url: string
  caption?: string
}

export interface TripSegment {
  name: string
  date?: string
  sections: Section[]
}

export interface TripDetails {
  id: string
  title: string
  date: string
  segments: TripSegment[]
  timestamp: number
}
