# eventide_ios

The endorsed iOS implementation of [Eventide](https://pub.dev/packages/eventide). It uses EventKit for calendar access and EventKitUI for the system event editor.

## Using Eventide in an app

Add `eventide` to your app. Flutter selects `eventide_ios` automatically with the federated version; a separate dependency is unnecessary. See the [iOS permission setup](https://github.com/sncf-connect-tech/eventide/blob/main/doc/PLATFORM_SETUP.md#ios) to select the usage descriptions for your app's `Info.plist`.

On iOS 17 and later, `createEventInDefaultCalendar` can write to the default calendar with write-only access. `createEventThroughNativePlatform` presents the system editor without requesting calendar access. Existing attendees can be read; `createAttendee` and `deleteAttendee` throw `ETNotSupportedByPlatform`.

See the [platform contract](https://github.com/sncf-connect-tech/eventide/tree/main/packages/eventide_platform_interface) and the [contributor guide](https://github.com/sncf-connect-tech/eventide/blob/main/CONTRIBUTING.md) for the API boundary and how to run the Swift package's XCTest suite.
