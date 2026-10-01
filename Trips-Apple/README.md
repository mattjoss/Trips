# Trips for iOS and macOS

Both apps share the SwiftUI screens, trip models, and Firebase Storage data in
`Trips/`. The native Mac target is `TripsMac`; the existing iOS target is `Trips`.

## Run the Mac app

1. Open `Trips.xcodeproj` in Xcode.
2. Choose the **TripsMac** scheme and **My Mac** as the destination.
3. Select your development team under Signing & Capabilities if necessary.
4. Run the app and sign in with Google.

The Mac target requires macOS 15.7 or later. It uses a resizable window, native
text editors (including selection-aware Markdown formatting), desktop media
thumbnails, and Previous/Next controls in the photo/video browser. Cover images
and media are selected through PhotosPicker on both platforms.

## Configuration

The Mac app reuses the existing Firebase project, Google client ID, bundle ID
(`com.jossfamily.Trips`), and Google callback scheme. Its separate
`TripsMac/Info.plist` keeps the iOS settings intact. No storage paths or JSON
formats change. Both apps edit the same trips.

`TripsMac/TripsMac.entitlements` enables the app sandbox, outgoing network
connections, selected-file read access, and the app's keychain access group.
Use Xcode signing when testing sign-in: unsigned builds verify compilation but
cannot validate the signed app's Firebase keychain persistence. A distribution
build requires the appropriate Mac signing identity/provisioning profile.

## Verification

Build **TripsMac / My Mac** and **Trips / an iOS simulator**. Before distributing,
verify Google sign-in and reopening the app, trip loading, cover selection,
Markdown edits, media upload, video playback, caption edits, and sign-out with
a signed app. Use a disposable trip for write/delete checks because both apps
use the production data.
