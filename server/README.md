# Invoicey Private Sync API

This service synchronizes each Google-authenticated user's workspace between the Flutter web and mobile apps. The client keeps a local copy for offline use and sends workspace snapshots to this API after edits.

Local app login accounts are intentionally not synchronized because the current local model contains passwords. Use Google Sign-In to connect each device to the same private workspace.

## Deploy on aaPanel

1. Create a PostgreSQL database and a least-privilege database user in aaPanel.
2. Run `sql/001_initial.sql` against that database.
3. Copy `.env.example` to `.env` and set every value. Use a long, random `JWT_SECRET`.
4. From the `server` directory, run `npm install` and then `npm start`.
5. In aaPanel, create a Node project for this directory and configure a reverse proxy such as `https://api.yourdomain.com` to the service port.
6. Enable an SSL certificate for the API domain. Do not expose PostgreSQL to the internet.

## Google OAuth

Set `GOOGLE_OAUTH_CLIENT_IDS` to a comma-separated list of your Web and Android OAuth client IDs. The Flutter app sends Google ID tokens to `POST /v1/auth/google`; the server verifies the token before creating its own session JWT.

## Sync behavior

- **Upload** replaces the server snapshot only when it matches the last revision known by that device.
- **Download** replaces the local workspace with the server snapshot.
- Edits upload automatically while connected. If another device has updated the server first, the app reports a conflict and requires the user to download before uploading again.
