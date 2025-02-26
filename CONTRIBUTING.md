## Contribute

## Flutter version

Ensure to use a version mentionned in `pubspec.yaml`.

## Lefthook

[Lefthook](https://github.com/evilmartians/lefthook) is used to ensure proper code formatting and detect errors ahead of CI.

Install lefthook on your machine then run at the root of the project :
```bash
lefthook install
```

## Build API

This project uses [pigeon](https://pub.dev/packages/pigeon) to make communication between Flutter and host platforms easier.

Run the following command from project root to build boilerplate code with pigeon:

```bash
fvm dart pub run pigeon --input ./pigeons/calendar_api.dart
```