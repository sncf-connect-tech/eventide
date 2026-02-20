## 2.2.0
* **Definitive fix in `createEventInDefaultCalendar` & `createEventThroughNativePlatform` on Android :**: using ical format under the hood

## 2.1.1
* **Fix allDay flag in createEventThroughNativePlatform:** allDay extra flag was `CalendarContract.EXTRA_EVENT_ALL_DAY` and not `CalendarContract.Events.ALL_DAY`

## 2.1.0
* **Account name improvement** on Android. We figured we could fetch a displayable account name based on the account type using PackageManager. i.e. `com.google` will result in a clean `Google` `account.name`
* **Dart dev dependencies upgrade**

## 2.0.1
* **Fix sourceType comparison** on iOS (https://github.com/sncf-connect-tech/eventide/issues/98)

## 2.0.0
* **🚨 BREAKING CHANGES - Account API Redesign:**
  * **createCalendar():** Parameter `localAccountName` (String) replaced with `account` (ETAccount?)
    * Before: `createCalendar(title: 'Work', color: Colors.red, localAccountName: 'My App')`
    * After: `createCalendar(title: 'Work', color: Colors.red, account: myAccount)`
    * When `account` is null, calendar is created in default account/source
  * **retrieveCalendars():** Parameter `fromLocalAccountName` (String) replaced with `account` (ETAccount?)
    * Before: `retrieveCalendars(fromLocalAccountName: 'My App')`
    * After: `retrieveCalendars(account: myAccount)`
  * **New Method:** Added `retrieveAccounts()` to get all available accounts (Google, Exchange, local, etc.)
    * Returns `Iterable<ETAccount>` with account details for better account management
    * Use this method to get accounts before creating calendars or filtering
* **Enhanced Account Management:**
  * More robust account handling across platforms
  * Better integration with system accounts (Google, Exchange, iCloud, etc.)
  * Improved account-based calendar filtering and organization
* **Migration Guide:**
  ```dart
  // OLD API (v1.x)
  final calendars = await eventide.retrieveCalendars(fromLocalAccountName: 'My App');
  await eventide.createCalendar(title: 'Work', color: Colors.red, localAccountName: 'My App');
  
  // NEW API (v2.0)
  final accounts = await eventide.retrieveAccounts();
  final myAccount = accounts.firstWhere((acc) => acc.name == 'My App');
  final calendars = await eventide.retrieveCalendars(account: myAccount);
  await eventide.createCalendar(title: 'Work', color: Colors.red, account: myAccount);
  ```
* **Removed automatic duration addition** for parameters `startDate` and `endDate` in `retrieveEvents()` method
* **Upcasting:**
  * **All `List` occurrences** are now `Iterable`
* Updates minimum supported SDK version to Flutter 3.29/Dart 3.7
* Add `location` to `ETEvent` by @StoneyDev

## 1.0.2
* **Android URL Support:** Added comprehensive URL handling for event creation and retrieval. Android Calendar API lacks native URL field support, so implemented intelligent description/URL merging system that preserves both fields while maintaining compatibility with existing calendar apps
* **Enhanced Native-Only Example App:** Added prefill parameters toggle to demonstrate `createEventThroughNativePlatform()` flexibility
  * New configuration switch to enable/disable parameter pre-population
  * Demonstrates both empty form (no parameters) and prefilled form usage patterns
  * Dynamic UI that adapts button text and success messages based on toggle state
  * Improved user experience for testing different API usage scenarios

## 1.0.1
* **Restored example app** as it was not appearing on pub.dev. Put the more complex examples in new `example/more-complex/` folder.

## 1.0.0+1
* **Restored ETNotSupportedByPlatform** as it was thrown by `createAttendee()` and `removeAttendee()` methods on iOS.
* **Splitted example app** into 3 "use-case" apps
* **Quickstart example** for pub.dev

## 1.0.0
* **Breaking Change - Android Permissions:** Removed default calendar permissions from eventide's `AndroidManifest.xml`. Apps must now declare needed permissions based on their usage:
  * `android.permission.READ_CALENDAR` for reading calendars/events
  * `android.permission.WRITE_CALENDAR` for creating/modifying calendars/events
  * No permissions required for `createEventInDefaultCalendar()` or `createEventThroughNativePlatform()` (use system Intent)
* **Android Enhancement:** `createEventInDefaultCalendar()` now uses system Intent to open calendar app directly (no permissions needed)
* **New Method:** Added `createEventThroughNativePlatform()` for platform-native event creation
  * iOS: Opens native event creation modal with write-only permission support
  * Android: Uses system calendar app (identical behavior to `createEventInDefaultCalendar()`)
  * All parameters optional for maximum flexibility
  * No permissions required in AndroidManifest.xml or Info.plist
* **Enhanced Exception Handling:** Added new specific exception types:
  * `ETUserCanceledException`: User canceled event creation in native platform
  * `ETPresentationException`: Event creation view cannot be presented
* **Removed Exception:** Removed unused `ETNotSupportedByPlatform` exception
* **Privacy-First Approach:** Enhanced documentation emphasizing user privacy and minimal permission requests
* **Android Bug Fix:** Fixed `allDay` attribute Boolean to Int cast in event creation
* **CI/CD Improvements:** Removed conditional CI jobs for better workflow reliability

## 0.10.2
* **Android fix:** `createEventInDefaultCalendar()` did not retrieve any default calendar when there was multiple primary calendars. Now also returns any writable calendar when there is no primary calendars

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