## Contribute

## Flutter version

Ensure to use a version mentionned in `pubspec.yaml`.

## Build API

This project uses [pigeon](https://pub.dev/packages/pigeon) to make communication between Flutter and host platforms easier.

Run the following command from project root to build boilerplate code with pigeon:

```bash
fvm dart pub run pigeon --input ./pigeons/calendar_api.dart
```