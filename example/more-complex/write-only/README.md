# Write-Only Example

This example demonstrates **Eventide's write-only calendar access** - perfect for event creation without reading existing data.

## Why This Example Exists

This example showcases the `createEventInDefaultCalendar()` method, which:

- **✍️ Creates events directly** in the user's default calendar
- **🔐 Uses minimal permissions** (write-only access on iOS 17+, limited read on older versions)
- **🚫 Cannot read existing events** - enhanced privacy protection
- **⚡ Faster than full permission** - users are more likely to grant limited access
- **📅 Automatic calendar selection** - no need to choose which calendar to use

## Perfect For

- Event creation apps (meeting schedulers, appointment bookers)
- Apps that create events but never need to read existing calendar data
- iOS 17+ apps wanting to leverage write-only calendar permissions
- Applications prioritizing user privacy while maintaining functionality

## Run example app

Example app is set to use Swift Package Manager by default. Therefore there is no Podfile.

```sh
flutter config --enable-swift-package-manager
flutter pub get
# Mandatory to get a FlutterGeneratedPluginSwiftPackage with a correct iOS minimum version
flutter build ios --config-only --no-codesign
```