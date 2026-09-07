# Google Sign-In Setup

Google Sign-In requires OAuth credentials owned by your Google Cloud or Firebase project. The app cannot create these credentials automatically.

## Android

1. Open [Google Cloud Console](https://console.cloud.google.com/) or Firebase Console and select your project.
2. Create an **Android OAuth 2.0 client** with this package name:
   ```
   com.example.invoice_managment_system
   ```
3. Add the SHA-1 and SHA-256 certificate fingerprints for every build you use. For the debug build, run:
   ```powershell
   cd android
   .\gradlew.bat signingReport
   ```
4. Download `google-services.json` and place it here:
   ```
   android/app/google-services.json
   ```
5. Rebuild from the project root:
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

## iOS

1. Create an **iOS OAuth 2.0 client** for this bundle ID:
   ```
   com.example.invoiceManagmentSystem
   ```
2. Download `GoogleService-Info.plist` and add it to `ios/Runner` using Xcode so it is included in the Runner target.
3. Add the iOS URL scheme from the downloaded configuration to `ios/Runner/Info.plist`.

## Web

1. Create a **Web OAuth 2.0 client** in your Google Cloud project.
2. Add each web app URL under **Authorized JavaScript origins**, such as `http://localhost:3000` for local testing and your deployed HTTPS domain for production.
3. Build or run the app with the Web client ID:
   ```powershell
   flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com
   ```
4. Use the same `--dart-define` value when building the deployable web app:
   ```powershell
   flutter build web --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com
   ```
