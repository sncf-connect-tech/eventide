## 0.2.0

* Fixed gradle issue by targeting jvm 17 ([Issue #7](https://github.com/sncf-connect-tech/eventide/issues/7))
* Exposed a new class `ETAccount` { name, type } ([Issue #8](https://github.com/sncf-connect-tech/eventide/issues/8))
    name = EKSource.sourceIdentifier and type = EKSource.sourceType on iOS
    name = CalendarContract.Calendars.ACCOUNT_NAME and type = CalendarContract.Calendars.ACCOUNT_TYPE on Android

## 0.1.0

Initial release with features:
* create/retrieve/delete calendars
* create/retrieve/delete events
* create/delete reminders
* ask for system calendar permission (although the plugin handles it automatically)