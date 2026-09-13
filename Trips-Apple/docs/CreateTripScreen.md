This screen should have a field to add the trip `title` and `year`, with the year filled in by default to the current year. The screen shoudl also have a button to add a cover image.


There should be a `Create` button at the bottom of the screen that will create the trip and navigate back to the home screen.

The trip should be created with the following data:
- `title`: The trip title
- `year`: The trip year
- `trip_details`: The trip details ID. This should be computed by taking the `year` and `title` and joining them with a `/` and substituting spaces with underscores. For example, if the trip title is "Costa Rica" and the year is 2025, the trip details ID should be `2025/costa_rica`
- `image`: The cover image URL. This should be uploaded to Firebase Storage using the path `data/trips/{trip_details}/cover.jpg` and the URL should be stored here.
- `timestamp`: The timestamp for when this trip was added


This trip should be inserted at the top of the list stored at `data/trips.json` and `data/trips.json` should be updated in firebase storage