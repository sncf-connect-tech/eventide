# eventide_platform_interface

The shared Dart contract for the [Eventide](https://pub.dev/packages/eventide) Flutter plugin. It defines `EventidePlatformInterface`, the `ETAccount`, `ETCalendar`, `ETEvent`, and `ETAttendee` models, `ETSpan` for recurrence scope, and typed exceptions such as `ETPermissionException` and `ETNotSupportedByPlatform`.

## Implementing a platform

1. Add a dependency on `eventide_platform_interface`. Until its first pub.dev release, use the workspace copy in this repository.
2. Extend `EventidePlatformInterface` and override the operations your platform supports. Use the shared models and exceptions; keep native APIs and Pigeon types private to your implementation.
3. Give your Dart plugin class a static `registerWith()` method that assigns the implementation to `EventidePlatformInterface.instance`. Declare `implements: eventide` and the platform's `dartPluginClass` in your plugin's `pubspec.yaml` so Flutter can register it.

See the [Android](https://github.com/sncf-connect-tech/eventide/tree/main/packages/eventide_android) and [iOS](https://github.com/sncf-connect-tech/eventide/tree/main/packages/eventide_ios) implementations and Flutter's [federated plugin guide](https://docs.flutter.dev/packages-and-plugins/developing-packages#federated-plugins).

## Compatibility

Extend the platform interface rather than implementing it. This lets existing platform implementations inherit a default when a new method is added. Prefer compatible additions over removing methods or changing their signatures; see Flutter's guidance on [platform interface breaking changes](https://flutter.dev/go/platform-interface-breaking-changes).
