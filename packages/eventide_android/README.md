# eventide_android

The endorsed Android implementation of [Eventide](https://pub.dev/packages/eventide). It uses `CalendarContract` to access device calendars and `.ics` sharing to hand event creation off to a compatible app.

## Using Eventide in an app

Add `eventide` to your app. Flutter selects `eventide_android` automatically with the federated version; a separate dependency is unnecessary. See the [Android permission setup](https://github.com/sncf-connect-tech/eventide/blob/main/doc/PLATFORM_SETUP.md#android) for manifest declarations required by direct calendar access.

`createEventThroughNativePlatform` shares an `.ics` file and require no calendar permissions. Android stores reminders in whole minutes and supports reading, adding, and removing attendees.

See the [platform contract](https://github.com/sncf-connect-tech/eventide/tree/main/packages/eventide_platform_interface) and [contributor guide](https://github.com/sncf-connect-tech/eventide/blob/main/CONTRIBUTING.md) for the API boundary and how to run tests.
