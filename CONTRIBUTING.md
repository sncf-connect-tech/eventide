# Contributing to Eventide

## Set up the workspace

Install the Flutter version in [`.fvmrc`](.fvmrc) using [FVM](https://fvm.app/), then resolve the Dart workspace from the repository root:

```sh
fvm install
fvm flutter pub get
```

Install [Lefthook](https://github.com/evilmartians/lefthook) and run `lefthook install` at the repository root to enable the pre-commit checks.

## Run an example

```sh
cd packages/eventide/example
fvm flutter run
```

The [`examples/`](examples/) directory also contains standalone apps for the full-permission, write-only, and native-only flows.

## Regenerate Pigeon bindings

Each implementation owns its schema. After changing one, run the matching command from the root:

```sh
(cd packages/eventide_ios && fvm dart run pigeon --input pigeon/calendar_api.dart)
(cd packages/eventide_android && fvm dart run pigeon --input pigeon/calendar_api.dart)
```

Format the generated Dart files and include both the Dart and native bindings in the same change as the schema.

## Run tests

### Dart

From the repository root:

```sh
fvm dart analyze . --fatal-infos
fvm dart format . --output=none --set-exit-if-changed
fvm flutter test packages/eventide/test packages/eventide_platform_interface/test \
  packages/eventide_ios/test packages/eventide_android/test
```

### Android (Kotlin)

With the Android SDK and Java 17 set up, first build the example once to generate its Android configuration. Run the native tests through the example's Gradle project:

```sh
cd packages/eventide/example
fvm flutter build apk --debug
cd android
./gradlew :eventide_android:testDebugUnitTest
```

### iOS (Swift)

On macOS with Xcode and an installed iOS Simulator, run the following from the repository root. Replace the placeholder with an available iPhone simulator UDID from `xcrun simctl list devices available`.

```sh
fvm flutter config --enable-swift-package-manager
fvm flutter precache --ios
(cd packages/eventide/example && fvm flutter build ios --simulator --config-only --no-codesign)

simulator_udid='<iPhone simulator UDID>'
engine="$PWD/.fvm/flutter_sdk/bin/cache/artifacts/engine/ios/Flutter.xcframework"
framework=$(find "$engine" -path '*/ios-*-simulator/Flutter.framework' -type d -print -quit)
framework_dir=$(dirname "$framework")

cd packages/eventide_ios/ios
if [ ! -e FlutterFramework ]; then
  ln -s ../../eventide/example/ios/Flutter/ephemeral/Packages/.packages/FlutterFramework FlutterFramework
fi
cd eventide_ios
xcodebuild test -scheme eventide_ios \
  -destination "platform=iOS Simulator,id=$simulator_udid" \
  FRAMEWORK_SEARCH_PATHS="$framework_dir" \
  LD_RUNPATH_SEARCH_PATHS="\$(inherited) $framework_dir"
```

The example prepares the Flutter dependency. The XCTest target itself lives in [`eventide_ios`'s Swift package](packages/eventide_ios/ios/eventide_ios/Package.swift). See the [CI workflow](.github/workflows/ci.yaml) for coverage commands.

## Submit a pull request

Use [Conventional Commits](https://www.conventionalcommits.org/) for commits that land on `main`. If the PR is squash-merged, use the same format for its title. For example:

- `fix(eventide_android): preserve attendee roles`
- `feat(eventide): support a new recurrence option`
- `docs: update the platform setup guide`

Use `!` or a `BREAKING CHANGE:` footer for incompatible API changes. Include tests for behavior changes and update the [API reference](doc/API_REFERENCE.md) when the public contract changes.
