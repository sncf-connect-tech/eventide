# Native-Only Example

This example demonstrates **Eventide's native platform integration** - the most privacy-friendly approach to event creation.

## Why This Example Exists

This example showcases the `createEventThroughNativePlatform()` method, which:

- **🔒 Requires NO calendar permissions** in your app's manifest
- **📱 Uses the system's native event creation UI** (Calendar app on iOS, Intent on Android)
- **👤 Gives users complete control** over what gets saved and where
- **🛡️ Maximizes user privacy** by not accessing any existing calendar data

## Perfect For

- Apps that occasionally need to create events but don't want sensitive calendar permissions
- Privacy-focused applications
- Quick event creation without complex calendar integration
- Apps targeting users who are security-conscious about calendar access

## Run example app

Example app is set to use Swift Package Manager by default. Therefore there is no Podfile.

```sh
flutter config --enable-swift-package-manager
flutter pub get
# Mandatory to get a FlutterGeneratedPluginSwiftPackage with a correct iOS minimum version
flutter build ios --config-only --no-codesign
```