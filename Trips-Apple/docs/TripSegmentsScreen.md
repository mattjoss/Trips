## Trip Segment Screen
The `Trip Segment` screen shows the name of the segment and a list of trip segments for the current trip. This is a list of markdown segments and media segments.

### Navigating to Trip Segment Screen
Tapping the `+ Add Trip Segment` button will open the `Trip Segment` screen. Also, tapping on an existing segment will open the `Trip Segment` screen.

### Trip Segment Screen Data
Data for each segment is as described in `Trips Schema.md`.

### Trip Segment Screen Layout
The name of the segment will be displayed in the `Segment Header` area. Sinilar to the `Trip Header` area in the `Trip Details` screen, this is either editable or not and is toggled but the pencil icon in the top right corner of the `Segment Header` area. In Edit mode, the name is editable and in View mode, the name is not editable and disoplayed in a large bold font.

Following the `Segment Header` area is a list of `Trip Segments`. 

#### Markdown segments
Markdown segments will be displayed fitting the width to the screen with a bit of padding and the height will be based on content. The segments are not editable, but there is a pencil icon in the top right corner of each segment that will toggle the segment into Edit mode. Edit mode replaces that segment's display with an inline text editor and scrolls it into view. While editing, Cancel replaces the back button and Done appears on the right; Done saves the segment and ends editing.

#### Media segments
Media segments will be displayed horizontally scrolling list of media items with a plus button at the end to add more media items. The plus button should bring up the standard media picker screen. The media item cells should be square and should be sized such that 3.5 cells should fit the width of the screen. The cells should be aspect fit to the image.


#### Adding new segments
At the bottom of the screen there are two buttons side by side. On the left is `Add Text` and on the right is `Add Media`. Tapping on `Add Text` will add a new markdown section to the list of sections. Tapping on `Add Media` will add a new media section to the list of sections.

When a new markdown section is added or when a markdown section is edited, the app should show the same inline text editor in the section's position and scroll it into view.

When a new media section is added, a new empty media section should be added to the list of sections and saved immediately. It will be empty except for the plus button.
