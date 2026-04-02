name: plugin-interop
description: |-
  Guidelines for working with Pigeon and Platform Channels in Flutter plugins.
  Ensures safe, strongly-typed, and efficient communication between Dart and Native.
---

# Plugin Interop (Pigeon & Platform Channels)

## 1. When to use this skill
Use this skill when:
- Modifying `pigeons/*.dart` files.
- Implementing native handlers in Swift or Kotlin.
- Debugging communication issues between Dart and Native.

## 2. Pigeon Best Practices

### API Definition (`pigeons/`)
- **Use `@async` for all methods**: Native operations (Calendar access, DB) are inherently asynchronous and should not block the main UI thread.
- **Strict Typing**: Prefer custom classes (`final class` in Pigeon) over `Map` or `dynamic`.
- **Naming**: Use `camelCase` for methods and properties. Use `@SwiftFunction` to provide idiomatic names for Swift.
- **Nullability**: Be explicit about nullability. If a field is required on the native side, mark it as non-nullable in Dart.

### Swift Implementation
- **Use `FlutterError`**: Always return a `FlutterError` with a clear code and message when a native operation fails.
- **Thread Safety**: Ensure UI-related calls are on the main thread, but long-running tasks (like fetching many events) are handled appropriately.

### Kotlin Implementation
- **Result Callback**: Use the generated `Result` callback correctly for asynchronous operations.
- **Exceptions**: Catch platform-specific exceptions (e.g., `SecurityException` for permissions) and map them to `FlutterError`.

## 3. Review Checklist
- [ ] Are all new methods in Pigeon marked `@async`?
- [ ] Is the `@SwiftFunction` annotation used for complex parameter lists?
- [ ] Are the generated files (`.g.dart`, `.g.swift`, `.g.kt`) excluded from manual edits?
- [ ] Is error handling consistent across platforms?
