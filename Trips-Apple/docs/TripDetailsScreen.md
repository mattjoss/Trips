When user taps on a trip cell from the home screen, the user should be taken to the trip details screen for that trip. Also, the user can tap on the `+` button in the top right corner of the home screen to create a new trip which will also navigate to this page.

## Header
At the top of the screen is where the title, date and cover image are displayed. This portion, which we'll call the `Header`, can either be in edit mode or not. If not in edit mode, this portion should be similar to the trip cell in the home screen. If in edit mode, this `Header` portion should have text fields for the `title` and `year`, and a button to change the cover image. If there is no year, fill it in with the current year.


When not in edit mode, there should be a button with a pencil icon in the upper right corner of the display cell that will enter edit mode. When in edit mode, there should be a `Save` button in the top right corner of the screen that will save the `Header` info and exit edit mode.

## Trip Segments
Below the title and date, there should be a list of trip segments. Each trip segment should just list the name of the trip segment. This is tied to the `Trip Segments` as specified in `Trips Schema.md`

The trip details should be fetched from firebase storage with the path `data/trips/{trip_details}/trip.json` where `trip_details` is the trip details ID for the selected trip.

See `Trips Schema.md` for the schema of the trip details.

At the bottom of the screen, there should be a button labelled `Add Trip Segment` that will take the user to the `Trip Segments` screen, which should slide over like a navigation.


### Header Update
If the `Header` has been edited, or it did not exist. The trip should be created or updated with the following data:
- `title`: The trip title
- `year`: The trip year
- `trip_details`: The trip details ID. This should be computed by taking the `year` and `title` and joining them with a `/` and substituting spaces with underscores. For example, if the trip title is "Costa Rica" and the year is 2025, the trip details ID should be `2025/costa_rica`
- `image`: The cover image URL. This should be uploaded to Firebase Storage using the path `data/trips/{trip_details}/cover.jpg` and the URL should be stored here.
- `timestamp`: The timestamp for when this trip was added. Should not be altered if updating an existing trip.


If creating, this trip should be inserted at the top of the list stored at `data/trips.json` 

Save the edited trip data to `data/trips.json` in firebase storage

### Trip Segments Update
When the trip segments have been edited, added or removed, the trip segments should be saved to `data/trips/{trip_details}/trip.json` in firebase storage