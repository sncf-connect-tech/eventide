name: plugin-maintenance
description: |-
  Guidelines for maintaining a stable and clean public API for the eventide plugin.
  Focuses on breaking changes, exports, and documentation.
---

# Plugin Maintenance & Public API

## 1. When to use this skill
Use this skill when:
- Modifying files in `lib/`.
- Changing the public interface of the library.
- Updating `pubspec.yaml` or `CHANGELOG.md`.

## 2. Public API Stability

### Interface vs Implementation
- **Minimize Exports**: Only export what is necessary for the user in `lib/eventide.dart`. Keep internal logic in `lib/src/`.
- **Breaking Changes**: Avoid changing existing method signatures in the public API. If necessary, follow semantic versioning and document the migration path.
- **Extensions**: Use extensions (like in `lib/src/extensions/`) to add functionality to generated classes without bloating the core API.

### Documentation
- **Mandatory Dartdoc**: Every public class, method, and property MUST have a `///` documentation comment.
- **Examples**: Include code snippets in doc comments for complex APIs.
- **Platform-Specific Notes**: Clearly document if a feature is only available on iOS or Android.

## 3. Project Health
- **CHANGELOG**: Ensure every PR that changes behavior adds a entry to `CHANGELOG.md`.
- **Version Management**: Check if `pubspec.yaml` needs a version bump.
- **Dependencies**: Keep dependencies lean and up-to-date.

## 4. Review Checklist
- [ ] Does `lib/eventide.dart` only export public-facing APIs?
- [ ] Are all new public members documented with `///`?
- [ ] Is a breaking change properly flagged?
- [ ] Has the `CHANGELOG.md` been updated?
