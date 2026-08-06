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

Web Google Sign-In needs a separate Web OAuth client and authorized JavaScript origins. The current app intentionally keeps Google account selection mobile-only until those web credentials are supplied.
