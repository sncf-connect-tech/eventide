# Platform Setup

Eventide is designed with user privacy as a core principle.
- **Minimal permissions**: Only request what you actually need.
- **User choice**: Support for iOS 17+ write-only access.
- **System delegation**: Using Android system for zero-permission event creation.

## Android

Add these to your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- For reading calendars and events -->
    <uses-permission android:name="android.permission.READ_CALENDAR" />
    
    <!-- For creating, modifying, or deleting calendars and events -->
    <uses-permission android:name="android.permission.WRITE_CALENDAR" />
</manifest>
```

> `createEventInDefaultCalendar()` and `createEventThroughNativePlatform()` do not require these permissions.

## iOS

Add the following to your `Info.plist` based on the access level required:

### Versions below iOS 17
```xml
<key>NSCalendarsUsageDescription</key>
<string>We need access to your calendar to add information about your trip.</string>
```

### iOS 17+ (Granular Access)

#### Write-only

```xml
<key>NSCalendarsWriteOnlyAccessUsageDescription</key>
<string>We need access to your calendar to add information about your trip.</string>
```

> `createEventInDefaultCalendar()` do requires this permission.

> Introduced in iOS 17, this permission allows apps to add events without being able to read any existing calendar data.

> You can only add new events to the default calendar defined in user iOS system settings.

> Any attempt to retrieve events or list calendars will result in an exception.

#### Full access

```xml
<key>NSCalendarsFullAccessUsageDescription</key>
<string>We need access to your calendar to add information about your trip.</string>
```