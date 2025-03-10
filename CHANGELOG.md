## 0.5.0
* retrieve attendees through events (Android & iOS)
* create/delete attendees (Android only)
* set up lefthook & ci format check
* fixed some permission checks
* fixed some configuration issues

## 0.4.0

* Added Swift Package Manager support
* dart 3.7.0 format

## 0.3.0

* Create reminder alongside event creation
* Fix android action where name was affected to type

## 0.2.0

* Fixed gradle issue by targeting JVM 17
* Exposed a new class `ETAccount` { name, type } ([Issue #8](https://github.com/sncf-connect-tech/eventide/issues/8))
    name = EKSource.sourceIdentifier and type = EKSource.sourceType on iOS
    name = CalendarContract.Calendars.ACCOUNT_NAME and type = CalendarContract.Calendars.ACCOUNT_TYPE on Android

## 0.1.0

Initial release with features:
* create/retrieve/delete calendars
* create/retrieve/delete events
* create/delete reminders
* ask for system calendar permission (although the plugin handles it automatically)