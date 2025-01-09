# Easy Calendar ⚠️ work in progress ⚠️

A Flutter plugin to access & modify native calendars on user's device (iOS & Android).

This plugin allows you to create, read and delete calendars, events and reminders. It handles timezones as UTC.

You can ask for permissions manually if you want to request the user early at runtime. However permissions are handled automatically by the plugin at each method call.

## Getting Started

### iOS

To read/write calendar data, your app must include the following permissions in its info.plist file.

```xml
<key>NSCalendarsUsageDescription</key>
<string>We need access to your calendar to add information about your trip.</string>
<key>NSCalendarsFullAccessUsageDescription</key>
<string>We need access to your calendar to add information about your trip.</string>
<key>NSCalendarsWriteOnlyAccessUsageDescription</key>
<string>We need access to your calendar to add information about your trip.</string>
```

## Contribute

### Build with pigeon

We use [pigeon](https://pub.dev/packages/pigeon) to make communication between Flutter and host platforms easier.

Run the following command from project root to build boilerplate code with pigeon:

```sh
fvm dart pub run pigeon --input ./lib/src/pigeon/calendar_api.dart
```

## License

Copyright © 2025 SNCF Connect & Tech. This project is licensed under the MIT License - see the LICENSE file for details.
