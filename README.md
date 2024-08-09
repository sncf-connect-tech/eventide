# Flutter Calendar Connect

A Flutter plugin to access & modify native calendars on user's device (iOS & Android).

## Getting Started

To read calendar data, your app must include the READ_CALENDAR permission in its manifest file. It must include the WRITE_CALENDAR permission to delete, insert or update calendar data:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"...>
    <uses-sdk android:minSdkVersion="14" />
    <uses-permission android:name="android.permission.READ_CALENDAR" />
    <uses-permission android:name="android.permission.WRITE_CALENDAR" />
    ...
</manifest>
```

## Build with pigeon

We use [pigeon](https://pub.dev/packages/pigeon) to make communication between Flutter and host platforms easier.

Run the following command to build boilerplate code with pigeon:

```sh
fvm dart pub run pigeon --input pigeon/schema.dart
```

## License

Copyright © 2024 SNCF Connect & Tech. This project is licensed under the MIT License - see the LICENSE file for details.