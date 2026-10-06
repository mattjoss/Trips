# Trips Web

Website for displaying our trips (`travel.jossfamily.com`).

## How to Run Locally

```bash
npm run dev
```

## How to Deploy to Firebase Hosting

To build the application and deploy it directly to Firebase Hosting:

```bash
npm run deploy
```

Alternatively, run:

```bash
npm run build
npx -y firebase-tools@latest deploy --only hosting
```


## Firebase Deploy
Firebase project is deployed at
https://joss-travel-ios.web.app


## First-Time Setup / Re-initialization

If `firebase.json` is missing or you are setting up on a new machine:

1. **Log in to Firebase CLI:**
   ```bash
   npx -y firebase-tools@latest login
   ```

2. **Initialize Firebase Hosting:**
   ```bash
   npx -y firebase-tools@latest init hosting
   ```
   - **Project selection:** Select `joss-travel-ios`
   - **Public directory:** `dist`
   - **Configure as single-page app (SPA)?** `y`
   - **Set up automatic builds and deploys with GitHub?** `n`
   - **Overwrite dist/index.html?** `n`

3. **Verify `firebase.json` has `site` set:**
   Ensure [`firebase.json`](file:///Users/joss/DevProjects/Trips/TripsWeb/firebase.json) includes `"site": "joss-travel-ios"` inside the `"hosting"` block:
   ```json
   {
     "hosting": {
       "site": "joss-travel-ios",
       "public": "dist",
       "ignore": [
         "firebase.json",
         "**/.*",
         "**/node_modules/**"
       ],
       "rewrites": [
         {
           "source": "**",
           "destination": "/index.html"
         }
       ]
     }
   }
   ```