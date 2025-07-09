## 0.10.1
* **Fixed DateTime UTC handling** in `createEvent()`, `createEventInDefaultCalendar()` and `retrieveEvents()` by systemically calling `dateTime.toUtc()`

## 0.10.0
* **Changed signature of createEventInDefaultCalendar** to not return the created event as the event will not be editable

## 0.9.1
* **Fix** double (write-only and full) permission prompt issue on iOS by creating reminders in the same method channel as the event creation
* **Fix** permission issue on Android by binding PermissionHandler as a RequestPermissionsResultListener
* **Improved docs**

## 0.9.0
* **Removed retrieveDefaultCalendar** because it did not make sense to return a virtual calendar on iOS (error-prone)
* **Created createEventInDefaultCalendar** instead to directly create an event and prompt write-only access on iOS 17+
* **Created .pubignore file** to remove example app and other useless files from being published

## 0.8.1
* **Removed final clause** on Eventide class because it prevented it from being mocked

## 0.8.0
* **iOS 17 Support**: Added support for iOS 17 write-only calendar access
* **Permission Enhancement**: `retrieveDefaultCalendar()` now prompts for write-only access on iOS 17+
* **Documentation**: Comprehensive documentation update with detailed API reference
* **Platform Features**: Added dedicated section for platform-specific features

## 0.7.0
* **Android Calendar Fix**: Fixed calendar creation to use local accounts by default
* **Breaking Change**: `localAccountName` is now mandatory when creating calendars
* **Account Management**: Improved account handling for better calendar organization

## 0.6.0
* **Dependencies**: Removed dependency to [equatable](https://pub.dev/packages/equatable)
* **Pigeon Update**: Upgraded pigeon dependency to 25.2.0
* **Requirements**: Set minimum versions - Flutter 3.27.0 & Dart 3.6.0

## 0.5.0
* **Attendees Support**: Retrieve attendees through events (Android & iOS)
* **Attendee Management**: Create/delete attendees (Android only due to iOS EventKit limitations)
* **Development**: Set up lefthook & CI format check
* **Bug Fixes**: Fixed permission checks and configuration issues

## 0.4.0
* **iOS Enhancement**: Added Swift Package Manager support
* **Code Quality**: Updated to Dart 3.7.0 format standards

## 0.3.0
* **Reminders**: Create reminders alongside event creation
* **Bug Fix**: Fixed Android issue where name was incorrectly assigned to type field

## 0.2.0
* **Build Fix**: Resolved Gradle issue by targeting JVM 17
* **New Feature**: Exposed `ETAccount` class with name and type properties ([Issue #8](https://github.com/sncf-connect-tech/eventide/issues/8))
  * iOS: `name` = EKSource.sourceIdentifier, `type` = EKSource.sourceType
  * Android: `name` = CalendarContract.Calendars.ACCOUNT_NAME, `type` = CalendarContract.Calendars.ACCOUNT_TYPE

## 0.1.0
**Initial Release** 🎉

Core features:
* **Calendar Management**: Create, retrieve, and delete calendars
* **Event Management**: Create, retrieve, and delete events
* **Reminder System**: Create and delete reminders for events
* **Permission Handling**: Automatic system calendar permission management
* **Cross-Platform**: Full support for iOS and Android
* **Exception Handling**: Custom exceptions for better error management