name: native-standards
description: |-
  Guidelines for writing idiomatic Swift and Kotlin code within the eventide plugin.
  Ensures consistency with platform standards.
---

# Native Standards (Swift & Kotlin)

## 1. When to use this skill
Use this skill when:
- Writing or reviewing code in `ios/` (Swift).
- Writing or reviewing code in `android/` (Kotlin).

## 2. Swift Guidelines (iOS)
- **API Design**: Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- **Optionals**: Use `guard let` or `if let` for safe unwrapping. Avoid force unwraps (`!`).
- **Extensions**: Use extensions to organize code, especially for protocol conformances.
- **EventKit**: When working with EventKit, ensure `EKEventStore` is handled as a shared resource where appropriate.

## 3. Kotlin Guidelines (Android)
- **Null Safety**: Leverage Kotlin's null safety features. Avoid `!!`.
- **Coroutines**: Use coroutines for background tasks if they are not already managed by the Pigeon generated code.
- **Modern Android**: Use modern APIs and avoid deprecated ones. Ensure compatibility with the minimum SDK defined in `android/build.gradle`.

## 4. Error Handling
- **Consistency**: Map native errors (EventKit errors on iOS, CalendarProvider errors on Android) to consistent error codes that can be caught in Dart.
- **Logs**: Use platform-appropriate logging (e.g., `os_log` on iOS, `Log` on Android) for debugging, but avoid logging sensitive user data (like event titles).

## 5. Review Checklist
- [ ] Is the Swift code using idiomatic naming?
- [ ] Are there any unsafe force unwraps?
- [ ] Is the Kotlin code following null-safety best practices?
- [ ] Are native permissions handled gracefully?
