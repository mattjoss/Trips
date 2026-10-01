
## Home Screen
Once logged in, the user should see the Home Screen
The main part of the Home Screen should contain a list. The list will be a list of Trips and each Trip Cell should contain a background image and some text overtop of it. The text should contain the `title` of the trip and the `date` of the trip. 

Data for the Home Screen should be pulled from firebase storage with the path `data/trips.json` and with the schema specified in `Trips Schema.md`


There should be a `+` button in the top right corner of the screen that will take the user to the `Create Trip` screen, which should pop up as a sheet.

See `CreateTripScreen.md` for more details of the `Create Trip` screen


### Delete a trip

Long-press a trip card to show **Delete Trip** (right-click on Mac). Selecting
it opens a confirmation naming the trip and explaining that its segments,
photos, and videos will also be deleted. Cancel makes no changes. Confirming
shows a progress indicator and prevents repeated actions. The card disappears
only after deletion succeeds; failures show an alert so the user can retry.

Deletion removes all objects under `data/trips/{trip_details}/`, including
`trip.json`, `cover.jpg`, and the `media/` folder, then removes the trip from
`data/trips.json`. Images linked from elsewhere are not owned by this trip
and are not deleted. The existing Delete Trip action in trip details uses the
same behavior. Storage rules must permit listing and deleting trip objects.
