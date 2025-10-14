# Full-Permission Example

This example demonstrates **Eventide's complete calendar API** with full read/write access to calendar data.

## Why This Example Exists

This example showcases comprehensive calendar management including:

- **📖 Reading existing calendars and events** with `retrieveCalendars()` and `retrieveEvents()`
- **📝 Creating events in specific calendars** with full control and customization
- **👥 Managing attendees** (create, retrieve, delete)
- **⏰ Managing reminders** for events
- **🗓️ Full calendar CRUD operations** - the complete calendar management experience

## Perfect For

- Full calendar management applications
- Calendar sync and migration tools
- Event management platforms
- Apps that need to display, modify, or analyze existing calendar data
- Business applications requiring comprehensive calendar integration

## Trade-offs

- **Requires full calendar permissions** - users may be hesitant to grant access
- **More complex permission handling** - need to handle read/write permissions
- **Greater responsibility** - access to sensitive user calendar data

## Run example app

Example app is set to use Swift Package Manager by default. Therefore there is no Podfile.

```sh
flutter config --enable-swift-package-manager
flutter pub get
# Mandatory to get a FlutterGeneratedPluginSwiftPackage with a correct iOS minimum version
flutter build ios --config-only --no-codesign
```