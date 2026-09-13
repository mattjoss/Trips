# Trips repository guide

This repository contains two clients for the same trip data:

- `Trips-Apple/` is the native iOS app. It is a SwiftUI Xcode project at
  `Trips-Apple/Trips.xcodeproj` (iOS deployment target 18.6).
- `TripsWeb/` is the web app: a Vite + TypeScript single-page app using Lit.

## Shared data contract

Both clients consume trip content from Firebase/Google Cloud Storage under the
`data/` prefix. The canonical data layout is:

- `data/trips.json` — array of trip list entries.
- `data/trips/{trip_details}/trip.json` — details for an individual trip.
- `data/trips/{trip_details}/cover.jpg` — cover image uploaded by the iOS app.

Keep the clients' models and this JSON contract compatible. A trip list entry
uses `title`, `year`, `image`, `trip_details`, and `timestamp`. A detail record
uses `id`, `title`, optional `date`, `segments`, and `timestamp`. A segment has
`name`, optional `date`, and `sections`; section types are `markdown` and
`media`. See `Trips-Apple/docs/Trips Schema.md` for the complete schema.

The web app's storage endpoint is configured in `TripsWeb/src/config.ts`; do
not casually point it at another bucket. The iOS app reads and writes the same
paths in `Trips-Apple/Trips/StorageManager.swift`.

## Working on the web app

- Install dependencies in `TripsWeb/` with `npm install`.
- Run locally with `npm run dev`; verify production compilation with
  `npm run build` (TypeScript check plus Vite build).
- Application source is in `TripsWeb/src/`. Components are Lit custom
  elements and deliberately render into the light DOM via `createRenderRoot()`.
  Preserve that behavior unless the CSS strategy is updated as well.
- Routing is query-string based: `/?id={trip_details}`. Keep route IDs aligned
  with the storage path and sanitize/build detail URLs through
  `getTripDetailsUrl()`.
- `TripsWeb/public/` contains local/sample trip JSON. Treat it as fixtures;
  production reads from the configured storage endpoint.

## Working on the iOS app

- Open and build `Trips-Apple/Trips.xcodeproj` in Xcode. Dependencies are
  Swift Package Manager packages (Firebase Auth/Core/Storage and Google Sign-In);
  their resolved versions are in the project workspace's `Package.resolved`.
- SwiftUI screens and data models are under `Trips-Apple/Trips/`. Use the
  existing async/await Firebase Storage APIs for trip data operations.
- Firebase is configured at launch in `TripsApp.swift`; authentication is
  Google Sign-In through `AuthManager.swift`. Do not alter
  `GoogleService-Info.plist`, URL scheme configuration, or storage access rules
  unless the task explicitly concerns Firebase/Google configuration.
- Consult `Trips-Apple/docs/` for screen behavior, storage notes, and the data
  schema before changing content flows.

## Repository hygiene

- Keep changes scoped to the relevant client; update both only when changing
  the shared data contract or user-facing parity is explicitly desired.
- Do not commit Xcode user-state files under `xcuserdata/` or other generated
  IDE state. Preserve unrelated in-progress edits in this working tree.
